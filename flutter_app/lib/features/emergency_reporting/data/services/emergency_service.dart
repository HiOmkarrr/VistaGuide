import '../models/emergency_contact.dart';
import '../../../../core/services/location_weather_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to manage emergency reporting data and functionality
class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  // Mock data - in a real app, this would come from a database or API
  final List<EmergencyContact> _emergencyContacts = [
    const EmergencyContact(
      id: '1',
      name: 'Sophia Carter',
      phoneNumber: '+917678058313',
      label: 'Emergency Contact 1',
      email: 'aniket.saini603@gmail.com',
      isPrimary: true,
    ),
    const EmergencyContact(
      id: '2',
      name: 'Ethan Bennett',
      phoneNumber: '+919769345313',
      label: 'Emergency Contact 2',
      email: 'aniket603saini@gmail.com',
      isPrimary: false,
    ),
  ];

  /// Get all emergency contacts
  List<EmergencyContact> getEmergencyContacts() {
    return List.unmodifiable(_emergencyContacts);
  }

  /// Get primary emergency contact
  EmergencyContact? getPrimaryContact() {
    try {
      return _emergencyContacts.firstWhere((contact) => contact.isPrimary);
    } catch (e) {
      return _emergencyContacts.isNotEmpty ? _emergencyContacts.first : null;
    }
  }

  /// Add a new emergency contact
  void addEmergencyContact(EmergencyContact contact) {
    _emergencyContacts.add(contact);
  }

  /// Update an existing emergency contact
  void updateEmergencyContact(EmergencyContact updatedContact) {
    final index = _emergencyContacts
        .indexWhere((contact) => contact.id == updatedContact.id);
    if (index != -1) {
      _emergencyContacts[index] = updatedContact;
    }
  }

  /// Remove an emergency contact
  void removeEmergencyContact(String contactId) {
    _emergencyContacts.removeWhere((contact) => contact.id == contactId);
  }

  /// Handle emergency button press
  Future<Map<String, dynamic>> handleEmergencyPress() async {
    final locationService = LocationWeatherService();

    try {
      // 1. Get current location
      final position = await locationService.getCurrentLocation();
      String? address;
      String? weather;

      if (position != null) {
        // Get address from coordinates
        address = await locationService.getLocationName(position);
        // Get weather for current location
        final weatherData = await locationService.getWeatherData();
        weather = weatherData != null
            ? '${weatherData.temperature.toInt()}°C, ${weatherData.description}'
            : null;
      }

      // 2. Prepare emergency data
      final emergencyData = {
        'timestamp': DateTime.now().toIso8601String(),
        'location': position != null
            ? {
                'latitude': position.latitude,
                'longitude': position.longitude,
                'accuracy': position.accuracy,
              }
            : null,
        'address': address,
        'weather': weather,
        'primaryContact': getPrimaryContact()?.toJson(),
      };

      debugPrint(
          'Emergency triggered at: ${emergencyData['address'] ?? 'Unknown location'}');

      // 3. In a real implementation, this would:
      // - Send emergency alert to authorities
      // - Notify emergency contacts with location
      // - Log the emergency event to backend
      // - Start continuous location tracking

      return emergencyData;
    } catch (e) {
      debugPrint('Error handling emergency: $e');
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'error': 'Failed to get location: $e',
        'primaryContact': getPrimaryContact()?.toJson(),
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
    final locationService = LocationWeatherService();
    final position = await locationService.getCurrentLocation();
    return position != null;
  }

  /// Get emergency status info
  Future<String> getEmergencyStatusInfo() async {
    final hasLocation = await isLocationAvailable();
    final primaryContact = getPrimaryContact();

    if (hasLocation && primaryContact != null) {
      return 'Emergency services ready. Location and contacts configured.';
    } else if (!hasLocation && primaryContact != null) {
      return 'Emergency contacts ready. Location access needed for full functionality.';
    } else if (hasLocation && primaryContact == null) {
      return 'Location ready. Please add emergency contacts for full protection.';
    } else {
      return 'Please enable location and add emergency contacts for full protection.';
    }
  }
}
