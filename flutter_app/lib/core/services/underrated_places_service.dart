import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/journeys/data/models/underrated_place.dart';
import '../../features/profile/data/services/preferences_service.dart';
import '../utils/distance_calculator.dart';

/// Service for managing underrated places from CSV dataset
class UnderratedPlacesService {
  static const String _csvPath = 'assets/dataset/underrated_places.csv';
  static const String _cacheKey = 'underrated_places_geocoded';
  static const int _maxPlacesPerLocation = 5;
  static const double _defaultRadiusKm = 10.0;

  List<UnderratedPlace>? _places;
  bool _isInitialized = false;

  /// Initialize the service by loading and parsing CSV
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('📍 Initializing UnderratedPlacesService...');

      // Try to load from cache first
      final cachedPlaces = await _loadFromCache();
      if (cachedPlaces != null && cachedPlaces.isNotEmpty) {
        _places = cachedPlaces;
        _isInitialized = true;
        debugPrint('✅ Loaded ${_places!.length} places from cache');
        return;
      }

      // Load and parse CSV
      final csvString = await rootBundle.loadString(_csvPath);
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
        shouldParseNumbers: false,
      );

      // Skip header row and parse data
      _places = [];
      for (int i = 1; i < csvData.length; i++) {
        try {
          final place = UnderratedPlace.fromCsvRow(csvData[i]);
          if (place.name.isNotEmpty) {
            _places!.add(place);
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing CSV row $i: $e');
        }
      }

      debugPrint('✅ Loaded ${_places!.length} underrated places from CSV');

      // Geocode anchor locations in background
      _geocodePlacesAsync();

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error initializing UnderratedPlacesService: $e');
      _places = [];
      _isInitialized = false;
    }
  }

  /// Find underrated places near given coordinates
  Future<List<UnderratedPlace>> findNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusKm = _defaultRadiusKm,
    int? maxResults,
  }) async {
    if (!_isInitialized || _places == null) {
      await initialize();
    }

    if (_places == null || _places!.isEmpty) {
      return [];
    }

    final nearbyPlaces = <UnderratedPlace>[];

    for (final place in _places!) {
      // If place has coordinates, use GPS-based distance
      if (place.hasCoordinates) {
        final distance = DistanceCalculator.calculateDistance(
          lat1: latitude,
          lon1: longitude,
          lat2: place.latitude!,
          lon2: place.longitude!,
        );

        if (distance <= radiusKm) {
          nearbyPlaces.add(place);
        }
      }
    }

    // Sort by underrated score (highest first) and distance
    nearbyPlaces.sort((a, b) {
      final scoreComparison = b.underratedScore.compareTo(a.underratedScore);
      if (scoreComparison != 0) return scoreComparison;

      // If scores are equal, sort by distance
      if (a.hasCoordinates && b.hasCoordinates) {
        final distA = DistanceCalculator.calculateDistance(
          lat1: latitude,
          lon1: longitude,
          lat2: a.latitude!,
          lon2: a.longitude!,
        );
        final distB = DistanceCalculator.calculateDistance(
          lat1: latitude,
          lon1: longitude,
          lat2: b.latitude!,
          lon2: b.longitude!,
        );
        return distA.compareTo(distB);
      }
      return 0;
    });

    // Limit results
    final limit = maxResults ?? _maxPlacesPerLocation;
    return nearbyPlaces.take(limit).toList();
  }

  /// Find places near multiple locations (for journey with multiple stops)
  Future<List<UnderratedPlace>> findPlacesAlongRoute({
    required List<LocationPoint> locations,
    double? radiusKm,
    int maxPerLocation = 3,
  }) async {
    // Get radius from user preferences if not specified
    final preferencesService = PreferencesService();
    final effectiveRadius = radiusKm ?? await preferencesService.getUnderratedPlacesRadius();
    
    debugPrint('🔍 Searching underrated places with radius: $effectiveRadius km');
    
    final allPlaces = <String, UnderratedPlace>{}; // Use map to avoid duplicates

    for (final location in locations) {
      final nearby = await findNearbyPlaces(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusKm: effectiveRadius,
        maxResults: maxPerLocation,
      );

      for (final place in nearby) {
        // Use name + anchor location as unique key
        final key = '${place.name}_${place.anchorLocation}';
        if (!allPlaces.containsKey(key)) {
          allPlaces[key] = place;
        }
      }
    }

    // Convert to list and sort by underrated score
    final result = allPlaces.values.toList();
    result.sort((a, b) => b.underratedScore.compareTo(a.underratedScore));

    return result;
  }

  /// Geocode places asynchronously in background
  Future<void> _geocodePlacesAsync() async {
    if (_places == null || _places!.isEmpty) return;

    debugPrint('🌍 Starting geocoding for ${_places!.length} places...');
    
    int geocoded = 0;
    int failed = 0;

    for (int i = 0; i < _places!.length; i++) {
      final place = _places![i];
      
      // Skip if already has coordinates
      if (place.hasCoordinates) {
        geocoded++;
        continue;
      }

      try {
        // Build search query
        final query = _buildGeocodingQuery(place);
        
        // Rate limiting - wait 100ms between requests
        await Future.delayed(const Duration(milliseconds: 100));
        
        final locations = await locationFromAddress(query);
        
        if (locations.isNotEmpty) {
          place.latitude = locations.first.latitude;
          place.longitude = locations.first.longitude;
          geocoded++;
          
          // Save progress every 50 places
          if (geocoded % 50 == 0) {
            await _saveToCache();
            debugPrint('💾 Geocoding progress: $geocoded/${_places!.length}');
          }
        }
      } catch (e) {
        failed++;
        // Silently fail for individual places
      }
    }

    // Save final results
    await _saveToCache();
    debugPrint('✅ Geocoding complete: $geocoded succeeded, $failed failed');
  }

  /// Build geocoding query from place data
  String _buildGeocodingQuery(UnderratedPlace place) {
    final parts = <String>[];
    
    // Priority order: anchor_location, district, state
    if (place.anchorLocation.isNotEmpty) {
      parts.add(place.anchorLocation);
    }
    if (place.district != null && place.district!.isNotEmpty) {
      parts.add(place.district!);
    }
    if (place.state != null && place.state!.isNotEmpty) {
      parts.add(place.state!);
    }
    
    // Add India to improve geocoding accuracy
    parts.add('India');
    
    return parts.join(', ');
  }

  /// Save geocoded places to cache
  Future<void> _saveToCache() async {
    if (_places == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final placesJson = _places!.map((p) => p.toMap()).toList();
      final jsonString = jsonEncode(placesJson);
      await prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      debugPrint('⚠️ Error saving to cache: $e');
    }
  }

  /// Load geocoded places from cache
  Future<List<UnderratedPlace>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
      if (jsonString == null) return null;
      
      final List<dynamic> placesJson = jsonDecode(jsonString);
      return placesJson.map((json) => UnderratedPlace.fromMap(json)).toList();
    } catch (e) {
      debugPrint('⚠️ Error loading from cache: $e');
      return null;
    }
  }

  /// Clear cache (useful for updates)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    _isInitialized = false;
    _places = null;
  }

  /// Get all places (for debugging)
  List<UnderratedPlace> getAllPlaces() {
    return _places ?? [];
  }

  /// Check if service is ready
  bool get isInitialized => _isInitialized;

  /// Get total count of places
  int get placesCount => _places?.length ?? 0;

  /// Get count of geocoded places
  int get geocodedCount => _places?.where((p) => p.hasCoordinates).length ?? 0;
}

/// Helper class for location points
class LocationPoint {
  final double latitude;
  final double longitude;
  final String name;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.name,
  });
}
