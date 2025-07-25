import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Local Events page - display current events with filters and search
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Festivals', 'Concerts', 'Exhibitions', 'Food'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Events',
        showBackButton: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilterTabs(),
            Expanded(
              child: _buildEventsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 3),
    );
  }

  Widget _buildSearchBar() {
    return const CustomSearchBar(
      hintText: 'Search events',
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedFilter = filter;
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.grey300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsList() {
    final events = _getFilteredEvents();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildEventCard(events[index]);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to event details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: event['color'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  event['icon'],
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'],
                      style: AppTextStyles.eventTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event['date'],
                      style: AppTextStyles.eventDate,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event['description'],
                      style: AppTextStyles.eventDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.grey500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    final allEvents = [
      {
        'title': 'Summer Music Festival',
        'date': 'July 15, 2024 • 7:00 PM',
        'description': 'Join us for an amazing evening of live music featuring local and international artists.',
        'category': 'Festivals',
        'color': AppColors.festivalColor,
        'icon': Icons.music_note,
      },
      {
        'title': 'Art Exhibition',
        'date': 'July 20, 2024 • 6:00 PM',
        'description': 'Discover contemporary art from emerging artists in our gallery space.',
        'category': 'Exhibitions',
        'color': AppColors.exhibitionColor,
        'icon': Icons.palette,
      },
      {
        'title': 'Local Food Festival',
        'date': 'July 25, 2024 • 5:00 PM',
        'description': 'Taste the best local cuisine from various food vendors and restaurants.',
        'category': 'Food',
        'color': AppColors.foodColor,
        'icon': Icons.restaurant,
      },
      {
        'title': 'Outdoor Cinema',
        'date': 'August 5, 2024 • 8:00 PM',
        'description': 'Watch classic movies under the stars in our outdoor cinema setup.',
        'category': 'Concerts',
        'color': AppColors.outdoorColor,
        'icon': Icons.movie,
      },
    ];

    if (selectedFilter == 'All') {
      return allEvents;
    }

    return allEvents.where((event) => event['category'] == selectedFilter).toList();
  }
}
