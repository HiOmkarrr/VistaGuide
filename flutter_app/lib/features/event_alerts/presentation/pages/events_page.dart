import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/events_service.dart';
import '../localWidgets/event_filter_tabs.dart';
import '../localWidgets/events_list.dart';

/// Local Events page - display current events with filters and search
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String selectedFilter = 'All';
  final EventsService _eventsService = EventsService();

  @override
  Widget build(BuildContext context) {
    final filters = _eventsService.getFilterCategories();
    final events = _eventsService.getEventsByCategory(selectedFilter);

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
            EventFilterTabs(
              filters: filters,
              selectedFilter: selectedFilter,
              onFilterSelected: (filter) {
                setState(() {
                  selectedFilter = filter;
                });
              },
            ),
            Expanded(
              child: EventsList(
                events: events,
                onEventTap: (eventId) =>
                    _eventsService.navigateToEventDetails(eventId),
              ),
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
}
