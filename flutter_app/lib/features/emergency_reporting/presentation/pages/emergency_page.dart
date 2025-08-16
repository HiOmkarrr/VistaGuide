import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/emergency_service.dart';
import '../localWidgets/emergency_header.dart';
import '../localWidgets/emergency_button.dart';
import '../localWidgets/emergency_contacts_list.dart';

/// Emergency Reporting page - quick access to safety features
class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyService = EmergencyService();
    final emergencyContacts = emergencyService.getEmergencyContacts();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Emergency',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              EmergencyHeader(
                title: emergencyService.getEmergencyHeaderTitle(),
                description: emergencyService.getEmergencyInfoText(),
              ),
              const SizedBox(height: 24),
              EmergencyButton(
                onPressed: () async {
                  final emergencyData =
                      await emergencyService.handleEmergencyPress();

                  // Show confirmation to user
                  if (context.mounted) {
                    final location =
                        emergencyData['address'] ?? 'Unknown location';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Emergency alert sent from: $location'),
                        backgroundColor: AppColors.emergency,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              EmergencyContactsList(
                contacts: emergencyContacts,
                onCallContact: (contactId) =>
                    emergencyService.callEmergencyContact(contactId),
                onManageContacts: () {
                  // Navigate to manage contacts
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 3),
    );
  }
}
