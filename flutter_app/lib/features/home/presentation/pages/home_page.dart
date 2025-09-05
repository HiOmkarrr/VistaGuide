import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/location_autocomplete_search_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/location_weather_service.dart';
import '../../data/services/home_service.dart';
import '../localWidgets/greeting_widget.dart';
import '../localWidgets/location_weather_widget.dart';
import '../localWidgets/recommended_destinations.dart';
import '../localWidgets/quick_access_grid.dart';
import 'destination_detail_page.dart';

/// Home page - central hub with search, recommendations, and quick access
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? _userLatitude;
  double? _userLongitude;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final locationService = LocationWeatherService();
      final position = await locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        });
        print('📍 User location: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('❌ Error getting user location: $e');
    }
  }

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
                onDestinationTap: (destinationId, destination) {
                  // Navigate to destination detail page with pre-loaded data
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DestinationDetailPage(
                        destinationId: destinationId,
                        initialDestination: destination,
                      ),
                    ),
                  );
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
    return LocationAutocompleteSearchBar(
      hintText: 'Where to?',
      userLatitude: _userLatitude,
      userLongitude: _userLongitude,
      onLocationSelected: (location) {
        print('📍 Selected location: ${location.title} - ${location.subtitle}');
        // TODO: Navigate to search results or destination details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: ${location.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onTextChanged: (text) {
        // Handle text changes if needed
        print('🔍 Search text changed: $text');
      },
    );
  }
}
