import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/landmark_recognition_service.dart';
import '../localWidgets/recognition_instructions.dart';
import '../localWidgets/camera_section.dart';
import '../localWidgets/recent_recognitions.dart';

/// Landmark Recognition page - identify landmarks from photos
class LandmarkRecognitionPage extends StatelessWidget {
  const LandmarkRecognitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final recognitionService = LandmarkRecognitionService();
    final recentRecognitions = recognitionService.getRecentRecognitions();

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
              RecognitionInstructions(
                title: recognitionService.getInstructionsTitle(),
                subtitle: recognitionService.getInstructionsSubtitle(),
              ),
              const SizedBox(height: 24),
              CameraSection(
                onCameraPressed: () =>
                    recognitionService.showImageSourceDialog(),
              ),
              const SizedBox(height: 24),
              RecentRecognitions(
                recognitions: recentRecognitions,
                onRecognitionTap: (recognitionId) =>
                    recognitionService.handleRecognitionTap(recognitionId),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}
