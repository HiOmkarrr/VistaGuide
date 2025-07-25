import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/event.dart';

/// Service to manage events data and functionality
class EventsService {
  static final EventsService _instance = EventsService._internal();
  factory EventsService() => _instance;
  EventsService._internal();

  // Mock data - in a real app, this would come from a database or API
  final List<Event> _events = [
    const Event(
      id: '1',
      title: 'Summer Music Festival',
      date: 'July 15, 2024 • 7:00 PM',
      description:
          'Join us for an amazing evening of live music featuring local and international artists.',
      category: 'Festivals',
      color: AppColors.festivalColor,
      icon: Icons.music_note,
      location: 'Central Park',
    ),
    const Event(
      id: '2',
      title: 'Art Exhibition',
      date: 'July 20, 2024 • 6:00 PM',
      description:
          'Discover contemporary art from emerging artists in our gallery space.',
      category: 'Exhibitions',
      color: AppColors.exhibitionColor,
      icon: Icons.palette,
      location: 'Modern Art Gallery',
    ),
    const Event(
      id: '3',
      title: 'Local Food Festival',
      date: 'July 25, 2024 • 5:00 PM',
      description:
          'Taste the best local cuisine from various food vendors and restaurants.',
      category: 'Food',
      color: AppColors.foodColor,
      icon: Icons.restaurant,
      location: 'Downtown Square',
    ),
    const Event(
      id: '4',
      title: 'Outdoor Cinema',
      date: 'August 5, 2024 • 8:00 PM',
      description:
          'Watch classic movies under the stars in our outdoor cinema setup.',
      category: 'Concerts',
      color: AppColors.outdoorColor,
      icon: Icons.movie,
      location: 'Riverside Park',
    ),
  ];

  /// Get all events
  List<Event> getAllEvents() {
    return List.unmodifiable(_events);
  }

  /// Get events filtered by category
  List<Event> getEventsByCategory(String category) {
    if (category == 'All') {
      return getAllEvents();
    }
    return _events.where((event) => event.category == category).toList();
  }

  /// Get available filter categories
  List<String> getFilterCategories() {
    final categories = <String>{'All'};
    for (final event in _events) {
      categories.add(event.category);
    }
    return categories.toList();
  }

  /// Search events by title or description
  List<Event> searchEvents(String query) {
    if (query.isEmpty) return getAllEvents();

    final lowercaseQuery = query.toLowerCase();
    return _events.where((event) {
      return event.title.toLowerCase().contains(lowercaseQuery) ||
          event.description.toLowerCase().contains(lowercaseQuery) ||
          event.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Toggle favorite status of an event
  void toggleEventFavorite(String eventId) {
    final index = _events.indexWhere((event) => event.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(
        isFavorite: !_events[index].isFavorite,
      );
    }
  }

  /// Get favorite events
  List<Event> getFavoriteEvents() {
    return _events.where((event) => event.isFavorite).toList();
  }

  /// Navigate to event details
  void navigateToEventDetails(String eventId) {
    // In a real implementation, this would navigate to event details page
    // For now, this is a placeholder for navigation functionality
  }
}
