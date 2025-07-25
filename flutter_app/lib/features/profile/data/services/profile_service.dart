import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/user_profile.dart';
import '../models/settings_item.dart';

/// Service to manage profile data and functionality
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // Mock user profile data
  UserProfile _userProfile = UserProfile(
    id: '1',
    name: 'Sophia Clark',
    email: 'sophia.clark@email.com',
    phoneNumber: '+1-555-0123',
    location: 'New York, USA',
    preferences: ['Travel', 'Photography', 'Culture'],
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
    updatedAt: DateTime.now(),
  );

  // Account settings items
  final List<SettingsItem> _accountSettings = [
    const SettingsItem(
      id: 'personal_info',
      title: 'Personal Information',
      icon: Icons.person_outline,
    ),
    const SettingsItem(
      id: 'contact_info',
      title: 'Contact Information',
      icon: Icons.phone_outlined,
    ),
    const SettingsItem(
      id: 'preferences',
      title: 'Preferences',
      icon: Icons.settings_outlined,
    ),
  ];

  // App settings items
  final List<SettingsItem> _appSettings = [
    const SettingsItem(
      id: 'language',
      title: 'Language',
      icon: Icons.language_outlined,
    ),
    const SettingsItem(
      id: 'notifications',
      title: 'Notifications',
      icon: Icons.notifications_outlined,
    ),
    const SettingsItem(
      id: 'privacy',
      title: 'Privacy Settings',
      icon: Icons.security_outlined,
    ),
  ];

  /// Get current user profile
  UserProfile getUserProfile() {
    return _userProfile;
  }

  /// Update user profile
  void updateUserProfile(UserProfile updatedProfile) {
    _userProfile = updatedProfile.copyWith(
      updatedAt: DateTime.now(),
    );
  }

  /// Get account settings items
  List<SettingsItem> getAccountSettings() {
    return List.unmodifiable(_accountSettings);
  }

  /// Get app settings items
  List<SettingsItem> getAppSettings() {
    return List.unmodifiable(_appSettings);
  }

  /// Handle view profile action
  void handleViewProfile() {
    // In a real implementation, this would navigate to profile details
    print('Navigating to profile details');
    // TODO: Implement profile details navigation
  }

  /// Handle settings item tap
  void handleSettingsItemTap(String itemId) {
    switch (itemId) {
      case 'personal_info':
        print('Navigating to personal information');
        // TODO: Navigate to personal information page
        break;
      case 'contact_info':
        print('Navigating to contact information');
        // TODO: Navigate to contact information page
        break;
      case 'preferences':
        print('Navigating to preferences');
        // TODO: Navigate to preferences page
        break;
      case 'language':
        print('Navigating to language settings');
        // TODO: Navigate to language settings page
        break;
      case 'notifications':
        print('Navigating to notification settings');
        // TODO: Navigate to notification settings page
        break;
      case 'privacy':
        print('Navigating to privacy settings');
        // TODO: Navigate to privacy settings page
        break;
      default:
        print('Unknown settings item: $itemId');
    }
  }

  /// Get profile avatar color
  Color getProfileAvatarColor() {
    return const Color(0xFFFFB74D); // Orange color from design
  }

  /// Check if user has profile image
  bool hasProfileImage() {
    return _userProfile.profileImageUrl != null &&
        _userProfile.profileImageUrl!.isNotEmpty;
  }

  /// Get section titles
  String getAccountSectionTitle() => 'Account';
  String getAppSettingsSectionTitle() => 'App Settings';
}
