import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/journey.dart';
import 'journey_card.dart';

/// Widget for displaying a list of journeys
class JourneyList extends StatelessWidget {
  final List<Journey> journeys;
  final Function(String journeyId) onJourneyTap;
  final String emptyStateMessage;

  const JourneyList({
    super.key,
    required this.journeys,
    required this.onJourneyTap,
    this.emptyStateMessage = 'No journeys found',
  });

  @override
  Widget build(BuildContext context) {
    if (journeys.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: journeys.length,
      itemBuilder: (context, index) {
        final journey = journeys[index];
        return JourneyCard(
          journey: journey,
          onTap: () => onJourneyTap(journey.id),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            emptyStateMessage,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start planning your adventures!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
