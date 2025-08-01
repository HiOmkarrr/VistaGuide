/// User Profile data model
/// Represents user information stored in Firestore and Firebase Auth
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String location;
  final List<String> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profileImageUrl;
  final String? bio;
  final Map<String, dynamic>? settings;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
    this.bio,
    this.settings,
  });

  /// Create UserProfile from JSON (Firestore data)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      location: json['location'] ?? '',
      preferences: List<String>.from(json['preferences'] ?? []),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      profileImageUrl: json['profileImageUrl'],
      bio: json['bio'],
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'])
          : null,
    );
  }

  /// Convert UserProfile to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'location': location,
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'settings': settings,
    };
  }

  /// Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? location,
    List<String>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImageUrl,
    String? bio,
    Map<String, dynamic>? settings,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      settings: settings ?? this.settings,
    );
  }

  /// Get display name (fallback to email if name is empty)
  String get displayName =>
      name.isNotEmpty ? name : (email.isNotEmpty ? email : 'User');

  /// Check if profile is complete
  bool get isComplete => name.isNotEmpty && email.isNotEmpty;

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, location: $location, preferences: $preferences, createdAt: $createdAt, updatedAt: $updatedAt, profileImageUrl: $profileImageUrl, bio: $bio, settings: $settings)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.location == location &&
        other.preferences.toString() == preferences.toString() &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.profileImageUrl == profileImageUrl &&
        other.bio == bio &&
        other.settings.toString() == settings.toString();
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        location.hashCode ^
        preferences.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        profileImageUrl.hashCode ^
        bio.hashCode ^
        settings.hashCode;
  }
}
