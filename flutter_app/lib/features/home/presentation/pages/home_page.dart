import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/home_service.dart';
import '../localWidgets/greeting_widget.dart';
import '../localWidgets/location_weather_widget.dart';
import '../localWidgets/recommended_destinations.dart';
import '../localWidgets/quick_access_grid.dart';

/// Home page - central hub with search, recommendations, and quick access
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeService = HomeService();
    final quickAccessItems = homeService.getEmergencyReportingItems();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Greeting Section
              const GreetingWidget(),

              const SizedBox(height: 8),
              // Location and Weather Section (Original working widget)
              const LocationWeatherWidget(),

              const SizedBox(height: 8),
              // Search Bar
              _buildSearchBar(),

              // Recommended Destinations Section (with loading indicators)
              RecommendedDestinations(
                onDestinationTap: (destinationId) {
                  // Handle destination tap - placeholder for navigation
                  print('Destination tapped: $destinationId');
                },
                sectionTitle: 'Personalized for You',
                limit: 8,
                enableLocationBasedRecommendations: true,
              ),

              // Emergency Reporting Grid
              QuickAccessGrid(
                items: quickAccessItems,
                sectionTitle: 'Emergency Reporting',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildSearchBar() {
    return const CustomSearchBar(
      hintText: 'Where to?',
    );
  }
}
