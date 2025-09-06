import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_sms_service.dart';

/// OTP Session data
class OTPSession {
  final String phoneNumber;
  final String otp;
  final DateTime generatedAt;
  final DateTime expiresAt;
  bool isVerified;
  int attemptCount;

  OTPSession({
    required this.phoneNumber,
    required this.otp,
    required this.generatedAt,
    required this.expiresAt,
    this.isVerified = false,
    this.attemptCount = 0,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired && !isVerified;
}

/// Service to handle OTP verification for emergency contacts
class OTPVerificationService {
  static final OTPVerificationService _instance = OTPVerificationService._internal();
  factory OTPVerificationService() => _instance;
  OTPVerificationService._internal();

  final EmergencySMSService _smsService = EmergencySMSService();
  final Map<String, OTPSession> _activeSessions = {};

  static const Duration _otpValidityDuration = Duration(minutes: 5);
  static const int _otpLength = 6;
  
  // Legacy maps removed (Firebase phone auth not used here)

  /// Generate and send OTP to phone number
  Future<OTPVerificationResult> generateAndSendOTP({
    required String phoneNumber,
    String? userName,
  }) async {
    try {
      debugPrint('📱 Generating OTP for $phoneNumber');

      // Clean phone number
      final cleanedPhone = _cleanPhoneNumber(phoneNumber);
      
      // Validate phone number format
      if (!_isValidPhoneNumber(cleanedPhone)) {
        return OTPVerificationResult(
          success: false,
          message: 'Invalid phone number format',
          errorCode: 'INVALID_PHONE',
        );
      }

      // Generate OTP
      final otp = _generateOTP();
      final now = DateTime.now();
      final expiresAt = now.add(_otpValidityDuration);

      // Create session
      final session = OTPSession(
        phoneNumber: cleanedPhone,
        otp: otp,
        generatedAt: now,
        expiresAt: expiresAt,
      );

      // Store session
      _activeSessions[cleanedPhone] = session;

      debugPrint('🔑 OTP generated: $otp (expires at ${expiresAt.toString()})');

      // Send OTP via SMS
      final smsResult = await _smsService.sendOTPSMS(
        phoneNumber: cleanedPhone,
        otp: otp,
        appName: 'VistaGuide',
      );

      if (smsResult.status == SMSStatus.sent) {
        debugPrint('✅ OTP SMS sent successfully to $cleanedPhone');
        
        // Store in SharedPreferences for persistence
        await _storePendingOTP(cleanedPhone, session);
        
        return OTPVerificationResult(
          success: true,
          message: 'OTP sent successfully',
          sessionId: cleanedPhone,
          expiresAt: expiresAt,
          channel: 'sms',
        );
      } else {
        // Keep session so user can still type OTP shown in UI (dev fallback)
        debugPrint('❌ Failed to send OTP SMS: ${smsResult.message}');
        await _storePendingOTP(cleanedPhone, session);
        return OTPVerificationResult(
          success: true,
          message: 'SMS app not available. Use the code shown in the app to verify.',
          sessionId: cleanedPhone,
          expiresAt: expiresAt,
          channel: 'fallback',
          debugOtp: otp,
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating OTP: $e');
      return OTPVerificationResult(
        success: false,
        message: 'Failed to generate OTP: $e',
        errorCode: 'GENERATION_FAILED',
      );
    }
  }

  /// Verify OTP entered by user
  Future<OTPVerificationResult> verifyOTP({
    required String phoneNumber,
    required String enteredOTP,
  }) async {
    try {
      final cleanedPhone = _cleanPhoneNumber(phoneNumber);
      debugPrint('🔑 Verifying OTP for $cleanedPhone');

      // Check if session exists
      final session = _activeSessions[cleanedPhone] ?? await _getPendingOTP(cleanedPhone);
      
      if (session == null) {
        return OTPVerificationResult(
          success: false,
          message: 'No active OTP session found',
          errorCode: 'NO_SESSION',
        );
      }

      // Check if OTP is expired
      if (session.isExpired) {
        _activeSessions.remove(cleanedPhone);
        await _removePendingOTP(cleanedPhone);
        
        return OTPVerificationResult(
          success: false,
          message: 'OTP has expired',
          errorCode: 'EXPIRED',
        );
      }

      // Check if already verified
      if (session.isVerified) {
        return OTPVerificationResult(
          success: false,
          message: 'OTP already verified',
          errorCode: 'ALREADY_VERIFIED',
        );
      }

      // Increment attempt count
      session.attemptCount++;

      // Check attempt limit
      if (session.attemptCount > 3) {
        _activeSessions.remove(cleanedPhone);
        await _removePendingOTP(cleanedPhone);
        
        return OTPVerificationResult(
          success: false,
          message: 'Too many failed attempts',
          errorCode: 'TOO_MANY_ATTEMPTS',
        );
      }

      // Verify OTP
      if (enteredOTP.trim() == session.otp) {
        session.isVerified = true;
        debugPrint('✅ OTP verified successfully for $cleanedPhone');
        
        // Clean up
        _activeSessions.remove(cleanedPhone);
        await _removePendingOTP(cleanedPhone);
        
        return OTPVerificationResult(
          success: true,
          message: 'OTP verified successfully',
          sessionId: cleanedPhone,
          isVerified: true,
        );
      } else {
        debugPrint('❌ Invalid OTP entered for $cleanedPhone');
        
        return OTPVerificationResult(
          success: false,
          message: 'Invalid OTP. ${4 - session.attemptCount} attempts remaining',
          errorCode: 'INVALID_OTP',
          attemptsRemaining: 3 - session.attemptCount,
        );
      }
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      return OTPVerificationResult(
        success: false,
        message: 'Failed to verify OTP: $e',
        errorCode: 'VERIFICATION_FAILED',
      );
    }
  }

  /// Check if phone number has active OTP session
  bool hasActiveSession(String phoneNumber) {
    final cleanedPhone = _cleanPhoneNumber(phoneNumber);
    final session = _activeSessions[cleanedPhone];
    return session != null && session.isValid;
  }

  /// Get remaining time for OTP session
  Duration? getRemainingTime(String phoneNumber) {
    final cleanedPhone = _cleanPhoneNumber(phoneNumber);
    final session = _activeSessions[cleanedPhone];
    
    if (session != null && session.isValid) {
      return session.expiresAt.difference(DateTime.now());
    }
    
    return null;
  }

  /// Cancel OTP session
  Future<void> cancelOTPSession(String phoneNumber) async {
    final cleanedPhone = _cleanPhoneNumber(phoneNumber);
    _activeSessions.remove(cleanedPhone);
    await _removePendingOTP(cleanedPhone);
    debugPrint('🚫 OTP session cancelled for $cleanedPhone');
  }

  /// Generate random OTP
  String _generateOTP() {
    final random = Random();
    String otp = '';
    
    for (int i = 0; i < _otpLength; i++) {
      otp += random.nextInt(10).toString();
    }
    
    return otp;
  }

  /// Clean phone number (remove formatting)
  String _cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Validate phone number format
  bool _isValidPhoneNumber(String phoneNumber) {
    // Indian mobile numbers (10 digits starting with 6-9)
    if (phoneNumber.length == 10 && phoneNumber.startsWith(RegExp(r'[6-9]'))) {
      return true;
    }
    
    // Indian mobile numbers with country code
    if (phoneNumber.length == 13 && phoneNumber.startsWith('+91')) {
      final mobile = phoneNumber.substring(3);
      return mobile.startsWith(RegExp(r'[6-9]')) && mobile.length == 10;
    }
    
    return false;
  }

  /// Store pending OTP in SharedPreferences
  Future<void> _storePendingOTP(String phoneNumber, OTPSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'pending_otp_$phoneNumber';
      
      final data = {
        'phoneNumber': session.phoneNumber,
        'otp': session.otp,
        'generatedAt': session.generatedAt.millisecondsSinceEpoch,
        'expiresAt': session.expiresAt.millisecondsSinceEpoch,
        'attemptCount': session.attemptCount,
        'isVerified': session.isVerified,
      };
      
      // Convert map to JSON string (simplified)
      await prefs.setString(key, data.toString());
    } catch (e) {
      debugPrint('❌ Error storing pending OTP: $e');
    }
  }

  /// Get pending OTP from SharedPreferences
  Future<OTPSession?> _getPendingOTP(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'pending_otp_$phoneNumber';
      final dataStr = prefs.getString(key);
      
      if (dataStr != null) {
        // Parse stored data (simplified - in production use JSON)
        return null; // For now, return null
      }
    } catch (e) {
      debugPrint('❌ Error getting pending OTP: $e');
    }
    return null;
  }

  /// Remove pending OTP from SharedPreferences
  Future<void> _removePendingOTP(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'pending_otp_$phoneNumber';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('❌ Error removing pending OTP: $e');
    }
  }

  /// Clear all expired sessions
  Future<void> cleanupExpiredSessions() async {
    final expiredKeys = <String>[];
    
    for (final entry in _activeSessions.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _activeSessions.remove(key);
      await _removePendingOTP(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('🧹 Cleaned up ${expiredKeys.length} expired OTP sessions');
    }
  }

  /// Get session info for debugging
  Map<String, dynamic>? getSessionInfo(String phoneNumber) {
    final cleanedPhone = _cleanPhoneNumber(phoneNumber);
    final session = _activeSessions[cleanedPhone];
    
    if (session != null) {
      return {
        'phoneNumber': session.phoneNumber,
        'generatedAt': session.generatedAt.toString(),
        'expiresAt': session.expiresAt.toString(),
        'isExpired': session.isExpired,
        'isVerified': session.isVerified,
        'attemptCount': session.attemptCount,
      };
    }
    
    return null;
  }
}

/// Result of OTP operations
class OTPVerificationResult {
  final bool success;
  final String message;
  final String? errorCode;
  final String? sessionId;
  final DateTime? expiresAt;
  final bool isVerified;
  final int? attemptsRemaining;
  final String? channel; // 'sms' | 'fcm' | 'fallback'
  final String? debugOtp; // only for fallback/dev flows

  OTPVerificationResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.sessionId,
    this.expiresAt,
    this.isVerified = false,
    this.attemptsRemaining,
    this.channel,
    this.debugOtp,
  });
}
