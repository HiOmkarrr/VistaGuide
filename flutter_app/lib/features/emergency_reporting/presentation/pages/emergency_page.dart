import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/emergency_service.dart';
import '../localWidgets/emergency_header.dart';
import '../localWidgets/emergency_button.dart';
import '../localWidgets/emergency_contacts_list.dart';
import '../../data/models/emergency_contact.dart';
import '../widgets/emergency_confirmation_dialog.dart';
import 'add_emergency_contact_page.dart';

/// Emergency Reporting page - quick access to safety features
class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final EmergencyService _emergencyService = EmergencyService();
  late List<EmergencyContact> _contacts;
  bool _loadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final items = await _emergencyService.fetchEmergencyContacts();
    if (!mounted) return;
    setState(() {
      _contacts = items;
      _loadingContacts = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    final emergencyService = _emergencyService;
    final emergencyContacts = _loadingContacts
        ? const <EmergencyContact>[]
        : _contacts;

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
                  final contacts = emergencyService.getEmergencyContacts();
                  
                  // Show confirmation dialog first
                  final confirmed = await EmergencyConfirmationDialog.show(
                    context: context,
                    contactCount: contacts.length,
                    onConfirm: () {
                      // Dialog will call this callback after user confirms
                    },
                  );
                  
                  if (confirmed != true || !context.mounted) return;
                  
                  // Show loading dialog
                  EmergencyLoadingDialog.show(
                    context: context,
                    message: 'Sending emergency alert...',
                    subtitle: 'Notifying your emergency contacts',
                  );
                  
                  try {
                    // Handle emergency action
                    final emergencyData = await emergencyService.handleEmergencyPress();
                    
                    // Close loading dialog (shown with root navigator)
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    
                    // Show success/error dialog based on result
                    if (context.mounted) {
                      if (emergencyData['success'] == true) {
                        final contactsNotified = emergencyData['contactsNotified'] ?? 0;
                        final location = emergencyData['address'] ?? 'Unknown location';
                        
                        EmergencySuccessDialog.show(
                          context: context,
                          message: 'Emergency alert sent successfully',
                          details: 'Notified $contactsNotified ${contactsNotified == 1 ? 'contact' : 'contacts'} from $location',
                        );
                      } else {
                        // Show error in snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${emergencyData['error'] ?? 'Failed to send emergency alert'}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    // Close loading dialog if error occurs
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              if (_loadingContacts)
                const SizedBox.shrink()
              else
                EmergencyContactsList(
                contacts: emergencyContacts,
                onCallContact: (contactId) =>
                    emergencyService.callEmergencyContact(contactId),
                onManageContacts: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddEmergencyContactPage(),
                    ),
                  ).then((result) {
                    // Refresh the page if a contact was added
                    if (result == true && mounted) {
                      _loadContacts();
                    }
                  });
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
