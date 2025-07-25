import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/landmark_recognition.dart';

/// Reusable recent recognitions widget
class RecentRecognitions extends StatelessWidget {
  final List<LandmarkRecognition> recognitions;
  final Function(String recognitionId) onRecognitionTap;
  final String sectionTitle;

  const RecentRecognitions({
    super.key,
    required this.recognitions,
    required this.onRecognitionTap,
    this.sectionTitle = 'Recent Recognitions',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: 16),
        if (recognitions.isEmpty)
          _buildEmptyState()
        else
          _buildRecognitionsList(),
      ],
    );
  }

  Widget _buildRecognitionsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final cardHeight = screenHeight * 0.1; // 10% of screen height

        return SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recognitions.length,
            itemBuilder: (context, index) {
              final recognition = recognitions[index];
              return _buildRecognitionCard(context, recognition, cardHeight);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecognitionCard(BuildContext context,
      LandmarkRecognition recognition, double cardHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.25; // 25% of screen width
    final iconSize = cardHeight * 0.3; // 30% of card height
    final fontSize = screenWidth * 0.025; // Responsive font size

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: screenWidth * 0.03),
      child: Card(
        child: InkWell(
          onTap: () => onRecognitionTap(recognition.id),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.image,
                          color: AppColors.grey500,
                          size: iconSize,
                        ),
                      ),
                      if (recognition.isHighConfidence)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(cardHeight * 0.08),
                child: Text(
                  recognition.landmarkName,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: fontSize),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Center(
        child: Text(
          'No recent recognitions yet',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.grey500,
          ),
        ),
      ),
    );
  }
}
