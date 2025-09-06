import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';

/// Dialog to confirm emergency action before sending SMS and making calls
class EmergencyConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String? userName;
  final int contactCount;

  const EmergencyConfirmationDialog({
    super.key,
    required this.onConfirm,
    this.onCancel,
    this.userName,
    this.contactCount = 0,
  });

  /// Show emergency confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String? userName,
    int contactCount = 0,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => EmergencyConfirmationDialog(
        onConfirm: onConfirm,
        onCancel: onCancel,
        userName: userName,
        contactCount: contactCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button dismissal
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emergency Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.emergency.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency,
                  color: AppColors.emergency,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'Emergency Alert',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.emergency,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Main warning text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emergency.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.emergency.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will immediately:',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Action list
                    _buildActionItem(
                      icon: Icons.sms,
                      text: contactCount > 0 
                        ? 'Send emergency SMS to $contactCount contact${contactCount > 1 ? 's' : ''}'
                        : 'Send emergency SMS to all emergency contacts',
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildActionItem(
                      icon: Icons.phone,
                      text: 'Call your first emergency contact',
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildActionItem(
                      icon: Icons.location_on,
                      text: 'Share your current location',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Warning note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only use this in real emergencies',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      type: ButtonType.secondary,
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        onCancel?.call();
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Confirm button
                  Expanded(
                    child: CustomButton(
                      text: 'Send Alert',
                      type: ButtonType.primary,
                      backgroundColor: AppColors.emergency,
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        // Defer callback to next microtask to avoid navigator lock
                        Future.microtask(() => onConfirm());
                      },
                    ),
                  ),
                ],
              ),

              if (contactCount == 0) ...[
                const SizedBox(height: 12),
                Text(
                  'No emergency contacts found. Add contacts first.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.orange.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build action item with icon and text
  Widget _buildActionItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Loading dialog to show while emergency actions are being processed
class EmergencyLoadingDialog extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback? onCancel;

  const EmergencyLoadingDialog({
    super.key,
    this.message = 'Sending emergency alert...',
    this.subtitle,
    this.onCancel,
  });

  /// Show emergency loading dialog
  static Future<void> show({
    required BuildContext context,
    String message = 'Sending emergency alert...',
    String? subtitle,
    VoidCallback? onCancel,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => EmergencyLoadingDialog(
        message: message,
        subtitle: subtitle,
        onCancel: onCancel != null ? () {
          Navigator.of(context, rootNavigator: true).pop();
          onCancel();
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading indicator
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: AppColors.emergency,
                  strokeWidth: 4,
                ),
              ),

              const SizedBox(height: 24),

              // Main message
              Text(
                message,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emergency,
                    color: AppColors.emergency,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Emergency in progress...',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              if (onCancel != null) ...[
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Cancel',
                  type: ButtonType.secondary,
                  size: ButtonSize.small,
                  onPressed: onCancel,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Success dialog to show emergency actions completed
class EmergencySuccessDialog extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onClose;

  const EmergencySuccessDialog({
    super.key,
    this.message = 'Emergency alert sent successfully',
    this.details,
    this.onClose,
  });

  /// Show emergency success dialog
  static Future<void> show({
    required BuildContext context,
    String message = 'Emergency alert sent successfully',
    String? details,
    VoidCallback? onClose,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (context) => EmergencySuccessDialog(
        message: message,
        details: details,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 30,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'Alert Sent',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Main message
            Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            CustomButton(
              text: 'OK',
              type: ButtonType.primary,
              size: ButtonSize.fullWidth,
              onPressed: () {
                Navigator.of(context).pop();
                onClose?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
