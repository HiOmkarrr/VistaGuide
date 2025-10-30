import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../data/models/journey.dart';
import '../../../data/models/journey_details_data.dart';

/// Suggestions & Packing tab for journey details showing places, events, and packing essentials
class SuggestionsPackingTab extends StatefulWidget {
  final Journey journey;

  const SuggestionsPackingTab({
    super.key,
    required this.journey,
  });

  @override
  State<SuggestionsPackingTab> createState() => _SuggestionsPackingTabState();
}

class _SuggestionsPackingTabState extends State<SuggestionsPackingTab> {
  late List<bool> _checkedPackingItems;

  @override
  void initState() {
    super.initState();
    final data = widget.journey.journeyDetails ?? dummyJourneyDetails;
    _checkedPackingItems = List.generate(
      data.packingChecklist.length,
      (index) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use AI-generated data if available, otherwise use fallback dummy data
    final data = widget.journey.journeyDetails ?? dummyJourneyDetails;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlacesEventsCard(data.placesEvents),
          const SizedBox(height: 16),
          _buildPackingChecklistCard(data.packingChecklist),
        ],
      ),
    );
  }

  Widget _buildPlacesEventsCard(List<PlaceEvent> placesEvents) {
    return _buildCard(
      title: 'Places & Events',
      icon: Icons.place,
      iconColor: AppColors.primary,
      child: Column(
        children: placesEvents.map((place) => _buildPlaceEventItem(place)).toList(),
      ),
    );
  }

  Widget _buildPackingChecklistCard(List<String> packingItems) {
    final checkedCount = _checkedPackingItems.where((item) => item).length;

    return _buildCard(
      title: 'Packing Checklist',
      icon: Icons.luggage,
      iconColor: Colors.purple,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$checkedCount/${packingItems.length}',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.purple,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Column(
        children: packingItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildChecklistItem(
            item: item,
            isChecked: _checkedPackingItems[index],
            onChanged: (value) {
              setState(() {
                _checkedPackingItems[index] = value ?? false;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlaceEventItem(PlaceEvent placeEvent) {
    // Check if this is an underrated place
    final isUnderrated = placeEvent.isUnderrated;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnderrated 
            ? Colors.amber.withOpacity(0.08)
            : AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnderrated 
              ? Colors.amber.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon indicator
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isUnderrated 
                      ? Colors.amber.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isUnderrated ? Icons.star_rounded : Icons.place_outlined,
                  color: isUnderrated ? Colors.amber.shade700 : AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              // Name and badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      placeEvent.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Badges row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Type badge
                        _buildBadge(
                          placeEvent.type,
                          isUnderrated ? Colors.amber.shade700 : AppColors.primary,
                        ),
                        // Underrated badge
                        if (isUnderrated)
                          _buildBadge(
                            '🌟 Hidden Gem',
                            Colors.amber.shade800,
                            isBold: true,
                          ),
                        // Score badge
                        if (isUnderrated && placeEvent.underratedScore != null)
                          _buildBadge(
                            'Score: ${placeEvent.underratedScore}/10',
                            Colors.green.shade700,
                          ),
                        // Cost badge
                        if (isUnderrated && placeEvent.estimatedCost != null)
                          _buildBadge(
                            placeEvent.estimatedCost!,
                            Colors.blue.shade700,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Location (for underrated places)
          if (isUnderrated && placeEvent.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    placeEvent.location!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Description (for underrated places)
          if (isUnderrated && placeEvent.description != null) ...[
            const SizedBox(height: 8),
            Text(
              placeEvent.description!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String item,
    required bool isChecked,
    required Function(bool?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            onChanged: onChanged,
            activeColor: Colors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item,
              style: AppTextStyles.bodyMedium.copyWith(
                decoration: isChecked ? TextDecoration.lineThrough : null,
                color: isChecked
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
