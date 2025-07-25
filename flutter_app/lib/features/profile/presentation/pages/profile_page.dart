import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// User Profile page - manage personal information and app settings
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildAccountSection(),
              const SizedBox(height: 24),
              _buildAppSettingsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 4),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surface,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.grey200,
            child: ClipOval(
              child: Container(
                width: 100,
                height: 100,
                color: const Color(0xFFFFB74D), // Orange color from design
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sophia Clark',
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              // Navigate to view profile
            },
            child: Text(
              'View Profile',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Account',
            style: AppTextStyles.h4,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          icon: Icons.person_outline,
          title: 'Personal Information',
          onTap: () {
            // Navigate to personal information
          },
        ),
        _buildSettingsItem(
          icon: Icons.phone_outlined,
          title: 'Contact Information',
          onTap: () {
            // Navigate to contact information
          },
        ),
        _buildSettingsItem(
          icon: Icons.settings_outlined,
          title: 'Preferences',
          onTap: () {
            // Navigate to preferences
          },
        ),
      ],
    );
  }

  Widget _buildAppSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'App Settings',
            style: AppTextStyles.h4,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          icon: Icons.language_outlined,
          title: 'Language',
          onTap: () {
            // Navigate to language settings
          },
        ),
        _buildSettingsItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () {
            // Navigate to notification settings
          },
        ),
        _buildSettingsItem(
          icon: Icons.security_outlined,
          title: 'Privacy Settings',
          onTap: () {
            // Navigate to privacy settings
          },
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            icon,
            color: AppColors.textSecondary,
          ),
          title: Text(
            title,
            style: AppTextStyles.bodyLarge,
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.grey500,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
