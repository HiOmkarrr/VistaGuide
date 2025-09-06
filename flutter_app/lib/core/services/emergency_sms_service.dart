import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import '../../features/emergency_reporting/data/models/emergency_contact.dart';

/// SMS send status
enum SMSStatus {
  pending,
  sending,
  sent,
  failed,
  permissionDenied,
}

/// Result of SMS sending operation
class SMSResult {
  final SMSStatus status;
  final String message;
  final List<String> successfulContacts;
  final List<String> failedContacts;
  final int attempts;

  SMSResult({
    required this.status,
    required this.message,
    this.successfulContacts = const [],
    this.failedContacts = const [],
    this.attempts = 0,
  });
}

/// Service to send emergency SMS alerts to contacts
class EmergencySMSService {
  static final EmergencySMSService _instance = EmergencySMSService._internal();
  factory EmergencySMSService() => _instance;
  EmergencySMSService._internal();

  final Telephony _telephony = Telephony.instance;

  /// Request/send permissions for SMS (Android only)
  Future<bool> _ensureSmsPermission() async {
    if (!Platform.isAndroid) return false;
    final granted = (await _telephony.requestPhoneAndSmsPermissions) ?? false;
    debugPrint('📱 SMS permission granted: $granted');
    return granted;
  }

  /// Send emergency SMS to all contacts
  Future<SMSResult> sendEmergencySMS({
    required List<EmergencyContact> contacts,
    required Map<String, dynamic> locationData,
    String? userName,
  }) async {
    debugPrint('🚨 Starting emergency SMS sending process');
    if (!Platform.isAndroid) {
      return SMSResult(
        status: SMSStatus.failed,
        message: 'Auto-SMS supported on Android only',
      );
    }

    if (contacts.isEmpty) {
      return SMSResult(
        status: SMSStatus.failed,
        message: 'No emergency contacts to notify',
      );
    }

    final allowed = await _ensureSmsPermission();
    if (!allowed) {
      return SMSResult(
        status: SMSStatus.permissionDenied,
        message: 'SMS permission denied',
      );
    }

    final message = _generateEmergencyMessage(locationData, userName);
    debugPrint('📱 Emergency message generated: ${message.substring(0, message.length.clamp(0, 50))}...');

    final successfulContacts = <String>[];
    final failedContacts = <String>[];
    int attempts = 0;

    for (final c in contacts) {
      try {
        attempts++;
        final st = await _sendSmsAwaitStatus(_normalizePhoneNumber(c.phoneNumber), message);
        if (st == SMSStatus.sent) {
          successfulContacts.add(c.name);
        } else {
          failedContacts.add(c.name);
        }
      } catch (e) {
        debugPrint('❌ Failed to send SMS to ${c.phoneNumber}: $e');
        failedContacts.add(c.name);
      }
      // Yield briefly to avoid jank on UI thread
      await Future.delayed(const Duration(milliseconds: 150));
    }

    final ok = successfulContacts.isNotEmpty;
    return SMSResult(
      status: ok ? SMSStatus.sent : SMSStatus.failed,
      message: ok
          ? 'Sent to ${successfulContacts.length} contact(s). Failed: ${failedContacts.length}.'
          : 'Failed to send to all contacts',
      successfulContacts: successfulContacts,
      failedContacts: failedContacts,
      attempts: attempts,
    );
  }


  /// Generate emergency message using the specified template
  String _generateEmergencyMessage(Map<String, dynamic> locationData, String? userName) {
    final name = userName ?? 'User';
    final latitude = locationData['latitude']?.toString() ?? '';
    final longitude = locationData['longitude']?.toString() ?? '';
    final address = locationData['address'] ?? 'Location unavailable';
    final battery = locationData['battery']?.toString() ?? 'Unknown';
    final timestamp = DateTime.now();
    
    // Format timestamp
    final formattedTime = '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    
    // Create Google Maps link
    String mapsLink = 'Location unavailable';
    if (latitude.isNotEmpty && longitude.isNotEmpty) {
      mapsLink = 'https://maps.google.com/?q=$latitude,$longitude';
    }

    // Generate message using the exact template format
    return '''🚨 EMERGENCY ALERT 🚨
$name has triggered an emergency.

📍 Location: $address
🗺️ Maps: $mapsLink
⏰ Time: $formattedTime
📱 Battery: $battery%

Please respond or call immediately.''';
  }

