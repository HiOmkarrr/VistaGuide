import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/emergency_contact.dart';
import 'emergency_contact_card.dart';

/// Reusable emergency contacts list widget
class EmergencyContactsList extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final Function(String contactId) onCallContact;
  final VoidCallback onManageContacts;
  final String sectionTitle;

  const EmergencyContactsList({
    super.key,
    required this.contacts,
    required this.onCallContact,
    required this.onManageContacts,
    this.sectionTitle = 'Emergency Contacts',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 16),
        if (contacts.isEmpty) _buildEmptyState() else _buildContactsList(),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Manage Contacts',
          type: ButtonType.secondary,
          size: ButtonSize.fullWidth,
          onPressed: onManageContacts,
        ),
      ],
    );
  }

  Widget _buildContactsList() {
    return Column(
      children: contacts.map((contact) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EmergencyContactCard(
            contact: contact,
            onCall: () => onCallContact(contact.id),
          ),
        );
      }).toList(),
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
          Icon(
            Icons.person_add_outlined,
            size: 48,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 12),
          Text(
            'No Emergency Contacts',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add emergency contacts to ensure help is available when you need it most.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
