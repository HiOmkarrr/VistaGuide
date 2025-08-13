import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Simplified location and weather widget that doesn't block startup
class SimpleLocationWeatherWidget extends StatelessWidget {
  const SimpleLocationWeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Location Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Location and Weather Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Loading location...',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          
          // Weather Icon and Temp (placeholder)
          Row(
            children: [
              Icon(
                Icons.wb_cloudy,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Loading weather...',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          
          // Refresh Button
          IconButton(
            onPressed: () {
              // TODO: Implement refresh functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location services are initializing...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              Icons.refresh,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
