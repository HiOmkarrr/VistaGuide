import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../features/home/data/models/destination.dart';
import 'magic_lane_service.dart';
import 'simple_offline_storage_service.dart';
import 'gemini_enrichment_service.dart';
import 'connectivity_service.dart';
import 'cache_manager_service.dart';
import 'offline_cache_service.dart';

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
  final GeminiEnrichmentService _geminiService = GeminiEnrichmentService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final CacheManagerService _cacheManager = CacheManagerService();

  /// Initialize the service and its dependencies
  Future<void> initialize() async {
    await _cacheManager.initialize();
  }

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
  /// STRICT OFFLINE-FIRST: Uses cached data when available, only fetches online when cache expired AND internet available
  Future<List<Destination>> getRecommendations({
    required double userLat,
    required double userLng,
    int limit = 10,
    double radiusKm = 50.0,
    List<String>? preferredTypes,
    bool useGooglePlaces = true,
    bool enrichWithAI =
        false, // Enable AI enrichment (respects caching and connectivity)
  }) async {
    if (kDebugMode) {
      print('🎯 STARTING RECOMMENDATION FETCH for ($userLat, $userLng)');
      print(
          '📊 Parameters: limit=$limit, radius=${radiusKm}km, useAPI=$useGooglePlaces, enrichAI=$enrichWithAI');
    }

    try {
      // STEP 1: Check cache status and connectivity
      final shouldRefresh = _cacheManager.shouldRefreshRecommendations();
      final hasInternet = await _connectivityService.hasInternetConnection();

      if (kDebugMode) {
        print('� CACHE ANALYSIS:');
        print('   - Should refresh: $shouldRefresh');
        print('   - Has internet: $hasInternet');
        print(
            '   - Cache age: ${_cacheManager.getRecommendationsCacheAgeInMinutes()}min');
      }

      // STEP 2: ALWAYS try offline storage FIRST
  final offlineStorage = SimpleOfflineStorageService();
  await offlineStorage.initialize();
      List<Destination> offlineDestinations = [];

      // 2A. Ultra-fast path: SharedPreferences cached destinations
      try {
        final spCached = await OfflineCacheService.getCachedDestinations();
        if (spCached.isNotEmpty) {
          if (kDebugMode) {
            print('� SP CACHE: Found ${spCached.length} destinations');
          }
          offlineDestinations.addAll(spCached);
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to read SP cache: $e');
        }
      }

      try {
        if (kDebugMode) {
          print('�📱 ATTEMPTING OFFLINE LOAD...');
        }

        offlineDestinations = await offlineStorage.getOfflineDestinations(
          nearLatitude: userLat,
          nearLongitude: userLng,
          radiusKm: radiusKm,
          types: preferredTypes,
          limit: limit,
        );

        if (kDebugMode) {
          print('📱 OFFLINE RESULT (SQLite): Found ${offlineDestinations.length} destinations');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ OFFLINE LOAD FAILED: $e');
        }
      }

      // 2C. Deduplicate any combined offline results (SP + SQLite)
      if (offlineDestinations.isNotEmpty) {
        offlineDestinations = _deduplicateDestinations(offlineDestinations);
      }

      // STEP 3: Decision Logic - STRICT OFFLINE-FIRST
      List<Destination> destinations = [];
      String dataSource = 'unknown';

      if (offlineDestinations.isNotEmpty && !shouldRefresh) {
        // ✅ CASE 1: Use offline data (cache is still fresh)
        destinations = offlineDestinations;
        dataSource = 'offline_cache_fresh';

        if (kDebugMode) {
          print(
              '✅ USING OFFLINE DATA (cache fresh, ${destinations.length} destinations)');
        }
      } else if (offlineDestinations.isNotEmpty && !hasInternet) {
        // ✅ CASE 2: Use offline data (no internet, regardless of cache age)
        destinations = offlineDestinations;
        dataSource = 'offline_no_internet';

        if (kDebugMode) {
          print(
              '� USING OFFLINE DATA (no internet, ${destinations.length} destinations)');
        }
      } else if (hasInternet &&
          (shouldRefresh || offlineDestinations.isEmpty)) {
        // 🌐 CASE 3: Fetch from API (cache expired AND internet available)
        if (kDebugMode) {
          print('🌐 FETCHING FROM API (cache expired or no offline data)...');
        }

        // Get user preferences for API call
        final userPreferences = await _getUserPreferences();

        // Try Firestore first
        try {
          final firestoreDestinations = await _getFirestoreRecommendations(
            userLat,
            userLng,
            radiusKm,
            preferredTypes,
            userPreferences,
          );
          destinations.addAll(firestoreDestinations);
          dataSource = 'firestore';

          if (kDebugMode) {
            print(
                '🔥 FIRESTORE RESULT: ${firestoreDestinations.length} destinations');
          }

          // Persist Firestore results for offline use (fast and durable)
          if (firestoreDestinations.isNotEmpty) {
            try {
              await OfflineCacheService.cacheDestinations(firestoreDestinations);
              await offlineStorage.storeDestinations(
                firestoreDestinations,
                downloadImages: false,
                source: 'firestore',
              );
              if (kDebugMode) {
                print('💾 Persisted Firestore results to SharedPreferences and SQLite');
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Failed to persist Firestore results offline: $e');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ FIRESTORE FAILED: $e');
          }
        }

        // If need more and Magic Lane enabled, try Magic Lane API
        if (destinations.length < limit && useGooglePlaces) {
          try {
            if (kDebugMode) {
              print('🪄 TRYING MAGIC LANE API...');
            }

            final magicLaneDestinations =
                await MagicLaneService.searchNearbyPlaces(
              latitude: userLat,
              longitude: userLng,
              radiusKm: radiusKm,
              maxResults: limit - destinations.length,
              categories: preferredTypes ?? ['tourism', 'culture'],
            );

            if (magicLaneDestinations.isNotEmpty) {
              // Store new destinations for future offline use
              await _storeMagicLaneDestinations(magicLaneDestinations);
              await offlineStorage.storeDestinations(
                magicLaneDestinations,
                downloadImages: false,
                source: 'magic_lane',
              );
              // Also cache for fast startup
              try {
                await OfflineCacheService.cacheDestinations(magicLaneDestinations);
              } catch (e) {
                if (kDebugMode) {
                  print('⚠️ Failed to SharedPreferences-cache Magic Lane results: $e');
                }
              }

              destinations.addAll(magicLaneDestinations);
              dataSource = dataSource == 'firestore'
                  ? 'firestore_magic_lane'
                  : 'magic_lane';

              if (kDebugMode) {
                print(
                    '🪄 MAGIC LANE RESULT: ${magicLaneDestinations.length} destinations');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ MAGIC LANE FAILED: $e');
            }
          }
        }

        // If API calls failed but we have stale offline data, use it
        if (destinations.isEmpty && offlineDestinations.isNotEmpty) {
          destinations = offlineDestinations;
          dataSource = 'offline_fallback';

          if (kDebugMode) {
            print(
                '🔄 FALLBACK TO STALE OFFLINE DATA (${destinations.length} destinations)');
          }
        }

        // Mark cache as fresh if we got new data from API
        if (destinations.isNotEmpty && dataSource.contains('firestore') ||
            dataSource.contains('magic_lane')) {
          await _cacheManager.markRecommendationsFresh();

          if (kDebugMode) {
            print('✅ MARKED CACHE AS FRESH');
          }
        }
      } else {
        // ⚠️ CASE 4: No offline data and no internet
        dataSource = 'no_data';

        if (kDebugMode) {
          print('❌ NO DATA AVAILABLE (no offline data, no internet)');
        }

        // As a last-resort when completely offline, try quick SharedPreferences cache
        try {
          final spCached = await OfflineCacheService.getCachedDestinations();
          if (spCached.isNotEmpty) {
            if (kDebugMode) {
              print('📦 Using SharedPreferences cached destinations (${spCached.length})');
            }
            return spCached.take(limit).toList();
          }
        } catch (_) {}
      }

      // STEP 4: Apply filtering and ranking (get user data for this)
      if (kDebugMode) {
        print('🔧 APPLYING FILTERS AND RANKING...');
      }

      // Get user preferences and visited places for filtering/ranking
      final userPreferences = await _getUserPreferences();
      final visitedPlaces = await _getVisitedPlaces();

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

      // STEP 5: Log final results
      if (kDebugMode) {
        print('📊 FINAL RESULTS:');
        print('   - Data source: $dataSource');
        print('   - Destinations found: ${destinations.length}');
        print('   - Will return: ${destinations.take(limit).length}');
      }

      // Update user interaction for improved future recommendations
      await _updateUserInteraction('recommendations_viewed', {
        'location': {'lat': userLat, 'lng': userLng},
        'count': destinations.take(limit).length,
        'source': dataSource,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final finalDestinations = destinations.take(limit).toList();

      // STEP 6: PROACTIVE AI ENRICHMENT - Always enrich when internet available
      // This ensures enhanced data is cached before user clicks on cards
      if (hasInternet && finalDestinations.isNotEmpty) {
        if (kDebugMode) {
          print('🤖 STARTING PROACTIVE AI ENRICHMENT...');
          print('   - Destinations to process: ${finalDestinations.length}');
        }

        final enrichedDestinations = <Destination>[];

        for (final destination in finalDestinations) {
          try {
            // Check if this destination's AI cache is expired
            final isAICacheExpired =
                _cacheManager.isAIEnrichmentExpired(destination.id);

            if (isAICacheExpired) {
              // AI cache expired, enrich with fresh data
              final enriched = await enrichDestinationWithGemini(destination);
              await _cacheManager.markAIEnrichmentFresh(destination.id);
              enrichedDestinations.add(enriched);

              // Store enriched destination for instant access
              await _storeEnrichedDestination(enriched);

              if (kDebugMode) {
                print('✅ Enriched & cached ${destination.title} with fresh AI data');
              }
            } else {
              // AI cache still valid, use existing data
              enrichedDestinations.add(destination);

              if (kDebugMode) {
                print('📱 Using cached AI data for ${destination.title}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print(
                  '⚠️ Failed to enrich ${destination.title}, using original: $e');
            }
            enrichedDestinations.add(destination);
          }
        }

        if (kDebugMode) {
          print(
              '✅ Proactive AI enrichment completed for ${enrichedDestinations.length} destinations');
        }

        // Cache enriched destinations for offline access
        try {
          await OfflineCacheService.cacheDestinations(enrichedDestinations);
          await offlineStorage.storeDestinations(
            enrichedDestinations,
            downloadImages: false,
            source: 'ai_enriched',
          );
          if (kDebugMode) {
            print('💾 Cached enriched destinations for offline access');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Failed to cache enriched destinations: $e');
          }
        }

        return enrichedDestinations;
      } else if (!hasInternet) {
        if (kDebugMode) {
          print('📴 Proactive AI enrichment skipped - no internet connection');
        }
      } else if (finalDestinations.isEmpty) {
        if (kDebugMode) {
          print('📭 No destinations to enrich');
        }
      }

      return finalDestinations;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting recommendations: $e');
      }
      // Fallback to popular destinations
      return await _getFallbackRecommendations(limit);
    }
  }

  /// Enrich destination with Gemini AI-powered historical and educational information
  Future<Destination> enrichDestinationWithGemini(
      Destination destination) async {
    try {
      print('🤖 Enriching ${destination.title} with Gemini AI...');

      // Use Gemini to enhance place information
      final enrichedData =
          await _geminiService.enrichPlaceInformation(destination.title);

      if (enrichedData != null) {
        // Create enriched destination with additional AI-generated content
        return Destination(
          id: destination.id,
          title: destination.title,
          subtitle: destination.subtitle,
          imageUrl: enrichedData['imageUrl'] ?? destination.imageUrl,
          description: enrichedData['description'] ?? destination.description,
          rating: destination.rating,
          tags: [
            ...destination.tags,
            ...((enrichedData['tags'] as List<dynamic>?)
                    ?.map((e) => e.toString()) ??
                [])
          ],
          isFavorite: destination.isFavorite,
          type: destination.type,
          coordinates: destination.coordinates,
          distanceKm: destination.distanceKm,
          historicalInfo: HistoricalInfo(
            briefDescription: enrichedData['historical']?['briefDescription'] ??
                destination.historicalInfo?.briefDescription ??
                'Historical significance information generated by AI.',
            extendedDescription: enrichedData['historical']
                    ?['extendedDescription'] ??
                destination.historicalInfo?.extendedDescription ??
                'Detailed historical information generated by AI.',
            keyEvents: [
              ...(destination.historicalInfo?.keyEvents ?? []),
              ...((enrichedData['historical']?['keyEvents'] as List<dynamic>?)
                      ?.map((e) => e.toString()) ??
                  [])
            ],
            timeline: enrichedData['historical']?['timeline'] ??
                destination.historicalInfo?.timeline,
            relatedFigures: [
              ...(destination.historicalInfo?.relatedFigures ?? []),
              ...((enrichedData['historical']?['relatedFigures']
                          as List<dynamic>?)
                      ?.map((e) => e.toString()) ??
                  [])
            ],
          ),
          educationalInfo: EducationalInfo(
            facts: [
              ...(destination.educationalInfo?.facts ?? []),
              ...((enrichedData['educational']?['facts'] as List<dynamic>?)
                      ?.map((e) => e.toString()) ??
                  [])
            ],
            importance: enrichedData['educational']?['importance'] ??
                destination.educationalInfo?.importance ??
                'Educational importance information generated by AI.',
            culturalRelevance: enrichedData['educational']
                    ?['culturalRelevance'] ??
                destination.educationalInfo?.culturalRelevance ??
                'Cultural relevance information generated by AI.',
            learningObjectives: [
              ...(destination.educationalInfo?.learningObjectives ?? []),
              ...((enrichedData['educational']?['learningObjectives']
                          as List<dynamic>?)
                      ?.map((e) => e.toString()) ??
                  [])
            ],
            architecturalStyle: enrichedData['educational']
                    ?['architecturalStyle'] ??
                destination.educationalInfo?.architecturalStyle,
            categories: [
              ...(destination.educationalInfo?.categories ?? []),
              ...((enrichedData['educational']?['categories'] as List<dynamic>?)
                      ?.map((e) => e.toString()) ??
                  [])
            ],
          ),
          images: [
            ...destination.images,
            ...((enrichedData['images'] as List<dynamic>?)
                    ?.map((e) => e.toString()) ??
                [])
          ],
          createdAt: destination.createdAt,
          updatedAt: DateTime.now(),
          isOfflineAvailable: destination.isOfflineAvailable,
        );
      }

      print('✅ Successfully enriched ${destination.title} with AI data');
      return destination;
    } catch (e) {
      print('⚠️ Failed to enrich ${destination.title} with Gemini: $e');
      // Return original destination if enrichment fails
      return destination;
    }
  }

  /// Store enriched destination in both Firestore and offline storage
  Future<void> _storeEnrichedDestination(Destination enrichedDestination) async {
    try {
      // Update in Firestore with enriched data
      await _destinationsCollection.doc(enrichedDestination.id).update({
        'description': enrichedDestination.description,
        'historicalInfo': enrichedDestination.historicalInfo?.toJson(),
        'educationalInfo': enrichedDestination.educationalInfo?.toJson(),
        'tags': enrichedDestination.tags,
        'images': enrichedDestination.images,
        'isAIEnriched': true,
        'lastAIEnrichment': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('💾 Stored enriched ${enrichedDestination.title} in Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to store enriched destination in Firestore: $e');
      }
    }
  }

  /// Get destination by ID with cached enrichment check
  Future<Destination?> getDestinationById(String destinationId,
      {bool enrichWithAI = true}) async {
    try {
      print('🔍 Getting destination: $destinationId');

      // First try to get from offline storage (may have cached enriched version)
      final offlineStorage = SimpleOfflineStorageService();
      await offlineStorage.initialize();
      
      final offlineDestinations = await offlineStorage.getOfflineDestinations(limit: 50);
      final cachedDestination = offlineDestinations
          .cast<Destination?>()
          .firstWhere((d) => d?.id == destinationId, orElse: () => null);

      if (cachedDestination != null) {
        if (kDebugMode) {
          print('📱 Found cached destination: ${cachedDestination.title}');
        }
        
        // Check if cached version is AI-enriched and fresh
        final isAICacheExpired = _cacheManager.isAIEnrichmentExpired(destinationId);
        if (!isAICacheExpired && cachedDestination.historicalInfo != null) {
          if (kDebugMode) {
            print('✅ Using cached enriched destination');
          }
          return cachedDestination;
        }
      }

      // If not in cache or cache expired, get from Firestore
      final doc = await _destinationsCollection.doc(destinationId).get();

      if (doc.exists) {
        final destination = Destination.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });

        // Check if Firestore version needs enrichment
        final hasInternet = await _connectivityService.hasInternetConnection();
        if (enrichWithAI && hasInternet) {
          final isAICacheExpired = _cacheManager.isAIEnrichmentExpired(destinationId);
          
          if (isAICacheExpired) {
            final enriched = await enrichDestinationWithGemini(destination);
            await _cacheManager.markAIEnrichmentFresh(destinationId);
            await _storeEnrichedDestination(enriched);
            
            // Cache for future offline access
            try {
              await offlineStorage.storeDestinations([enriched], source: 'ai_enriched');
              await OfflineCacheService.cacheDestinations([enriched]);
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Failed to cache enriched destination: $e');
              }
            }
            
            return enriched;
          }
        }

        return destination;
      }

      // Fallback to cached version if Firestore fails
      return cachedDestination;
    } catch (e) {
      print('❌ Error getting destination $destinationId: $e');
      return null;
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
