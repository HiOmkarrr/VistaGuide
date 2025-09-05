import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../data/models/journey.dart';
import '../../../data/models/journey_details_data.dart';

/// Safety & Weather tab for journey details showing emergency info and weather conditions
class SafetyWeatherTab extends StatelessWidget {
  final Journey journey;

  const SafetyWeatherTab({
    super.key,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {
    // Use AI-generated data if available, otherwise use fallback dummy data
    final data = journey.journeyDetails ?? dummyJourneyDetails;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeatherCard(data.weather),
          const SizedBox(height: 16),
          _buildWhatToBringCard(data.whatToBring),
          const SizedBox(height: 16),
          _buildSafetyNotesCard(data.safetyNotes),
          const SizedBox(height: 16),
          _buildEmergencyContactsCard(data.emergencyContacts),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(WeatherInfo weather) {
    IconData weatherIcon;
    Color weatherColor;
    
    switch (weather.type.toLowerCase()) {
      case 'hot':
        weatherIcon = Icons.wb_sunny;
        weatherColor = Colors.orange;
        break;
      case 'cool':
        weatherIcon = Icons.thermostat;
        weatherColor = Colors.blue;
        break;
      case 'rainy':
        weatherIcon = Icons.cloud;
        weatherColor = Colors.grey;
        break;
      case 'snowy':
        weatherIcon = Icons.ac_unit;
        weatherColor = Colors.lightBlue;
        break;
      default:
        weatherIcon = Icons.wb_cloudy;
        weatherColor = Colors.grey;
    }
    
    return _buildCard(
      title: 'Weather',
      icon: weatherIcon,
      iconColor: weatherColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${weather.type.substring(0, 1).toUpperCase()}${weather.type.substring(1)}, ${weather.temperature}',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Best time to visit: ${weather.bestTime}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatToBringCard(List<String> items) {
    return _buildCard(
      title: 'What to Bring',
      icon: Icons.backpack,
      iconColor: Colors.green,
      child: Column(
        children: items.map((item) => _buildBulletPoint(item)).toList(),
      ),
    );
  }

  Widget _buildSafetyNotesCard(List<String> notes) {
    return _buildCard(
      title: 'Safety Notes',
      icon: Icons.security,
      iconColor: AppColors.emergency,
      child: Column(
        children: notes.map((note) => _buildBulletPoint(note)).toList(),
      ),
    );
  }

  Widget _buildEmergencyContactsCard(EmergencyContacts contacts) {
    return _buildCard(
      title: 'Emergency Contacts',
      icon: Icons.phone,
      iconColor: AppColors.emergency,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Medical: ${contacts.medical}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Police: ${contacts.police}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
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
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
