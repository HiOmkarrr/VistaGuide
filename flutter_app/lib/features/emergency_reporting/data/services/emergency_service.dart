import '../models/emergency_contact.dart';
import '../../../../core/services/emergency_contacts_storage.dart';
import '../../../../core/services/location_cache_service.dart';
import '../../../../core/services/emergency_sms_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';

/// Service to manage emergency reporting data and functionality
class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  // In-memory list synchronized with SQLite storage
  final List<EmergencyContact> _emergencyContacts = [];
  bool _loaded = false;
  final EmergencyContactsStorage _storage = EmergencyContactsStorage();

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await _storage.initialize();
    final items = await _storage.getAllContacts();
    _emergencyContacts
      ..clear()
      ..addAll(items);
    _loaded = true;
  }

  /// Get all emergency contacts
  List<EmergencyContact> getEmergencyContacts() {
    // Synchronous snapshot (may be empty until first load). Call fetchEmergencyContacts() for async load.
    return List.unmodifiable(_emergencyContacts);
  }

  Future<List<EmergencyContact>> fetchEmergencyContacts() async {
    await _ensureLoaded();
    return List.unmodifiable(_emergencyContacts);
  }

  /// Get first emergency contact (if any)
  EmergencyContact? getFirstContact() {
    return _emergencyContacts.isNotEmpty ? _emergencyContacts.first : null;
  }

  /// Add a new emergency contact
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    await _ensureLoaded();
    _emergencyContacts.add(contact);
    await _storage.upsertContact(contact);
  }

  /// Update an existing emergency contact
  Future<void> updateEmergencyContact(EmergencyContact updatedContact) async {
    await _ensureLoaded();
    final index = _emergencyContacts
        .indexWhere((contact) => contact.id == updatedContact.id);
    if (index != -1) {
      _emergencyContacts[index] = updatedContact;
      await _storage.upsertContact(updatedContact);
    }
  }

  /// Remove an emergency contact
  Future<void> removeEmergencyContact(String contactId) async {
    await _ensureLoaded();
    _emergencyContacts.removeWhere((contact) => contact.id == contactId);
    await _storage.deleteContact(contactId);
  }

  /// Handle emergency button press
  Future<Map<String, dynamic>> handleEmergencyPress() async {
    await _ensureLoaded();
    final smsService = EmergencySMSService();
    final cacheService = LocationCacheService();

    try {
      // 0. Ensure location service and permission (improves accuracy and avoids Unknown location)
      final loc = Location();
      bool serviceEnabled = await loc.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await loc.requestService();
      }
      PermissionStatus permission = await loc.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await loc.requestPermission();
      }

      // 1. Get best available location (with battery/address) from cache service
      final best = await cacheService.getBestAvailableLocation();

      // 2. Prepare emergency data (flat keys expected by SMS service)
      final emergencyData = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': best?['latitude'],
        'longitude': best?['longitude'],
        'accuracy': best?['accuracy'],
        'address': best?['address'],
        'battery': best?['battery'],
        'success': false,
        'contactsNotified': 0,
      };

      debugPrint(
          'Emergency triggered at: ${emergencyData['address'] ?? 'Unknown location'}');

      // 3. Send emergency notifications via SMS (Android telephony)
      final contacts = getEmergencyContacts();
      if (contacts.isNotEmpty) {
        try {
          final smsResult = await smsService.sendEmergencySMS(
            contacts: contacts,
            locationData: emergencyData,
            userName: 'User',
          );
          
          // Update success status
          if (smsResult.status.name == 'sent') {
            emergencyData['success'] = true;
            emergencyData['contactsNotified'] = contacts.length;
            emergencyData['smsSent'] = true;
          }
          
          debugPrint('✅ Emergency notifications sent via SMS=${smsResult.status.name}');
        } catch (e) {
          debugPrint('❌ Error sending emergency notifications: $e');
          emergencyData['error'] = 'Failed to send notifications: $e';
        }
      } else {
        emergencyData['error'] = 'No emergency contacts configured';
      }

      return emergencyData;
    } catch (e) {
      debugPrint('❌ Error handling emergency: $e');
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'error': 'Failed to get location: $e',
        'primaryContact': getFirstContact()?.toJson(),
        'success': false,
        'contactsNotified': 0,
      };
    }
  }

  /// Call an emergency contact
  Future<void> callEmergencyContact(String contactId) async {
    try {
      // Validate that the contact exists
      final contact = _emergencyContacts.firstWhere(
        (c) => c.id == contactId,
        orElse: () => throw Exception('Contact not found'),
      );

      // Create phone call URL
      final phoneUrl = Uri.parse('tel:${contact.phoneNumber}');

      // Check if phone calls are supported
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
        debugPrint('Calling ${contact.name} at ${contact.phoneNumber}');
      } else {
        debugPrint('Phone calls not supported on this device');
        throw Exception('Phone calls not supported on this device');
      }
    } catch (e) {
      debugPrint('Error calling emergency contact: $e');
      rethrow;
    }
  }

  /// Get emergency information text
  String getEmergencyInfoText() {
    return 'Your safety is our priority. In an emergency, use the button below to alert local authorities and your emergency contacts.';
  }

  /// Get emergency header title
  String getEmergencyHeaderTitle() {
    return 'In case of emergency';
  }

  /// Check if location services are available
  Future<bool> isLocationAvailable() async {
    final loc = Location();
    bool serviceEnabled = await loc.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await loc.requestService();
      if (!serviceEnabled) return false;
    }
    PermissionStatus permission = await loc.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await loc.requestPermission();
      if (permission != PermissionStatus.granted) return false;
    }
    try {
      final data = await loc.getLocation().timeout(const Duration(seconds: 10));
      return data.latitude != null && data.longitude != null;
    } catch (_) {
      return false;
    }
  }

  /// Get emergency status info
  Future<String> getEmergencyStatusInfo() async {
    final hasLocation = await isLocationAvailable();
    final hasContacts = _emergencyContacts.isNotEmpty;

    if (hasLocation && hasContacts) {
      return 'Emergency services ready. Location and contacts configured.';
    } else if (!hasLocation && hasContacts) {
      return 'Emergency contacts ready. Location access needed for full functionality.';
    } else if (hasLocation && !hasContacts) {
      return 'Location ready. Please add emergency contacts for full protection.';
    } else {
      return 'Please enable location and add emergency contacts for full protection.';
    }
  }
}
