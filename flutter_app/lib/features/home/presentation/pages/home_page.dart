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
    final destinations = homeService.getRecommendedDestinations();
    final quickAccessItems = homeService.getQuickAccessItems();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Greeting Section
              const GreetingWidget(),

              // Location and Weather Section
              const LocationWeatherWidget(),

              // Search Bar
              _buildSearchBar(),

              // Recommended Destinations Section
              RecommendedDestinations(
                destinations: destinations,
                onDestinationTap: (destinationId) {
                  // Handle destination tap - placeholder for navigation
                },
              ),

              // Quick Access Grid
              QuickAccessGrid(
                items: quickAccessItems,
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: const CustomSearchBar(
        hintText: 'Where to?',
      ),
    );
  }
}
