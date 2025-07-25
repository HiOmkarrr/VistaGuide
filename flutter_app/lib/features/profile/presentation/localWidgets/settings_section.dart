import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/settings_item.dart';

/// Reusable settings section widget
class SettingsSection extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;
  final Function(String itemId) onItemTap;

  const SettingsSection({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: AppTextStyles.h4,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildSettingsItem(item)),
      ],
    );
  }

  Widget _buildSettingsItem(SettingsItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            item.icon,
            color: AppColors.textSecondary,
          ),
          title: Text(
            item.title,
            style: AppTextStyles.bodyLarge,
          ),
          subtitle: item.subtitle != null
              ? Text(
                  item.subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: item.showArrow
              ? const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.grey500,
                )
              : null,
          onTap: item.isEnabled
              ? () {
                  if (item.onTap != null) {
                    item.onTap!();
                  } else {
                    onItemTap(item.id);
                  }
                }
              : null,
          enabled: item.isEnabled,
        ),
      ),
    );
  }
}