  /// Send OTP SMS to a phone number
  Future<SMSResult> sendOTPSMS({
    required String phoneNumber,
    required String otp,
    String? appName,
  }) async {
    debugPrint('📱 Sending OTP SMS to $phoneNumber');
    if (!Platform.isAndroid) {
      return SMSResult(
        status: SMSStatus.failed,
        message: 'Auto-OTP via SMS is Android-only',
      );
    }

    final allowed = await _ensureSmsPermission();
    if (!allowed) {
      return SMSResult(
        status: SMSStatus.permissionDenied,
        message: 'SMS permission denied',
      );
    }

    final message = _generateOTPMessage(otp, appName);
    try {
      final st = await _sendSmsAwaitStatus(_normalizePhoneNumber(phoneNumber), message);
      if (st == SMSStatus.sent) {
        debugPrint('✅ OTP SMS sent to $phoneNumber');
        return SMSResult(
          status: SMSStatus.sent,
          message: 'OTP SMS sent',
          attempts: 1,
        );
      }
      debugPrint('❌ OTP SMS failed to send (status listener). Falling back to default SMS app composer.');
      try {
        await _telephony.sendSmsByDefaultApp(
          to: _normalizePhoneNumber(phoneNumber),
          message: message,
        );
      } catch (e) {
        debugPrint('⚠️ Fallback composer open failed: $e');
      }
      return SMSResult(
        status: SMSStatus.failed,
        message: 'Failed to send OTP silently. Opened default SMS app to send manually.',
        attempts: 1,
      );
    } catch (e) {
      debugPrint('❌ Failed to send OTP SMS: $e');
      return SMSResult(
        status: SMSStatus.failed,
        message: 'Failed to send OTP: $e',
        attempts: 1,
      );
    }
  }

  /// Normalize a phone number to a format commonly accepted by carriers.
  /// - Keeps "+" international format as-is
  /// - Trims spaces and dashes
  /// - If Indian 10-digit starting 6-9, prefixes "+91"
  String _normalizePhoneNumber(String input) {
    var s = input.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (s.startsWith('+')) return s;
    // Handle leading 0 for Indian mobiles entered as 0XXXXXXXXXX
    if (s.length == 11 && s.startsWith('0') && RegExp(r'^[6-9]').hasMatch(s.substring(1, 2))) {
      s = s.substring(1);
    }
    // Heuristic for India
    if (s.length == 10 && RegExp(r'^[6-9]').hasMatch(s)) {
      return '+91$s';
    }
    return s;
  }

  /// Await SMS status using another_telephony listener
  Future<SMSStatus> _sendSmsAwaitStatus(String to, String message) async {
    final completer = Completer<SendStatus>();
    try {
      debugPrint('📨 Sending SMS to $to (normalized)');
      await _telephony.sendSms(
        to: to,
        message: message,
        isMultipart: message.length > 160,
        statusListener: (SendStatus status) {
          if (!completer.isCompleted) {
            completer.complete(status);
          }
        },
      );
    } catch (e) {
      debugPrint('❌ sendSms threw: $e');
      return SMSStatus.failed;
    }

    try {
      final status = await completer.future.timeout(const Duration(seconds: 20));
      switch (status) {
        case SendStatus.SENT:
        case SendStatus.DELIVERED:
          return SMSStatus.sent;
        default:
          return SMSStatus.failed;
      }
    } catch (e) {
      debugPrint('⚠️ sendSms status timeout or error: $e');
      return SMSStatus.failed;
    }
  }

  /// Generate OTP message
  String _generateOTPMessage(String otp, String? appName) {
    // Avoid common spam-filtered phrases like "verification code" and "Do not share".
    // Keep it concise and human-like to reduce carrier scrubbing on consumer SIMs.
    return 'VistaGuide code: $otp\nUse within 5 min to verify adding you as an emergency contact.';
  }

  // URL-launcher based helpers removed as redundant for auto-SMS flow.

  /// Get SMS send status description
  String getStatusDescription(SMSStatus status) {
    switch (status) {
      case SMSStatus.pending:
        return 'SMS is pending';
      case SMSStatus.sending:
        return 'Sending SMS...';
      case SMSStatus.sent:
        return 'SMS app opened successfully';
      case SMSStatus.failed:
        return 'Failed to open SMS app';
      case SMSStatus.permissionDenied:
        return 'SMS app not available';
    }
  }
}
