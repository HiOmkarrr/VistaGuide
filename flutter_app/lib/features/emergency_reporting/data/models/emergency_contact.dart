/// Emergency contact data model
class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String label;
  final String? email;
  final bool isPrimary;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.label,
    this.email,
    this.isPrimary = false,
  });

  /// Create a copy of this contact with updated fields
  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? label,
    String? email,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      label: label ?? this.label,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'label': label,
      'email': email,
      'isPrimary': isPrimary,
    };
  }

  /// Create from JSON
  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      label: json['label'] as String,
      email: json['email'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyContact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EmergencyContact(id: $id, name: $name, phoneNumber: $phoneNumber, label: $label, isPrimary: $isPrimary)';
  }
}
