import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/user_profile.dart';

/// Reusable profile header widget
class ProfileHeader extends StatelessWidget {
  final UserProfile userProfile;
  final Color avatarColor;
  final bool hasProfileImage;
  final VoidCallback onViewProfileTap;

  const ProfileHeader({
    super.key,
    required this.userProfile,
    required this.avatarColor,
    required this.hasProfileImage,
    required this.onViewProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surface,
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 16),
          Text(
            userProfile.displayName,
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onViewProfileTap,
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

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: AppColors.grey200,
      child: ClipOval(
        child: hasProfileImage ? _buildProfileImage() : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildProfileImage() {
    // In a real implementation, this would load the actual image
    return Container(
      width: 100,
      height: 100,
      color: AppColors.grey300,
      child: const Icon(
        Icons.image,
        size: 40,
        color: AppColors.grey500,
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      color: avatarColor,
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
      ),
    );
  }
}
