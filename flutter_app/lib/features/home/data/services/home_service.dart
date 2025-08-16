import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/navigation/app_routes.dart';
import '../models/destination.dart';
import '../models/quick_access_item.dart';

/// Service to manage home page data and functionality
class HomeService {
  static final HomeService _instance = HomeService._internal();
  factory HomeService() => _instance;
  HomeService._internal();

  // Mock data - in a real app, this would come from a database or API
  final List<Destination> _destinations = [
    const Destination(
      id: '1',
      title: 'The Alps',
      subtitle: 'Explore the majestic peaks and charming villages of the Alps.',
      rating: 4.8,
      tags: ['Mountains', 'Adventure', 'Nature'],
    ),
    const Destination(
      id: '2',
      title: 'Maldives',
      subtitle: 'Relax on the pristine vibrant coral reefs.',
      rating: 4.9,
      tags: ['Beach', 'Relaxation', 'Tropical'],
    ),
    const Destination(
      id: '3',
      title: 'Tokyo',
      subtitle: 'Discover the blend of tradition and modernity.',
      rating: 4.7,
      tags: ['City', 'Culture', 'Food'],
    ),
  ];

  final List<QuickAccessItem> _quickAccessItems = [
    const QuickAccessItem(
      id: '1',
      title: 'Hospital',
      icon: Icons.local_hospital,
      color: AppColors.emergency,
      route: AppRoutes.emergency,
    ),
    const QuickAccessItem(
      id: '2',
      title: 'Medical',
      icon: Icons.medical_services,
      color: AppColors.primary,
      route: AppRoutes.emergency,
    ),
    const QuickAccessItem(
      id: '3',
      title: 'Emergency Contact',
      icon: Icons.contact_emergency,
      color: Colors.orange,
      route: AppRoutes.emergency,
    ),
  ];

  /// Get recommended destinations
  List<Destination> getRecommendedDestinations() {
    return List.unmodifiable(_destinations);
  }

  /// Get emergency reporting items
  List<QuickAccessItem> getEmergencyReportingItems() {
    return List.unmodifiable(_quickAccessItems);
  }

  /// Search destinations
  List<Destination> searchDestinations(String query) {
    if (query.isEmpty) return getRecommendedDestinations();

    final lowercaseQuery = query.toLowerCase();
    return _destinations.where((destination) {
      return destination.title.toLowerCase().contains(lowercaseQuery) ||
          destination.subtitle.toLowerCase().contains(lowercaseQuery) ||
          destination.tags
              .any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Toggle destination favorite status
  void toggleDestinationFavorite(String destinationId) {
    final index = _destinations.indexWhere((dest) => dest.id == destinationId);
    if (index != -1) {
      _destinations[index] = _destinations[index].copyWith(
        isFavorite: !_destinations[index].isFavorite,
      );
    }
  }

  /// Get app title
  String getAppTitle() {
    return 'VistaGuide';
  }

  /// Handle search action
  void handleSearch(String query) {
    // In a real implementation, this would handle search functionality
    // For now, this is a placeholder for search functionality
  }

  /// Handle settings navigation
  void navigateToSettings() {
    // In a real implementation, this would navigate to settings
    // For now, this is a placeholder for settings navigation
  }
}
