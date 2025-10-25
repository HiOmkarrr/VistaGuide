import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';

/// Reusable camera section widget with responsive design
class CameraSection extends StatelessWidget {
  final VoidCallback onCameraPressed;
  final String? selectedImagePath;
  final String buttonText;
  final String placeholderText;
  final bool isEnabled;

  const CameraSection({
    super.key,
    required this.onCameraPressed,
    this.selectedImagePath,
    this.buttonText = 'Take Photo',
    this.placeholderText = 'No photo selected',
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cameraSize = screenWidth * 0.4; // 40% of screen width
        final iconSize = cameraSize * 0.3; // 30% of camera container size

        return Column(
          children: [
            _buildImageContainer(screenWidth, cameraSize, iconSize),
            SizedBox(height: screenWidth * 0.06),
            _buildCameraButton(),
          ],
        );
      },
    );
  }

  Widget _buildImageContainer(
      double screenWidth, double cameraSize, double iconSize) {
    return Container(
      width: cameraSize,
      height: cameraSize,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: AppColors.grey300, width: 2),
      ),
      child: selectedImagePath != null
          ? _buildSelectedImage()
          : _buildPlaceholder(cameraSize, iconSize, screenWidth),
    );
  }

  Widget _buildSelectedImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: AppColors.grey200,
        child: const Center(
          child: Icon(
            Icons.image,
            size: 48,
            color: AppColors.grey500,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(
      double cameraSize, double iconSize, double screenWidth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: iconSize,
          color: AppColors.grey500,
        ),
        SizedBox(height: cameraSize * 0.08),
        Text(
          placeholderText,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: screenWidth * 0.035,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraButton() {
    return CustomButton(
      text: buttonText,
      type: ButtonType.primary,
      size: ButtonSize.fullWidth,
      icon: const Icon(Icons.camera_alt),
      onPressed: isEnabled ? onCameraPressed : null,
    );
  }
}
