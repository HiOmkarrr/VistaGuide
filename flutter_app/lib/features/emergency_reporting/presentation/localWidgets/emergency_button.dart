import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Reusable emergency button widget with responsive design
class EmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;
  final IconData icon;

  const EmergencyButton({
    super.key,
    required this.onPressed,
    this.buttonText = 'Report Emergency',
    this.icon = Icons.warning,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final buttonSize = screenWidth * 0.4; // 40% of screen width
        final iconSize = buttonSize * 0.3; // 30% of button size

        return Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.emergency,
            boxShadow: [
              BoxShadow(
                color: AppColors.emergency.withOpacity(0.3),
                blurRadius: screenWidth * 0.04,
                spreadRadius: screenWidth * 0.008,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(buttonSize / 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: iconSize,
                    color: Colors.white,
                  ),
                  SizedBox(height: buttonSize * 0.04),
                  Text(
                    buttonText,
                    style: AppTextStyles.emergencyButton.copyWith(
                      fontSize: buttonSize * 0.08,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
