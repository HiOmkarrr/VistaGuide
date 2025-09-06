import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/otp_verification_service.dart';
import '../../data/models/emergency_contact.dart';
import '../../data/services/emergency_service.dart';

/// Page for managing emergency contacts - add, edit, delete
class AddEmergencyContactPage extends StatefulWidget {
  const AddEmergencyContactPage({super.key});

  @override
  State<AddEmergencyContactPage> createState() => _AddEmergencyContactPageState();
}

class _AddEmergencyContactPageState extends State<AddEmergencyContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _labelController = TextEditingController();
  
  bool _hasChanges = false;
  final EmergencyService _emergencyService = EmergencyService();
  final OTPVerificationService _otpService = OTPVerificationService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndSaveContact({
    required String name,
    required String phone,
    required String label,
  }) async {
    try {
      // Step 1: Generate and send OTP
      final result = await _otpService.generateAndSendOTP(phoneNumber: phone);
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        return;
      }

      // Step 2: Ask user to enter OTP (show debug code if SMS not available on emulator)
      final verified = await _showOTPInputDialog(phone, result.expiresAt, result.debugOtp);
      if (verified != true) return;

      // Step 3: Save contact
      final contact = EmergencyContact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phoneNumber: phone,
        label: label,
        verified: true,
      );

      await _emergencyService.addEmergencyContact(contact);
      _hasChanges = true;

      // Clear form and refresh
      _nameController.clear();
      _phoneController.clear();
      _labelController.clear();

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact verified and added'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  Future<bool?> _showOTPInputDialog(String phone, DateTime? expiresAt, String? debugOtp) async {
    final controller = TextEditingController();
    bool? verified;

    await showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the OTP sent to $phone'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '6-digit code',
              ),
              maxLength: 6,
            ),
            if (expiresAt != null)
              Text('Expires at: ${expiresAt.toLocal()}'),
            if (debugOtp != null) ...[
              const SizedBox(height: 8),
              Text(
                'Emulator note: use code $debugOtp',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Unfocus keyboard dependencies and pop after this frame
              FocusManager.instance.primaryFocus?.unfocus();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop(false);
                }
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              final res = await _otpService.verifyOTP(phoneNumber: phone, enteredOTP: code);
              if (res.success) {
                verified = true;
                // Ensure no focused text field keeps dependencies while popping
                FocusManager.instance.primaryFocus?.unfocus();
                // Pop after this frame to ensure all dependents detached
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop(true);
                    }
                  });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.message)),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    // Dispose controller after the dialog route is fully removed
    Future.microtask(() => controller.dispose());
    return verified;
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _emergencyService.getEmergencyContacts();

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges);
        return false;
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Manage Emergency Contacts',
        showBackButton: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(_hasChanges),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add New Contact Form
            _buildAddContactForm(),
            
            const SizedBox(height: 24),
            
            // Existing Contacts List with Edit/Delete
            _buildContactsList(contacts),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAddContactForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Emergency Contact',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter contact\'s full name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '+91 9876543210',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Label Field
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  hintText: 'e.g., Family, Friend, Doctor',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const SizedBox(height: 20),
              
              // Add Button
              CustomButton(
                text: 'Add Contact',
                type: ButtonType.primary,
                size: ButtonSize.fullWidth,
                onPressed: _addContact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsList(List<EmergencyContact> contacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Existing Contacts (${contacts.length})',
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        if (contacts.isEmpty)
          _buildEmptyState()
        else
          ...contacts.map((contact) => _buildEditableContactCard(contact)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_add_outlined,
            size: 48,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 12),
          Text(
            'No Emergency Contacts Yet',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first emergency contact using the form above.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.grey200,
              child: Icon(Icons.person, color: AppColors.grey600),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    contact.phoneNumber,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  if (contact.label.isNotEmpty)
                    Text(
                      contact.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.success),
                  onPressed: () => _emergencyService.callEmergencyContact(contact.id),
                  tooltip: 'Call',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => _editContact(contact),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.emergency),
                  onPressed: () => _deleteContact(contact),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addContact() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final label = _labelController.text.trim();

    _verifyAndSaveContact(name: name, phone: phone, label: label.isEmpty ? 'Contact' : label);
  }

  void _editContact(EmergencyContact contact) {
    _showContactDialog(contact: contact);
  }

  void _deleteContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _emergencyService.removeEmergencyContact(contact.id);
                Navigator.of(context).pop();
                _hasChanges = true;
                setState(() {});
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting contact: $e'),
                    backgroundColor: AppColors.emergency,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog({EmergencyContact? contact}) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phoneNumber ?? '');
    final labelController = TextEditingController(text: contact?.label ?? '');
    // No primary flag anymore
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                ),
                // No primary option
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and phone are required')),
                  );
                  return;
                }
                
                final updatedContact = EmergencyContact(
                  id: contact?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  phoneNumber: phone,
                  label: labelController.text.trim().isEmpty ? 'Contact' : labelController.text.trim(),
                );
                
                try {
                  if (contact == null) {
                    await _emergencyService.addEmergencyContact(updatedContact);
                  } else {
                    await _emergencyService.updateEmergencyContact(updatedContact);
                  }
                  
                  Navigator.of(context).pop();
                  _hasChanges = true;
                  this.setState(() {});
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(contact == null ? 'Contact added' : 'Contact updated'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.emergency,
                    ),
                  );
                }
              },
              child: Text(contact == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
    
    // Clean up controllers
    nameController.dispose();
    phoneController.dispose();
    labelController.dispose();
  }
}
