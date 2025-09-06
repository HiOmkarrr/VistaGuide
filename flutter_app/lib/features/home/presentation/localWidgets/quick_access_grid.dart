import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/emergency_numbers_service.dart';
import '../../../../features/emergency_reporting/data/services/emergency_service.dart';
import '../../data/models/quick_access_item.dart';

/// Reusable quick access grid widget
class QuickAccessGrid extends StatelessWidget {
  final List<QuickAccessItem> items;
  final String sectionTitle;

  const QuickAccessGrid({
    super.key,
    required this.items,
    this.sectionTitle = 'Quick Access',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            sectionTitle,
            style: AppTextStyles.h3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 2,
                    right: index == items.length - 1 ? 0 : 2,
                  ),
                  child: _buildQuickAccessCard(context, item),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuickAccessCard(BuildContext context, QuickAccessItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final iconSize = screenWidth * 0.08; // 8% of screen width
        final fontSize = screenWidth * 0.03; // 3% of screen width
        final padding = screenWidth * 0.03; // 3% of screen width

        return SizedBox(
          width: double.infinity, // Ensure full width
          child: Card(
            margin: EdgeInsets.zero, // Remove default card margin
            child: InkWell(
              onTap:
                  item.isEnabled ? () => _handleItemTap(context, item) : null,
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: item.isEnabled ? 1.0 : 0.5,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: padding * 1.2,
                    horizontal: padding * 0.8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: iconSize, color: item.color),
                      SizedBox(height: padding * 0.6),
                      Text(
                        item.title,
                        style: AppTextStyles.label.copyWith(fontSize: fontSize),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handle tap on quick access item
  void _handleItemTap(BuildContext context, QuickAccessItem item) async {
    try {
      debugPrint('🔘 Quick access item tapped: ${item.id}');

      // Handle different route types
      if (item.route.startsWith('dialer:')) {
        // Direct dialer actions
        final number = item.route.replaceFirst('dialer:', '');
        final emergencyService = EmergencyNumbersService();

        if (number == '108') {
          await emergencyService.callEmergencyNumber(EmergencyType.medical);
        } else if (number == '100') {
          await emergencyService.callEmergencyNumber(EmergencyType.police);
        } else {
          await emergencyService.callPhoneNumber(number);
        }
      } else if (item.route == 'emergency:trigger') {
        // Emergency trigger - show confirmation dialog and handle emergency
        await _handleEmergencyTrigger(context);
      } else {
        // Standard navigation
        context.go(item.route);
      }
    } catch (e) {
      debugPrint('❌ Error handling quick access tap: $e');

      // Show error to user
      if (context.mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Phone calls not supported')) {
          errorMessage =
              'Phone dialer not available (emulator limitation). On real device, this will open the dialer.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor:
                errorMessage.contains('emulator') ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle emergency trigger with confirmation dialog
  Future<void> _handleEmergencyTrigger(BuildContext context) async {
    // Import emergency services dynamically to avoid circular imports
    final EmergencyService emergencyService = EmergencyService();
    final contacts = emergencyService.getEmergencyContacts();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Emergency Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will immediately:'),
            const SizedBox(height: 8),
            const Text('• Send SMS to all emergency contacts'),
            const Text('• Call your primary emergency contact'),
            const Text('• Share your current location'),
            const SizedBox(height: 16),
            if (contacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '⚠️ No emergency contacts found. Add contacts first.',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              Text(
                  'Will notify ${contacts.length} contact${contacts.length > 1 ? 's' : ''}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed:
                contacts.isEmpty ? null : () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending emergency alert...'),
          ],
        ),
      ),
    );

    try {
      // Handle emergency
      final result = await emergencyService.handleEmergencyPress();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show result
      if (context.mounted) {
        final success = result['success'] == true;
        final message = success
            ? 'Emergency alert sent successfully!'
            : 'Failed to send emergency alert: ${result['error']}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
