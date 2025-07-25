import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
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
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: items.map((item) {
              return _buildQuickAccessCard(context, item);
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

        return Card(
          child: InkWell(
            onTap: item.isEnabled ? () => context.go(item.route) : null,
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: item.isEnabled ? 1.0 : 0.5,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: iconSize, color: item.color),
                    SizedBox(height: padding * 0.5),
                    Flexible(
                      child: Text(
                        item.title,
                        style: AppTextStyles.label.copyWith(fontSize: fontSize),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
