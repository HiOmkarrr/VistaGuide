import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../data/services/journey_service.dart';
import '../../data/models/journey.dart';
import '../localWidgets/journey_tabs.dart';
import '../localWidgets/journey_list.dart';

/// Journey page - manage planned and completed trips
class JourneyPage extends StatefulWidget {
  const JourneyPage({super.key});

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  final JourneyService _journeyService = JourneyService();
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final allJourneys = _journeyService.getAllJourneys();
    final upcomingJourneys = _journeyService.getUpcomingJourneys();
    final completedJourneys = _journeyService.getCompletedJourneys();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Journeys',
        showBackButton: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            JourneyTabs(
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: _buildJourneyList(
                  allJourneys,
                  upcomingJourneys,
                  completedJourneys,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to add journey page and refresh on return
          await context.push(AppRoutes.journeyAdd);
          setState(() {
            // This will trigger a rebuild with updated data
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildJourneyList(
    List<Journey> allJourneys,
    List<Journey> upcomingJourneys,
    List<Journey> completedJourneys,
  ) {
    List<Journey> journeysToShow;
    String emptyStateMessage;

    switch (_selectedTabIndex) {
      case 0: // All
        journeysToShow = allJourneys;
        emptyStateMessage = 'No journeys planned yet';
        break;
      case 1: // Upcoming
        journeysToShow = upcomingJourneys;
        emptyStateMessage = 'No upcoming journeys';
        break;
      case 2: // Completed
        journeysToShow = completedJourneys;
        emptyStateMessage = 'No completed journeys';
        break;
      default:
        journeysToShow = allJourneys;
        emptyStateMessage = 'No journeys found';
    }

    return JourneyList(
      journeys: journeysToShow,
      onJourneyTap: (journeyId) async {
        // Navigate to journey details page and refresh on return
        await context.push('${AppRoutes.journeyDetails}?id=$journeyId');
        setState(() {
          // This will trigger a rebuild with updated data
        });
      },
      emptyStateMessage: emptyStateMessage,
    );
  }
}
