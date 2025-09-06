import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Emergency number types
enum EmergencyType {
  police,
  medical,
  fire,
}

/// Service to manage Indian emergency numbers and dialer functionality
class EmergencyNumbersService {
  static final EmergencyNumbersService _instance = EmergencyNumbersService._internal();
  factory EmergencyNumbersService() => _instance;
  EmergencyNumbersService._internal();

  // Indian Emergency Numbers
  static const String policeNumber = '100';
  static const String medicalNumber = '108';
  static const String fireNumber = '101';

  /// Get emergency number for specific type
  String getEmergencyNumber(EmergencyType type) {
    switch (type) {
      case EmergencyType.police:
        return policeNumber;
      case EmergencyType.medical:
        return medicalNumber;
      case EmergencyType.fire:
        return fireNumber;
    }
  }

  /// Get formatted display name for emergency type
  String getEmergencyDisplayName(EmergencyType type) {
    switch (type) {
      case EmergencyType.police:
        return 'Police';
      case EmergencyType.medical:
        return 'Medical/Hospital';
      case EmergencyType.fire:
        return 'Fire Department';
    }
  }

  /// Get emergency type icon
  IconData getEmergencyIcon(EmergencyType type) {
    switch (type) {
      case EmergencyType.police:
        return Icons.local_police;
      case EmergencyType.medical:
        return Icons.local_hospital;
      case EmergencyType.fire:
        return Icons.local_fire_department;
    }
  }

  /// Call emergency number directly (opens dialer)
  Future<bool> callEmergencyNumber(EmergencyType type) async {
    final number = getEmergencyNumber(type);
    return await _makePhoneCall(number);
  }

  /// Call a specific phone number (opens dialer)
  Future<bool> callPhoneNumber(String phoneNumber) async {
    return await _makePhoneCall(phoneNumber);
  }

  /// Internal method to make phone calls
  Future<bool> _makePhoneCall(String phoneNumber) async {
    try {
      // Clean the phone number (remove spaces, hyphens, etc.)
      final cleanedNumber = _cleanPhoneNumber(phoneNumber);
      
      // Create phone call URL
      final phoneUrl = Uri.parse('tel:$cleanedNumber');

      debugPrint('📞 Attempting to call: $cleanedNumber');

      // Check if phone calls are supported
      if (await canLaunchUrl(phoneUrl)) {
        final launched = await launchUrl(phoneUrl);
        if (launched) {
          debugPrint('✅ Phone dialer opened for: $cleanedNumber');
          return true;
        } else {
          debugPrint('❌ Failed to open phone dialer for: $cleanedNumber');
          return false;
        }
      } else {
        debugPrint('❌ Phone calls not supported on this device (this is normal on emulators)');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error making phone call: $e');
      return false;
    }
  }

  /// Clean phone number (remove formatting characters)
  String _cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Format phone number for display
  String formatPhoneNumber(String phoneNumber) {
    final cleaned = _cleanPhoneNumber(phoneNumber);
    
    // For Indian mobile numbers (10 digits starting with 6-9)
    if (cleaned.length == 10 && cleaned.startsWith(RegExp(r'[6-9]'))) {
      return '+91 ${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    }
    
    // For Indian mobile numbers with country code
    if (cleaned.length == 13 && cleaned.startsWith('+91')) {
      final mobile = cleaned.substring(3);
      return '+91 ${mobile.substring(0, 5)} ${mobile.substring(5)}';
    }
    
    // For emergency numbers (3 digits)
    if (cleaned.length == 3) {
      return cleaned;
    }
    
    // Return as-is if no formatting rules match
    return cleaned;
  }

  /// Validate Indian phone number
  bool isValidIndianPhoneNumber(String phoneNumber) {
    final cleaned = _cleanPhoneNumber(phoneNumber);
    
    // Emergency numbers (3 digits)
    if (cleaned.length == 3 && ['100', '101', '102', '108'].contains(cleaned)) {
      return true;
    }
    
    // Indian mobile numbers (10 digits starting with 6-9)
    if (cleaned.length == 10 && cleaned.startsWith(RegExp(r'[6-9]'))) {
      return true;
    }
    
    // Indian mobile numbers with country code
    if (cleaned.length == 13 && cleaned.startsWith('+91')) {
      final mobile = cleaned.substring(3);
      return mobile.startsWith(RegExp(r'[6-9]')) && mobile.length == 10;
    }
    
    return false;
  }

  /// Get all emergency services information
  List<Map<String, dynamic>> getAllEmergencyServices() {
    return [
      {
        'type': EmergencyType.police,
        'name': getEmergencyDisplayName(EmergencyType.police),
        'number': getEmergencyNumber(EmergencyType.police),
        'icon': getEmergencyIcon(EmergencyType.police),
        'description': 'For law enforcement emergencies',
      },
      {
        'type': EmergencyType.medical,
        'name': getEmergencyDisplayName(EmergencyType.medical),
        'number': getEmergencyNumber(EmergencyType.medical),
        'icon': getEmergencyIcon(EmergencyType.medical),
        'description': 'For medical emergencies and ambulance',
      },
      {
        'type': EmergencyType.fire,
        'name': getEmergencyDisplayName(EmergencyType.fire),
        'number': getEmergencyNumber(EmergencyType.fire),
        'icon': getEmergencyIcon(EmergencyType.fire),
        'description': 'For fire emergencies',
      },
    ];
  }

  /// Check if a number is an emergency number
  bool isEmergencyNumber(String phoneNumber) {
    final cleaned = _cleanPhoneNumber(phoneNumber);
    return [policeNumber, medicalNumber, fireNumber].contains(cleaned);
  }
}
