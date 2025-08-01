import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/user_profile.dart';
import '../models/settings_item.dart';
import '../../../../core/navigation/app_routes.dart';

/// Service to manage profile data and functionality
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Cache for user profile to avoid repeated Firebase calls
  UserProfile? _cachedUserProfile;
  String? _cachedUserId;

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
    const SettingsItem(
      id: 'sign_out',
      title: 'Sign Out',
      icon: Icons.logout_outlined,
    ),
  ];

  /// Get current user profile
  UserProfile getUserProfile() {
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser != null) {
      // Check if we have a cached profile for the current user
      if (_cachedUserProfile != null && _cachedUserId == currentUser.uid) {
        return _cachedUserProfile!;
      }

      // Create user profile from Firebase Auth data
      final userProfile = UserProfile(
        id: currentUser.uid,
        name: currentUser.displayName ?? 'User',
        email: currentUser.email ?? '',
        phoneNumber: currentUser.phoneNumber ?? '',
        location: 'Location not set',
        preferences: const ['Travel', 'Photography', 'Culture'],
        createdAt: currentUser.metadata.creationTime ?? DateTime.now(),
        updatedAt: DateTime.now(),
        profileImageUrl: currentUser.photoURL,
      );

      // Cache the profile
      _cachedUserProfile = userProfile;
      _cachedUserId = currentUser.uid;

      return userProfile;
    }

    // Fallback if no user is authenticated
    return UserProfile(
      id: 'guest',
      name: 'Guest User',
      email: '',
      phoneNumber: '',
      location: '',
      preferences: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      // Update Firebase Auth profile
      await currentUser.updateDisplayName(updatedProfile.name);

      // Update cached profile
      _cachedUserProfile = updatedProfile.copyWith(
        updatedAt: DateTime.now(),
      );
      _cachedUserId = currentUser.uid;

      // Note: In a full implementation, you would also update Firestore user document
      // await _firestoreUserService.updateUserProfile(currentUser.uid, updatedProfile);
    }
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
    // For now, this is a placeholder for future navigation implementation
  }

  /// Handle settings item tap
  Future<void> handleSettingsItemTap(
      String itemId, BuildContext context) async {
    // In a real implementation, these would navigate to respective pages
    switch (itemId) {
      case 'personal_info':
        // Navigate to personal information page
        break;
      case 'contact_info':
        // Navigate to contact information page
        break;
      case 'preferences':
        // Navigate to preferences page
        break;
      case 'language':
        // Navigate to language settings page
        break;
      case 'notifications':
        // Navigate to notification settings page
        break;
      case 'privacy':
        // Navigate to privacy settings page
        break;
      case 'sign_out':
        await _showSignOutConfirmation(context);
        break;
      default:
        // Handle unknown settings item
        break;
    }
  }

  /// Show sign out confirmation dialog
  Future<void> _showSignOutConfirmation(BuildContext context) async {
    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true && context.mounted) {
      await _signOut(context);
    }
  }

  /// Sign out the current user
  Future<void> _signOut(BuildContext context) async {
    try {
      await _firebaseAuth.signOut();
      // Clear cached profile data
      _cachedUserProfile = null;
      _cachedUserId = null;

      // Navigate to login screen
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      // Show error message to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Refresh the cached user profile
  void refreshProfile() {
    _cachedUserProfile = null;
    _cachedUserId = null;
  }

  /// Get profile avatar color
  Color getProfileAvatarColor() {
    return const Color(0xFFFFB74D); // Orange color from design
  }

  /// Check if user has profile image
  bool hasProfileImage() {
    final currentUser = _firebaseAuth.currentUser;
    return currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty;
  }

  /// Get section titles
  String getAccountSectionTitle() => 'Account';
  String getAppSettingsSectionTitle() => 'App Settings';
}
