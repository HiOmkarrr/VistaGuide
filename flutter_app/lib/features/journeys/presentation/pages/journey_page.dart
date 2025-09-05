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
  
  List<Journey> _allJourneys = [];
  List<Journey> _upcomingJourneys = [];
  List<Journey> _completedJourneys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJourneys();
  }

  Future<void> _loadJourneys() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final allJourneys = await _journeyService.getAllJourneys();
      final upcomingJourneys = await _journeyService.getUpcomingJourneys();
      final completedJourneys = await _journeyService.getCompletedJourneys();
      
      setState(() {
        _allJourneys = allJourneys;
        _upcomingJourneys = upcomingJourneys;
        _completedJourneys = completedJourneys;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading journeys: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Journeys',
        showBackButton: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Column(
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
                        _allJourneys,
                        _upcomingJourneys,
                        _completedJourneys,
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
          // Refresh the journey data
          await _loadJourneys();
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
        // Refresh the journey data in case it was modified
        await _loadJourneys();
      },
      emptyStateMessage: emptyStateMessage,
    );
  }
}
