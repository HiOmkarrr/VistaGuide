import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/profile_service.dart';
import '../localWidgets/profile_header.dart';
import '../localWidgets/settings_section.dart';

/// User Profile page - manage personal information and app settings
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();
    final userProfile = profileService.getUserProfile();
    final accountSettings = profileService.getAccountSettings();
    final appSettings = profileService.getAppSettings();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Settings',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeader(
                userProfile: userProfile,
                avatarColor: profileService.getProfileAvatarColor(),
                hasProfileImage: profileService.hasProfileImage(),
                onViewProfileTap: () => profileService.handleViewProfile(),
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: profileService.getAccountSectionTitle(),
                items: accountSettings,
                onItemTap: (itemId) =>
                    profileService.handleSettingsItemTap(itemId),
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: profileService.getAppSettingsSectionTitle(),
                items: appSettings,
                onItemTap: (itemId) =>
                    profileService.handleSettingsItemTap(itemId),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 4),
    );
  }
}
