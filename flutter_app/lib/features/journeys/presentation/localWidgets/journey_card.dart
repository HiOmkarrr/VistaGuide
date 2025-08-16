import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/journey.dart';

/// Widget for displaying journey information in a card format
class JourneyCard extends StatelessWidget {
  final Journey journey;
  final VoidCallback onTap;

  const JourneyCard({
    super.key,
    required this.journey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey.title,
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          journey.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 16),
              _buildDateInfo(),
              const SizedBox(height: 12),
              _buildDestinationsInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String label;

    if (journey.isCompleted) {
      backgroundColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      label = 'Completed';
    } else if (journey.isCurrent) {
      backgroundColor = AppColors.primary.withValues(alpha: 0.1);
      textColor = AppColors.primary;
      label = 'Ongoing';
    } else if (journey.isUpcoming) {
      backgroundColor = AppColors.info.withValues(alpha: 0.1);
      textColor = AppColors.info;
      label = 'Upcoming';
    } else {
      backgroundColor = AppColors.grey200;
      textColor = AppColors.grey600;
      label = 'Past';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDateInfo() {
    final startDateStr = _formatDate(journey.startDate);
    final endDateStr = _formatDate(journey.endDate);

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$startDateStr - $endDateStr',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.schedule,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '${journey.durationInDays} days',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
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

  Widget _buildDestinationsInfo() {
    if (journey.destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Icon(
          Icons.place,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            journey.destinations.length > 3
                ? '${journey.destinations.take(3).join(', ')} and ${journey.destinations.length - 3} more'
                : journey.destinations.join(', '),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
