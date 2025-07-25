import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Landmark Recognition page - identify landmarks from photos
class LandmarkRecognitionPage extends StatelessWidget {
  const LandmarkRecognitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Landmark Recognition',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              _buildInstructions(),
              const SizedBox(height: 24),
              _buildCameraSection(),
              const SizedBox(height: 24),
              _buildRecentRecognitions(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Capture or upload a photo to identify landmarks.',
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Point your camera at a landmark or select from your gallery.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cameraSize = screenWidth * 0.4; // 40% of screen width
        final iconSize = cameraSize * 0.3; // 30% of camera container size

        return Column(
          children: [
            Container(
              width: cameraSize,
              height: cameraSize,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                border: Border.all(color: AppColors.grey300, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: iconSize,
                    color: AppColors.grey500,
                  ),
                  SizedBox(height: cameraSize * 0.08),
                  Text(
                    'No photo selected',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.06),
            CustomButton(
              text: 'Take Photo or Upload',
              type: ButtonType.primary,
              size: ButtonSize.fullWidth,
              icon: const Icon(Icons.camera_alt),
              onPressed: () {
                _showImageSourceDialog();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentRecognitions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Recognitions',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.of(context).size.height;
            final cardHeight = screenHeight * 0.1; // 10% of screen height

            return SizedBox(
              height: cardHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3, // Placeholder count
                itemBuilder: (context, index) {
                  return _buildRecentRecognitionCard(
                      context, index, cardHeight);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentRecognitionCard(
      BuildContext context, int index, double cardHeight) {
    final landmarks = [
      'Eiffel Tower',
      'Statue of Liberty',
      'Big Ben',
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.25; // 25% of screen width
    final iconSize = cardHeight * 0.3; // 30% of card height
    final fontSize = screenWidth * 0.025; // Responsive font size

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: screenWidth * 0.03),
      child: Card(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(Icons.image,
                      color: AppColors.grey500, size: iconSize),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(cardHeight * 0.08),
              child: Text(
                landmarks[index],
                style: AppTextStyles.bodySmall.copyWith(fontSize: fontSize),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    // This would show a dialog to choose between camera and gallery
    // Implementation would be added later with actual image picker functionality
  }
}
