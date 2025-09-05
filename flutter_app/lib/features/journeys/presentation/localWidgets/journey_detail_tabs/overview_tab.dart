import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../data/models/journey.dart';

/// Overview tab for journey details showing basic information
class OverviewTab extends StatelessWidget {
  final Journey journey;

  const OverviewTab({
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
          _buildDescriptionCard(),
          const SizedBox(height: 16),
          _buildDurationCard(),
          const SizedBox(height: 16),
          _buildDestinationsCard(),
          const SizedBox(height: 16),
          _buildTravelDatesCard(),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _buildCard(
      title: 'Description',
      child: Text(
        journey.description,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildDurationCard() {
    return _buildCard(
      title: 'Duration',
      child: Text(
        '${journey.durationInDays} days',
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDestinationsCard() {
    return _buildCard(
      title: 'Destinations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${journey.destinations.length} destinations',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...journey.destinations.asMap().entries.map(
                (entry) => _buildDestinationItem(
                  entry.key + 1,
                  entry.value,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildDestinationItem(int index, String destination) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              destination,
              style: AppTextStyles.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelDatesCard() {
    return _buildCard(
      title: 'Travel Dates',
      child: Column(
        children: [
          _buildDateRow(
            'Start Date',
            journey.startDate,
            Icons.flight_takeoff,
          ),
          const SizedBox(height: 16),
          _buildDateRow(
            'End Date',
            journey.endDate,
            Icons.flight_land,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime date, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _formatDate(date),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
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
          Text(
            title,
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
