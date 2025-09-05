import '../models/journey.dart';
import '../models/journey_details_data.dart';
import '../repositories/journey_repository.dart';

/// Service to manage journey data and functionality with persistent storage
class JourneyService {
  static final JourneyService _instance = JourneyService._internal();
  factory JourneyService() => _instance;
  JourneyService._internal();

  // Persistent repository for journey storage
  final JourneyRepository _repository = JourneyRepository();
  
  // Cache for fast access
  List<Journey>? _journeyCache;
  bool _isInitialized = false;

  /// Initialize the service and load data
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🚀 Initializing JourneyService...');
      await _loadJourneys();
      _isInitialized = true;
      print('✅ JourneyService initialized with ${_journeyCache?.length ?? 0} journeys');
    } catch (e) {
      print('❌ Failed to initialize JourneyService: $e');
      _journeyCache = [];
    }
  }

  /// Load journeys from repository
  Future<void> _loadJourneys() async {
    _journeyCache = await _repository.getAllJourneys();
  }

  /// Get all journeys
  Future<List<Journey>> getAllJourneys() async {
    await initialize();
    return List.unmodifiable(_journeyCache ?? []);
  }

  /// Get upcoming journeys
  Future<List<Journey>> getUpcomingJourneys() async {
    await initialize();
    final now = DateTime.now();
    return (_journeyCache ?? [])
        .where(
            (journey) => !journey.isCompleted && journey.startDate.isAfter(now))
        .toList();
  }

  /// Get completed journeys
  Future<List<Journey>> getCompletedJourneys() async {
    await initialize();
    return (_journeyCache ?? [])
        .where((journey) => journey.isCompleted)
        .toList();
  }

  /// Get current journeys (ongoing)
  Future<List<Journey>> getCurrentJourneys() async {
    await initialize();
    return (_journeyCache ?? [])
        .where((journey) => journey.isCurrent)
        .toList();
  }

  /// Add a new journey
  Future<void> addJourney(Journey journey) async {
    try {
      await _repository.insertJourney(journey);
      await _refreshCache();
      print('✅ Journey added: ${journey.title}');
    } catch (e) {
      print('❌ Failed to add journey: $e');
      rethrow;
    }
  }

  /// Update an existing journey
  Future<void> updateJourney(Journey updatedJourney) async {
    try {
      await _repository.updateJourney(updatedJourney);
      await _refreshCache();
      print('✅ Journey updated: ${updatedJourney.title}');
    } catch (e) {
      print('❌ Failed to update journey: $e');
      rethrow;
    }
  }

  /// Delete a journey
  Future<void> deleteJourney(String journeyId) async {
    try {
      await _repository.deleteJourney(journeyId);
      await _refreshCache();
      print('✅ Journey deleted: $journeyId');
    } catch (e) {
      print('❌ Failed to delete journey: $e');
      rethrow;
    }
  }

  /// Get journey by ID
  Future<Journey?> getJourneyById(String journeyId) async {
    try {
      // Try cache first for performance
      if (_journeyCache != null) {
        try {
          return _journeyCache!.firstWhere(
            (journey) => journey.id == journeyId,
          );
        } catch (e) {
          // Journey not found in cache, continue to repository
        }
      }
      
      // Fallback to repository
      return await _repository.getJourneyById(journeyId);
    } catch (e) {
      print('⚠️ Journey not found: $journeyId');
      return null;
    }
  }

  /// Mark journey as completed
  Future<void> markJourneyAsCompleted(String journeyId) async {
    try {
      final journey = await getJourneyById(journeyId);
      if (journey != null) {
        final updatedJourney = journey.copyWith(
          isCompleted: true,
          updatedAt: DateTime.now(),
        );
        await updateJourney(updatedJourney);
      }
    } catch (e) {
      print('❌ Failed to mark journey as completed: $e');
      rethrow;
    }
  }

  /// Update journey details (AI-generated content)
  Future<void> updateJourneyDetails(
    String journeyId, 
    JourneyDetailsData journeyDetails
  ) async {
    try {
      // Save details to repository
      await _repository.saveJourneyDetails(journeyId, journeyDetails);
      
      // Update the journey with details in cache
      final journey = await getJourneyById(journeyId);
      if (journey != null) {
        final updatedJourney = journey.copyWith(
          journeyDetails: journeyDetails,
          updatedAt: DateTime.now(),
        );
        await updateJourney(updatedJourney);
      }
    } catch (e) {
      print('❌ Failed to update journey details: $e');
      rethrow;
    }
  }

  /// Refresh the journey cache
  Future<void> _refreshCache() async {
    await _loadJourneys();
  }

  /// Get filtered journeys
  Future<List<Journey>> getJourneysFiltered({
    bool? isCompleted,
    DateTime? startDateAfter,
    DateTime? startDateBefore,
    int limit = 100,
  }) async {
    try {
      return await _repository.getJourneysFiltered(
        isCompleted: isCompleted,
        startDateAfter: startDateAfter,
        startDateBefore: startDateBefore,
        limit: limit,
      );
    } catch (e) {
      print('❌ Failed to get filtered journeys: $e');
      return [];
    }
  }

  /// Get journey details by ID
  Future<JourneyDetailsData?> getJourneyDetails(String journeyId) async {
    try {
      return await _repository.getJourneyDetails(journeyId);
    } catch (e) {
      print('❌ Failed to get journey details: $e');
      return null;
    }
  }

  /// Clear all journeys (for testing/debugging)
  Future<void> clearAllJourneys() async {
    try {
      await _repository.clearAllJourneys();
      await _refreshCache();
      print('✅ All journeys cleared');
    } catch (e) {
      print('❌ Failed to clear journeys: $e');
      rethrow;
    }
  }

  /// Get journey statistics
  Future<Map<String, int>> getJourneyStatistics() async {
    try {
      final allJourneys = await getAllJourneys();
      final upcoming = await getUpcomingJourneys();
      final completed = await getCompletedJourneys();
      final current = await getCurrentJourneys();
      
      return {
        'total': allJourneys.length,
        'upcoming': upcoming.length,
        'completed': completed.length,
        'current': current.length,
      };
    } catch (e) {
      print('❌ Failed to get journey statistics: $e');
      return {
        'total': 0,
        'upcoming': 0,
        'completed': 0,
        'current': 0,
      };
    }
  }

  /// Handle journey tap (for navigation)
  Future<void> handleJourneyTap(String journeyId) async {
    // This can be used by UI components for navigation logic
    print('💆 Journey tapped: $journeyId');
    // UI components should handle navigation directly
  }

  /// Handle add new journey (for navigation)
  Future<void> handleAddNewJourney() async {
    // This can be used by UI components for navigation logic
    print('➕ Add new journey requested');
    // UI components should handle navigation directly
  }

  /// Force refresh from repository
  Future<void> refresh() async {
    await _refreshCache();
    print('🔄 Journey cache refreshed');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get cache size
  int get cacheSize => _journeyCache?.length ?? 0;

  /// Close the service and repository
  Future<void> dispose() async {
    await _repository.close();
    _journeyCache = null;
    _isInitialized = false;
    print('📋 JourneyService disposed');
  }
}
