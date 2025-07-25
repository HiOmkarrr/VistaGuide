import '../models/emergency_contact.dart';

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
      phoneNumber: '+1-555-0123',
      label: 'Emergency Contact 1',
      email: 'sophia.carter@email.com',
      isPrimary: true,
    ),
    const EmergencyContact(
      id: '2',
      name: 'Ethan Bennett',
      phoneNumber: '+1-555-0456',
      label: 'Emergency Contact 2',
      email: 'ethan.bennett@email.com',
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
  Future<void> handleEmergencyPress() async {
    // In a real implementation, this would:
    // 1. Get current location
    // 2. Send emergency alert to authorities
    // 3. Notify emergency contacts
    // 4. Log the emergency event

    // In a real implementation, this would trigger emergency protocols
    // For now, this is a placeholder for emergency handling logic
  }

  /// Call an emergency contact
  Future<void> callEmergencyContact(String contactId) async {
    // Validate that the contact exists
    _emergencyContacts.firstWhere(
      (c) => c.id == contactId,
      orElse: () => throw Exception('Contact not found'),
    );

    // In a real implementation, this would use url_launcher to make a phone call
    // For now, this is a placeholder for phone call functionality
  }

  /// Get emergency information text
  String getEmergencyInfoText() {
    return 'Your safety is our priority. In an emergency, use the button below to alert local authorities and your emergency contacts.';
  }

  /// Get emergency header title
  String getEmergencyHeaderTitle() {
    return 'In case of emergency';
  }
}
