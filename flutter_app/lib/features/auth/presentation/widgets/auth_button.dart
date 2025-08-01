import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Custom button widget for authentication actions
class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AuthButtonVariant.primary,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AuthButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: variant == AuthButtonVariant.primary
              ? AppColors.primary
              : Colors.transparent,
          foregroundColor: variant == AuthButtonVariant.primary
              ? Colors.white
              : AppColors.primary,
          elevation: variant == AuthButtonVariant.primary ? 2 : 0,
          side: variant == AuthButtonVariant.outline
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Button style variants
enum AuthButtonVariant {
  primary,
  outline,
}
