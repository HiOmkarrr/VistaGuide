import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/home_service.dart';
import '../localWidgets/app_header.dart';
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
        child: Column(
          children: [
            AppHeader(
              title: homeService.getAppTitle(),
              onSettingsTap: () => homeService.navigateToSettings(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    RecommendedDestinations(
                      destinations: destinations,
                      onDestinationTap: (destinationId) {
                        // Handle destination tap
                        print('Tapped destination: $destinationId');
                      },
                    ),
                    QuickAccessGrid(
                      items: quickAccessItems,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
