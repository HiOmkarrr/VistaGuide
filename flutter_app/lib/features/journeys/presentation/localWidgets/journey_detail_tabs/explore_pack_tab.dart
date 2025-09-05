import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../data/models/journey.dart';

/// Explore & Pack tab for journey details showing attractions, events, and packing checklist
class ExplorePackTab extends StatefulWidget {
  final Journey journey;

  const ExplorePackTab({
    super.key,
    required this.journey,
  });

  @override
  State<ExplorePackTab> createState() => _ExplorePackTabState();
}

class _ExplorePackTabState extends State<ExplorePackTab> {
  final List<bool> _checkedItems = List.generate(8, (index) => false);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNearbyAttractionsCard(),
          const SizedBox(height: 16),
          _buildLocalEventsCard(),
          const SizedBox(height: 16),
          _buildPackingChecklistCard(),
        ],
      ),
    );
  }

  Widget _buildNearbyAttractionsCard() {
    final attractions = [
      {'name': 'Local Museum', 'distance': '0.5 km away', 'icon': Icons.museum},
      {'name': 'City Park', 'distance': '1.2 km away', 'icon': Icons.park},
      {
        'name': 'Historic District',
        'distance': '2.0 km away',
        'icon': Icons.location_city
      },
    ];

    return _buildCard(
      title: 'Nearby Attractions',
      icon: Icons.place,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          ...attractions.map((attraction) => _buildAttractionItem(
                icon: attraction['icon'] as IconData,
                name: attraction['name'] as String,
                distance: attraction['distance'] as String,
              )),
          const SizedBox(height: 12),
          _buildExploreMoreButton(),
        ],
      ),
    );
  }

  Widget _buildLocalEventsCard() {
    final events = [
      {
        'name': 'Music Festival',
        'time': 'This Weekend',
        'icon': Icons.music_note
      },
      {
        'name': 'Food Market',
        'time': 'Every Saturday',
        'icon': Icons.restaurant
      },
      {'name': 'Art Exhibition', 'time': 'Next Month', 'icon': Icons.palette},
    ];

    return _buildCard(
      title: 'Local Events',
      icon: Icons.event,
      iconColor: AppColors.info,
      child: Column(
        children: [
          ...events.map((event) => _buildEventItem(
                icon: event['icon'] as IconData,
                name: event['name'] as String,
                time: event['time'] as String,
              )),
          const SizedBox(height: 12),
          _buildViewAllEventsButton(),
        ],
      ),
    );
  }

  Widget _buildPackingChecklistCard() {
    final checklistItems = [
      'Passport & Travel Documents',
      'Travel Insurance',
      'Medications',
      'Phone Charger',
      'Camera',
      'Comfortable Shoes',
      'Weather-appropriate Clothing',
      'Local Currency',
    ];

    final checkedCount = _checkedItems.where((item) => item).length;

    return _buildCard(
      title: 'Packing Checklist',
      icon: Icons.checklist,
      iconColor: AppColors.success,
      trailing: Text(
        '$checkedCount/${checklistItems.length}',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      child: Column(
        children: checklistItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return _buildChecklistItem(
            item: item,
            isChecked: _checkedItems[index],
            onChanged: (value) {
              setState(() {
                _checkedItems[index] = value ?? false;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttractionItem({
    required IconData icon,
    required String name,
    required String distance,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  distance,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_right,
                size: 16,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              // Navigate to attraction details
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening $name details...'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem({
    required IconData icon,
    required String name,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.info,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 16,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              // Add event to calendar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name added to your calendar!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required String item,
    required bool isChecked,
    required Function(bool?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            onChanged: onChanged,
            activeColor: AppColors.success,
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
                color:
                    isChecked ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreMoreButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Explore more attractions
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening nearby attractions map...'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        icon: Icon(
          Icons.explore,
          size: 16,
          color: AppColors.primary,
        ),
        label: Text(
          'Explore More',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllEventsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // View all events
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening local events calendar...'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        icon: Icon(
          Icons.calendar_today,
          size: 16,
          color: AppColors.info,
        ),
        label: Text(
          'View All Events',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.info,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.info),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
