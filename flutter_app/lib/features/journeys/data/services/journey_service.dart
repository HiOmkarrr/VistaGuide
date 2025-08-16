import '../models/journey.dart';

/// Service to manage journey data and functionality
class JourneyService {
  static final JourneyService _instance = JourneyService._internal();
  factory JourneyService() => _instance;
  JourneyService._internal();

  // Mock data - in a real app, this would come from a database or API
  final List<Journey> _journeys = [
    Journey(
      id: '1',
      title: 'Weekend Alps Adventure',
      description: 'A weekend trip to explore the beautiful Alps',
      startDate: DateTime(2024, 8, 15),
      endDate: DateTime(2024, 8, 17),
      isCompleted: true,
      destinations: ['Interlaken', 'Jungfraujoch', 'Grindelwald'],
    ),
    Journey(
      id: '2',
      title: 'Tokyo Cultural Tour',
      description: 'Exploring traditional and modern Tokyo',
      startDate: DateTime(2024, 9, 1),
      endDate: DateTime(2024, 9, 7),
      isCompleted: false,
      destinations: ['Asakusa', 'Shibuya', 'Harajuku', 'Tokyo Skytree'],
    ),
    Journey(
      id: '3',
      title: 'Maldives Relaxation',
      description: 'A peaceful getaway to tropical paradise',
      startDate: DateTime(2024, 10, 10),
      endDate: DateTime(2024, 10, 17),
      isCompleted: false,
      destinations: ['Male', 'Conrad Maldives', 'Banana Reef'],
    ),
  ];

  /// Get all journeys
  List<Journey> getAllJourneys() {
    return List.unmodifiable(_journeys);
  }

  /// Get upcoming journeys
  List<Journey> getUpcomingJourneys() {
    final now = DateTime.now();
    return _journeys
        .where(
            (journey) => !journey.isCompleted && journey.startDate.isAfter(now))
        .toList();
  }

  /// Get completed journeys
  List<Journey> getCompletedJourneys() {
    return _journeys.where((journey) => journey.isCompleted).toList();
  }

  /// Add a new journey
  void addJourney(Journey journey) {
    _journeys.add(journey);
  }

  /// Update an existing journey
  void updateJourney(Journey updatedJourney) {
    final index =
        _journeys.indexWhere((journey) => journey.id == updatedJourney.id);
    if (index != -1) {
      _journeys[index] = updatedJourney;
    }
  }

  /// Delete a journey
  void deleteJourney(String journeyId) {
    _journeys.removeWhere((journey) => journey.id == journeyId);
  }

  /// Get journey by ID
  Journey? getJourneyById(String journeyId) {
    try {
      return _journeys.firstWhere((journey) => journey.id == journeyId);
    } catch (e) {
      return null;
    }
  }

  /// Mark journey as completed
  void markJourneyAsCompleted(String journeyId) {
    final index = _journeys.indexWhere((journey) => journey.id == journeyId);
    if (index != -1) {
      _journeys[index] = _journeys[index].copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Handle journey tap
  void handleJourneyTap(String journeyId) {
    // Navigate to journey details
    print('Journey tapped: $journeyId');
  }

  /// Handle add new journey
  void handleAddNewJourney() {
    // Navigate to add journey page or show dialog
    print('Add new journey');
  }
}
