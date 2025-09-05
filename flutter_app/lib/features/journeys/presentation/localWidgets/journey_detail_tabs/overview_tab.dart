import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../data/models/journey.dart';

/// Overview tab for journey details showing basic trip information at a glance
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
          _buildTripSummaryCard(),
          const SizedBox(height: 16),
          _buildTravelDatesCard(),
          const SizedBox(height: 16),
          _buildDestinationsCard(),
          const SizedBox(height: 16),
          _buildTripStatusCard(),
        ],
      ),
    );
  }


  Widget _buildTripSummaryCard() {
    return _buildCard(
      title: 'Trip Summary',
      icon: Icons.description_outlined,
      iconColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            journey.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryItem(
                icon: Icons.schedule,
                label: 'Duration',
                value: '${journey.durationInDays} days',
                color: AppColors.primary,
              ),
              const SizedBox(width: 24),
              _buildSummaryItem(
                icon: Icons.place,
                label: 'Destinations',
                value: '${journey.destinations.length}',
                color: AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripStatusCard() {
    return _buildCard(
      title: 'Trip Status',
      icon: Icons.timeline,
      iconColor: AppColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusIndicator(),
          const SizedBox(height: 12),
          _buildProgressInfo(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (journey.isCompleted) {
      statusColor = AppColors.success;
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    } else if (journey.isCurrent) {
      statusColor = AppColors.primary;
      statusText = 'Ongoing';
      statusIcon = Icons.flight_takeoff;
    } else if (journey.isUpcoming) {
      statusColor = AppColors.info;
      statusText = 'Upcoming';
      statusIcon = Icons.schedule;
    } else {
      statusColor = AppColors.grey600;
      statusText = 'Past';
      statusIcon = Icons.history;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: AppTextStyles.h4.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo() {
    final now = DateTime.now();

    if (journey.isCompleted) {
      return Text(
        'Trip completed successfully!',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (journey.isCurrent) {
      final daysElapsed = now.difference(journey.startDate).inDays;
      final totalDays = journey.durationInDays;
      final daysRemaining = totalDays - daysElapsed;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$daysRemaining days remaining',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: daysElapsed / totalDays,
            backgroundColor: AppColors.grey300,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      );
    } else if (journey.isUpcoming) {
      final daysUntilStart = journey.startDate.difference(now).inDays;
      return Text(
        'Starts in $daysUntilStart days',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.info,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      final daysSinceEnd = now.difference(journey.endDate).inDays;
      return Text(
        'Ended $daysSinceEnd days ago',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
  }

  Widget _buildDestinationsCard() {
    return _buildCard(
      title: 'Destinations',
      icon: Icons.place_outlined,
      iconColor: Colors.green,
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
      icon: Icons.calendar_month_outlined,
      iconColor: Colors.orange,
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
    IconData? icon,
    Color? iconColor,
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
                if (icon != null && iconColor != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
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
