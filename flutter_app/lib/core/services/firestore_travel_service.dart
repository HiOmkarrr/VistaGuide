import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/home/data/models/destination.dart';
import 'magic_lane_service.dart';
import 'simple_offline_storage_service.dart';

/// User preferences for personalized recommendations
class UserPreferences {
  final List<String> preferredTypes;
  final List<String> preferredTags;
  final double maxDistance;
  final double minRating;
  final String language;

  const UserPreferences({
    required this.preferredTypes,
    required this.preferredTags,
    required this.maxDistance,
    required this.minRating,
    required this.language,
  });

  factory UserPreferences.defaultPreferences() {
    return const UserPreferences(
      preferredTypes: ['monument', 'museum', 'park', 'attraction'],
      preferredTags: [],
      maxDistance: 50.0,
      minRating: 3.0,
      language: 'en',
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      preferredTypes:
          (json['preferredTypes'] as List<dynamic>?)?.cast<String>() ??
              ['monument', 'museum', 'park', 'attraction'],
      preferredTags:
          (json['preferredTags'] as List<dynamic>?)?.cast<String>() ?? [],
      maxDistance: (json['maxDistance'] as num?)?.toDouble() ?? 50.0,
      minRating: (json['minRating'] as num?)?.toDouble() ?? 3.0,
      language: json['language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredTypes': preferredTypes,
      'preferredTags': preferredTags,
      'maxDistance': maxDistance,
      'minRating': minRating,
      'language': language,
    };
  }
}

/// Firestore service for travel-related data
/// Handles destinations, favorites, travel history, and recommendations
class FirestoreTravelService {
  static final FirestoreTravelService _instance =
      FirestoreTravelService._internal();
  factory FirestoreTravelService() => _instance;
  FirestoreTravelService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection references
  CollectionReference get _destinationsCollection =>
      _firestore.collection('destinations');
  CollectionReference get _userDataCollection =>
      _firestore.collection('userData');

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user-specific document reference
  DocumentReference? get _currentUserDoc =>
      currentUserId != null ? _userDataCollection.doc(currentUserId!) : null;

  // ==================== DESTINATIONS ====================

  /// Get all destinations
  Future<List<Destination>> getDestinations({int limit = 20}) async {
    try {
      final querySnapshot = await _destinationsCollection
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Destination.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get destinations: $e');
    }
  }

