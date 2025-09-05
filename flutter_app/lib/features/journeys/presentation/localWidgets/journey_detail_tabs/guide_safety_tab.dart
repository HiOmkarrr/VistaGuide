import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../data/models/journey.dart';

/// Guide & Safety tab for journey details showing safety and health information
class GuideSafetyTab extends StatelessWidget {
  final Journey journey;

  const GuideSafetyTab({
    super.key,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSafetyInformationCard(),
          const SizedBox(height: 16),
          _buildHealthAdvisoriesCard(),
        ],
      ),
    );
  }

  Widget _buildSafetyInformationCard() {
    return _buildCard(
      title: 'Safety Information',
      icon: Icons.shield_outlined,
      iconColor: AppColors.info,
      child: Column(
        children: [
          _buildSafetyItem(
            icon: Icons.warning_amber,
            iconColor: Colors.orange,
            title: 'Travel Advisories',
            description:
                'Check current travel advisories for your destinations',
          ),
          const SizedBox(height: 16),
          _buildSafetyItem(
            icon: Icons.local_hospital,
            iconColor: AppColors.emergency,
            title: 'Medical Facilities',
            description: 'Locate nearby hospitals and medical centers',
          ),
          const SizedBox(height: 16),
          _buildSafetyItem(
            icon: Icons.phone,
            iconColor: AppColors.success,
            title: 'Emergency Numbers',
            description: 'Keep local emergency contact numbers handy',
          ),
          const SizedBox(height: 16),
          _buildInfoBanner(),
        ],
      ),
    );
  }

  Widget _buildHealthAdvisoriesCard() {
    return _buildCard(
      title: 'Health Advisories',
      icon: Icons.favorite_outline,
      iconColor: AppColors.success,
      child: Column(
        children: [
          _buildSafetyItem(
            icon: Icons.vaccines,
            iconColor: AppColors.primary,
            title: 'Vaccinations',
            description: 'Check required vaccinations for your destination',
          ),
          const SizedBox(height: 16),
          _buildSafetyItem(
            icon: Icons.security,
            iconColor: AppColors.info,
            title: 'Travel Insurance',
            description: 'Ensure you have adequate travel health insurance',
          ),
          const SizedBox(height: 16),
          _buildSafetyItem(
            icon: Icons.medication,
            iconColor: Colors.green,
            title: 'Medications',
            description: 'Pack necessary medications and prescriptions',
          ),
          const SizedBox(height: 16),
          _buildSafetyItem(
            icon: Icons.water_drop,
            iconColor: Colors.blue,
            title: 'Water Safety',
            description: 'Be cautious about drinking water and food safety',
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Always inform someone about your travel plans and expected return',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
