import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Emergency Reporting page - quick access to safety features
class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Emergency',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              _buildEmergencyHeader(),
              const SizedBox(height: 24),
              _buildEmergencyButton(),
              const SizedBox(height: 24),
              _buildEmergencyContacts(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 2),
    );
  }

  Widget _buildEmergencyHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'In case of emergency',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.emergency,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your safety is our priority. In an emergency, use the button below to alert local authorities and your emergency contacts.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final buttonSize = screenWidth * 0.4; // 40% of screen width
        final iconSize = buttonSize * 0.3; // 30% of button size

        return Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.emergency,
            boxShadow: [
              BoxShadow(
                color: AppColors.emergency.withOpacity(0.3),
                blurRadius: screenWidth * 0.04,
                spreadRadius: screenWidth * 0.008,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _handleEmergencyPress();
              },
              borderRadius: BorderRadius.circular(buttonSize / 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning,
                    size: iconSize,
                    color: Colors.white,
                  ),
                  SizedBox(height: buttonSize * 0.04),
                  Text(
                    'Report Emergency',
                    style: AppTextStyles.emergencyButton.copyWith(
                      fontSize: buttonSize * 0.08,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contacts',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          'Sophia Carter',
          'Emergency Contact 1',
          Icons.person,
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          'Ethan Bennett',
          'Emergency Contact 2',
          Icons.person,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Manage Contacts',
          type: ButtonType.secondary,
          size: ButtonSize.fullWidth,
          onPressed: () {
            // Navigate to manage contacts
          },
        ),
      ],
    );
  }

  Widget _buildContactCard(String name, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.grey200,
            child: Icon(icon, color: AppColors.grey600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.success),
            onPressed: () {
              _callContact(name);
            },
          ),
        ],
      ),
    );
  }

  void _handleEmergencyPress() {
    // This would handle the emergency reporting functionality
    // Implementation would include location services, contacting authorities, etc.
  }

  void _callContact(String contactName) {
    // This would initiate a phone call to the emergency contact
    // Implementation would use url_launcher or similar package
  }
}