  /// Get destination by ID
  Future<Destination?> getDestination(String destinationId) async {
    try {
      final doc = await _destinationsCollection.doc(destinationId).get();

      if (doc.exists && doc.data() != null) {
        return Destination.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get destination: $e');
    }
  }

  /// Search destinations
  Future<List<Destination>> searchDestinations(String query,
      {int limit = 20}) async {
    try {
      final querySnapshot = await _destinationsCollection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Destination.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to search destinations: $e');
    }
  }

  /// Search destinations by location name using both Firestore and Magic Lane
  Future<List<Destination>> searchDestinationsByLocation(String locationQuery,
      {int limit = 20}) async {
    try {
      print('🔍 Searching destinations for location: "$locationQuery"');

      final destinations = <Destination>[];

      // First, search in Firestore destinations
      final firestoreResults =
          await searchDestinations(locationQuery, limit: limit);
      destinations.addAll(firestoreResults);

      // If we need more results, try Magic Lane API
      if (destinations.length < limit) {
        try {
          final magicLaneResults = await MagicLaneService.searchPlacesByText(
            query: locationQuery,
            maxResults: limit - destinations.length,
          );

          // Store new destinations found via Magic Lane
          if (magicLaneResults.isNotEmpty) {
            await _storeMagicLaneDestinations(magicLaneResults);
            destinations.addAll(magicLaneResults);
          }
        } catch (e) {
          print('⚠️ Magic Lane search failed: $e');
        }
      }

      // Remove duplicates and return
      final uniqueDestinations = _deduplicateDestinations(destinations);
      return uniqueDestinations.take(limit).toList();
    } catch (e) {
      print('❌ Error searching destinations by location: $e');
      throw Exception('Failed to search destinations by location: $e');
    }
  }

  /// Get destinations by tags
  Future<List<Destination>> getDestinationsByTags(List<String> tags,
      {int limit = 20}) async {
    try {
      final querySnapshot = await _destinationsCollection
          .where('tags', arrayContainsAny: tags)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Destination.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get destinations by tags: $e');
    }
  }

  // ==================== FAVORITES ====================

  /// Get user's favorite destinations
  Future<List<String>> getUserFavorites() async {
    if (currentUserId == null) return [];

    try {
      final doc = await _currentUserDoc!.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['favoriteDestinations'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get user favorites: $e');
    }
  }

  /// Add destination to favorites
  Future<void> addToFavorites(String destinationId) async {
    if (currentUserId == null) return;

    try {
      await _currentUserDoc!.set({
        'favoriteDestinations': FieldValue.arrayUnion([destinationId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Remove destination from favorites
  Future<void> removeFromFavorites(String destinationId) async {
    if (currentUserId == null) return;

    try {
      await _currentUserDoc!.update({
        'favoriteDestinations': FieldValue.arrayRemove([destinationId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Check if destination is in favorites
  Future<bool> isFavorite(String destinationId) async {
    final favorites = await getUserFavorites();
    return favorites.contains(destinationId);
  }

  /// Get favorite destinations with full details
  Future<List<Destination>> getFavoriteDestinations() async {
    try {
      final favoriteIds = await getUserFavorites();
      if (favoriteIds.isEmpty) return [];

      final destinations = <Destination>[];

      // Firestore 'in' queries are limited to 10 items
      for (int i = 0; i < favoriteIds.length; i += 10) {
        final chunk = favoriteIds.skip(i).take(10).toList();
        final querySnapshot = await _destinationsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in querySnapshot.docs) {
          if (doc.data() != null) {
            destinations.add(Destination.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }));
          }
        }
      }

      return destinations;
    } catch (e) {
      throw Exception('Failed to get favorite destinations: $e');
    }
  }

  // ==================== TRAVEL HISTORY ====================

  /// Add destination to travel history
  Future<void> addToTravelHistory(String destinationId, {String? notes}) async {
    if (currentUserId == null) return;

    try {
      final historyItem = {
        'destinationId': destinationId,
        'visitedAt': FieldValue.serverTimestamp(),
        'notes': notes,
      };

      await _currentUserDoc!.set({
        'travelHistory': FieldValue.arrayUnion([historyItem]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add to travel history: $e');
    }
  }

  /// Get user's travel history
  Future<List<Map<String, dynamic>>> getTravelHistory() async {
    if (currentUserId == null) return [];

    try {
      final doc = await _currentUserDoc!.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['travelHistory'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get travel history: $e');
    }
  }

  // ==================== RECOMMENDATIONS ====================

  /// Get personalized destination recommendations based on user location and preferences
  Future<List<Destination>> getRecommendations({
    required double userLat,
    required double userLng,
    int limit = 10,
    double radiusKm = 50.0,
    List<String>? preferredTypes,
    bool useGooglePlaces = true,
  }) async {
    try {
      print(
          '🎯 Getting personalized recommendations for user at ($userLat, $userLng)');

      // Get user preferences first
      final userPreferences = await _getUserPreferences();
      final visitedPlaces = await _getVisitedPlaces();

      List<Destination> destinations = [];

      // Start with Firestore data (which has rich historical info) then supplement with Magic Lane
      final firestoreDestinations = await _getFirestoreRecommendations(
        userLat,
        userLng,
        radiusKm,
        preferredTypes,
        userPreferences,
      );
      destinations.addAll(firestoreDestinations);

      // If we need more results, try Magic Lane API for additional places
      if (destinations.length < limit && useGooglePlaces) {
        try {
          final magicLaneDestinations =
              await MagicLaneService.searchNearbyPlaces(
            latitude: userLat,
            longitude: userLng,
            radiusKm: radiusKm,
            maxResults: limit - destinations.length, // Only get what we need
            categories: preferredTypes ?? ['tourism', 'culture'],
          );

          // Store new destinations in Firestore and offline storage
          await _storeMagicLaneDestinations(magicLaneDestinations);

          // Store offline with simplified storage
          final offlineStorage = SimpleOfflineStorageService();
          await offlineStorage.storeDestinations(
            magicLaneDestinations,
            downloadImages:
                false, // Simplified - no image downloading for faster startup
            source: 'magic_lane',
          );

          destinations.addAll(magicLaneDestinations);
        } catch (e) {
          print('⚠️ Magic Lane API failed, using Firestore data only: $e');
        }
      }

      // If API didn't provide enough results, try offline storage for more
      if (destinations.length < limit) {
        try {
          final offlineStorage = SimpleOfflineStorageService();
          final offlineDestinations =
              await offlineStorage.getOfflineDestinations(
            nearLatitude: userLat,
            nearLongitude: userLng,
            radiusKm: radiusKm,
            types: preferredTypes,
            limit: limit - destinations.length,
          );

          if (offlineDestinations.isNotEmpty) {
            print(
                '📱 Found ${offlineDestinations.length} destinations in offline storage');
            destinations.addAll(offlineDestinations);
          }
        } catch (e) {
          print('⚠️ Offline storage access failed: $e');
        }
      }

      // Remove duplicates and apply filtering
      destinations = _deduplicateDestinations(destinations);
      destinations = destinations
          .where((d) => !_isRecentlyVisited(d.id, visitedPlaces))
          .toList();

      // Apply personalized ranking
      destinations.sort((a, b) =>
          _calculateRecommendationScore(b, userPreferences, visitedPlaces)
              .compareTo(_calculateRecommendationScore(
                  a, userPreferences, visitedPlaces)));

      // Update user interaction for improved future recommendations
      await _updateUserInteraction('recommendations_viewed', {
        'location': {'lat': userLat, 'lng': userLng},
        'count': destinations.take(limit).length,
        'source': useGooglePlaces ? 'mixed' : 'firestore',
      });

      return destinations.take(limit).toList();
    } catch (e) {
      print('❌ Error getting recommendations: $e');
      // Fallback to popular destinations
      return await _getFallbackRecommendations(limit);
    }
  }

  /// Get landmark-specific information when AI detects a landmark
  Future<Destination?> getLandmarkInfo(
    String landmarkName, {
    double? userLat,
    double? userLng,
  }) async {
    try {
      print('🔍 Looking up landmark: $landmarkName');

      // First try exact match by name
      var querySnapshot = await _destinationsCollection
          .where('title', isEqualTo: landmarkName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Try fuzzy search
        querySnapshot = await _destinationsCollection
            .where('title', isGreaterThanOrEqualTo: landmarkName)
            .where('title', isLessThan: '${landmarkName}z')
            .limit(5)
            .get();

        if (querySnapshot.docs.isEmpty) {
          // Try searching in tags or keywords
          querySnapshot = await _destinationsCollection
              .where('tags', arrayContains: landmarkName.toLowerCase())
              .limit(5)
              .get();
        }
      }

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final destination = Destination.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });

        // Calculate distance if user location provided
        double? distance;
        if (userLat != null &&
            userLng != null &&
            destination.coordinates != null) {
          distance = _calculateDistance(
            userLat,
            userLng,
            destination.coordinates!.latitude,
            destination.coordinates!.longitude,
          );
        }

        // Log landmark detection for analytics
        await _updateUserInteraction('landmark_detected', {
          'landmarkName': landmarkName,
          'destinationId': destination.id,
        });

        return distance != null
            ? destination.copyWith(distanceKm: distance)
            : destination;
      }

      return null;
    } catch (e) {
      print('❌ Error getting landmark info: $e');
      return null;
    }
  }

  /// Get recommendations for offline mode
  Future<List<Destination>> getOfflineRecommendations({int limit = 10}) async {
    try {
      // Get cached destinations that are marked as offline available
      final querySnapshot = await _destinationsCollection
          .where('isOfflineAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Destination.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      print('❌ Error getting offline recommendations: $e');
      return [];
    }
  }

  /// Cache destinations for offline usage
  Future<void> cacheDestinationsForOffline(
      List<Destination> destinations) async {
    try {
      final batch = _firestore.batch();

      for (final destination in destinations) {
        final docRef = _destinationsCollection.doc(destination.id);
        batch.update(docRef, {
          'isOfflineAvailable': true,
          'lastCached': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ Cached ${destinations.length} destinations for offline use');
    } catch (e) {
      print('❌ Error caching destinations: $e');
    }
  }

  /// Get trending destinations based on user interactions
  Future<List<Destination>> getTrendingDestinations({int limit = 10}) async {
    try {
      // This would ideally use aggregated user interaction data
      // For now, return highly rated destinations with recent activity
      final querySnapshot = await _destinationsCollection
          .where('rating', isGreaterThan: 4.0)
          .orderBy('rating', descending: true)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Destination.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      print('❌ Error getting trending destinations: $e');
      throw Exception('Failed to get trending destinations: $e');
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double radiusOfEarth = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radiusOfEarth * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get user preferences for personalization
  Future<UserPreferences> _getUserPreferences() async {
    if (currentUserId == null) return UserPreferences.defaultPreferences();

    try {
      final doc = await _currentUserDoc!.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return UserPreferences.fromJson(data['preferences'] ?? {});
      }

      return UserPreferences.defaultPreferences();
    } catch (e) {
      return UserPreferences.defaultPreferences();
    }
  }

  /// Get list of places user has visited
  Future<List<String>> _getVisitedPlaces() async {
    final history = await getTravelHistory();
    return history.map((item) => item['destinationId'] as String).toList();
  }

  /// Check if destination was visited recently (within last 30 days)
  bool _isRecentlyVisited(String destinationId, List<String> visitedPlaces) {
    // This is a simplified check - in a real implementation,
    // you'd check the timestamp of the visit
    return visitedPlaces.contains(destinationId);
  }

  /// Calculate recommendation score for personalization
  double _calculateRecommendationScore(Destination destination,
      UserPreferences preferences, List<String> visitedPlaces) {
    double score = destination.rating ?? 0.0;

    // Boost score for preferred types
    if (preferences.preferredTypes.contains(destination.type)) {
      score += 1.0;
    }

    // Boost score for preferred tags
    for (final tag in destination.tags) {
      if (preferences.preferredTags.contains(tag)) {
        score += 0.5;
      }
    }

    // Reduce score for recently visited places
    if (_isRecentlyVisited(destination.id, visitedPlaces)) {
      score -= 2.0;
    }

    // Boost score for closer destinations
    if (destination.distanceKm != null) {
      score += (50 - destination.distanceKm!) / 10; // Closer = higher score
    }

    return score;
  }

  /// Get fallback recommendations when main algorithm fails
  Future<List<Destination>> _getFallbackRecommendations(int limit) async {
    try {
      return await getDestinations(limit: limit);
    } catch (e) {
      return [];
    }
  }

  /// Update user interaction for analytics and personalization
  Future<void> _updateUserInteraction(
      String action, Map<String, dynamic> data) async {
    if (currentUserId == null) return;

    try {
      // Create interaction object with current timestamp
      final interaction = {
        'action': action,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _currentUserDoc!.set({
        'interactions': FieldValue.arrayUnion([interaction]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail for analytics - don't break main functionality
      print('⚠️ Failed to update user interaction: $e');
    }
  }

  /// Store Magic Lane destinations in Firestore for future use
  Future<void> _storeMagicLaneDestinations(
      List<Destination> destinations) async {
    try {
      final batch = _firestore.batch();

      for (final destination in destinations) {
        final docRef = _destinationsCollection.doc(destination.id);

        // Check if destination already exists
        final existingDoc = await docRef.get();
        if (!existingDoc.exists) {
          batch.set(docRef, {
            ...destination.toJson(),
            'source': 'magic_lane',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      print(
          '✅ Stored ${destinations.length} Magic Lane destinations in Firestore');
    } catch (e) {
      print('⚠️ Failed to store Magic Lane destinations: $e');
    }
  }

  /// Get Firestore-based recommendations
  Future<List<Destination>> _getFirestoreRecommendations(
    double userLat,
    double userLng,
    double radiusKm,
    List<String>? preferredTypes,
    UserPreferences userPreferences,
  ) async {
    try {
      Query query = _destinationsCollection;

      // Filter by type preferences if specified
      if (preferredTypes != null && preferredTypes.isNotEmpty) {
        query = query.where('type', whereIn: preferredTypes);
      } else if (userPreferences.preferredTypes.isNotEmpty) {
        query = query.where('type', whereIn: userPreferences.preferredTypes);
      }

      // Get destinations and calculate distances
      final querySnapshot =
          await query.limit(50).get(); // Get more to filter by distance

      final destinations = <Destination>[];

      for (final doc in querySnapshot.docs) {
        if (doc.data() != null) {
          final destination = Destination.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });

          // Calculate distance if coordinates are available
          if (destination.coordinates != null) {
            final distance = _calculateDistance(
              userLat,
              userLng,
              destination.coordinates!.latitude,
              destination.coordinates!.longitude,
            );

            // Only include if within radius
            if (distance <= radiusKm) {
              destinations.add(destination.copyWith(
                distanceKm: distance,
              ));
            }
          }
        }
      }

      return destinations;
    } catch (e) {
      print('❌ Error getting Firestore recommendations: $e');
      return [];
    }
  }

  /// Remove duplicate destinations based on ID and proximity
  List<Destination> _deduplicateDestinations(List<Destination> destinations) {
    final Map<String, Destination> uniqueDestinations = {};
    final List<Destination> result = [];

    for (final destination in destinations) {
      bool isDuplicate = false;

      // Check for exact ID match
      if (uniqueDestinations.containsKey(destination.id)) {
        isDuplicate = true;
      } else {
        // Check for proximity duplicates (within 100 meters)
        for (final existing in result) {
          if (existing.coordinates != null && destination.coordinates != null) {
            final distance = _calculateDistance(
                  existing.coordinates!.latitude,
                  existing.coordinates!.longitude,
                  destination.coordinates!.latitude,
                  destination.coordinates!.longitude,
                ) *
                1000; // Convert to meters

            if (distance < 100) {
              // Within 100 meters
              isDuplicate = true;
              break;
            }
          }
        }
      }

      if (!isDuplicate) {
        uniqueDestinations[destination.id] = destination;
        result.add(destination);
      }
    }

    return result;
  }

  // ==================== ADMIN FUNCTIONS ====================

  /// Add a new destination (admin function)
  Future<String> addDestination(Destination destination) async {
    try {
      final docRef = await _destinationsCollection.add(destination.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add destination: $e');
    }
  }

  /// Update destination (admin function)
  Future<void> updateDestination(
      String destinationId, Map<String, dynamic> updates) async {
    try {
      await _destinationsCollection.doc(destinationId).update(updates);
    } catch (e) {
      throw Exception('Failed to update destination: $e');
    }
  }

  /// Delete destination (admin function)
  Future<void> deleteDestination(String destinationId) async {
    try {
      await _destinationsCollection.doc(destinationId).delete();
    } catch (e) {
      throw Exception('Failed to delete destination: $e');
    }
  }

  // ==================== STREAMS ====================

  /// Stream destinations
  Stream<List<Destination>> streamDestinations({int limit = 20}) {
    return _destinationsCollection
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Destination.fromJson({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }))
            .toList());
  }

  /// Stream user favorites
  Stream<List<String>> streamUserFavorites() {
    if (currentUserId == null) return Stream.value([]);

    return _currentUserDoc!.snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['favoriteDestinations'] ?? []);
      }
      return <String>[];
    });
  }

  // ==================== OFFLINE METHODS ====================

  /// Get enhanced offline recommendations with location filtering
  Future<List<Destination>> getEnhancedOfflineRecommendations({
    required double userLat,
    required double userLng,
    double radiusKm = 50,
    List<String>? preferredTypes,
    int limit = 10,
  }) async {
    try {
      print('📱 Getting offline recommendations...');

      final offlineStorage = SimpleOfflineStorageService();

      // Get offline destinations
      final offlineDestinations = await offlineStorage.getOfflineDestinations(
        nearLatitude: userLat,
        nearLongitude: userLng,
        radiusKm: radiusKm,
        types: preferredTypes,
        limit: limit,
      );

      if (offlineDestinations.isNotEmpty) {
        print(
            '📱 Found ${offlineDestinations.length} fully offline destinations');
        return offlineDestinations;
      }

      // If no offline destinations, get any cached destinations
      final cachedDestinations = await offlineStorage.getOfflineDestinations(
        nearLatitude: userLat,
        nearLongitude: userLng,
        radiusKm: radiusKm,
        types: preferredTypes,
        limit: limit,
      );

      print(
          '📱 Found ${cachedDestinations.length} cached destinations for offline mode');
      return cachedDestinations;
    } catch (e) {
      print('❌ Failed to get offline recommendations: $e');
      return [];
    }
  }

  /// Check offline storage statistics
  Future<Map<String, dynamic>> getOfflineStorageStats() async {
    try {
      final offlineStorage = SimpleOfflineStorageService();
      return await offlineStorage.getCacheStatistics();
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear offline storage
  Future<void> clearOfflineStorage() async {
    try {
      final offlineStorage = SimpleOfflineStorageService();
      await offlineStorage.clearAllCache();
    } catch (e) {
      print('❌ Failed to clear offline storage: $e');
      throw Exception('Failed to clear offline storage: $e');
    }
  }
}
