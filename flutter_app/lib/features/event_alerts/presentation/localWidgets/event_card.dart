import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/event.dart';

/// Reusable event card widget
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildEventIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEventInfo(),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.grey500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: event.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        event.icon,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildEventInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: AppTextStyles.eventTitle,
        ),
        const SizedBox(height: 4),
        Text(
          event.date,
          style: AppTextStyles.eventDate,
        ),
        if (event.location != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.grey500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          event.description,
          style: AppTextStyles.eventDescription,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
