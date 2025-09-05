import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/home/data/models/destination.dart';

/// Service for integrating with Magic Lane Search API for nearby places
/// Based on official Magic Lane API documentation
class MagicLaneService {
  static const String _searchUrl = 'https://search.magiclaneapis.com/v1';
  static String? _apiKey;

  /// Initialize the API credentials
  static void initialize() {
    try {
      print('🔍 DEBUG: Attempting to load Magic Lane API key...');
      _apiKey = dotenv.env['MAGIC_LANE_API_KEY'];

      print('🔍 DEBUG: API Key loaded: ${_apiKey != null ? "YES" : "NO"}');
      print('🔍 DEBUG: API Key length: ${_apiKey?.length ?? 0}');
      print(
          '🔍 DEBUG: API Key first 20 chars: ${_apiKey?.substring(0, min(20, _apiKey?.length ?? 0)) ?? "NULL"}');

      if (_apiKey?.isEmpty ?? true) {
        print('⚠️ WARNING: MAGIC_LANE_API_KEY not found in .env file');
        print('💡 Add MAGIC_LANE_API_KEY=your_api_key_here to your .env file');
        print('🔍 DEBUG: All env vars: ${dotenv.env.keys.toList()}');
      } else {
        print('✅ Magic Lane API initialized successfully');
      }
    } catch (e) {
      print('⚠️ WARNING: Could not load Magic Lane API key from .env: $e');
      print('💡 Make sure .env file exists and has proper encoding');
      _apiKey = null;
    }
  }

  /// Check if API is properly configured
  static bool get isConfigured => (_apiKey?.isNotEmpty ?? false);

  /// Search for nearby places using Magic Lane API
  static Future<List<Destination>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    List<String> categories = const ['tourism', 'culture', 'entertainment'],
    int maxResults = 20,
  }) async {
    if (!isConfigured) {
      print('⚠️ Magic Lane API not configured, returning empty list');
      return [];
    }

    try {
      print('🔍 Magic Lane: Searching places near ($latitude, $longitude)');

      // Convert categories to Magic Lane POI categories
      final poiCategories = _convertToMagicLaneCategories(categories);

      // Magic Lane API request payload
      final payload = {
        'type': 'around_location',
        'target': ['pois'],
        'poi_categs': poiCategories,
        'ref_location': [
          longitude,
          latitude
        ], // Magic Lane uses [lon, lat] format
        'max_results': maxResults,
        'debug': false,
        'locale': 'en',
      };

      final response = await http.post(
        Uri.parse(_searchUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _apiKey!,
        },
        body: jsonEncode(payload),
      );

      print('🔍 MagicLane: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null) {
          final List<dynamic> places = data['results'];
          print('🔍 Magic Lane: Found ${places.length} places');

          final destinations = <Destination>[];

          for (final place in places.take(maxResults)) {
            final destination =
                await _convertPlaceToDestination(place, latitude, longitude);
            if (destination != null) {
              destinations.add(destination);
            }
          }

          print('✅ Magic Lane: Converted ${destinations.length} destinations');
          return destinations;
        } else {
          throw Exception('Magic Lane API error: No results in response');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ MagicLane: Search failed: $e');
      return []; // Return empty list instead of throwing to allow fallback
    }
  }

  /// Convert categories to Magic Lane POI categories
  static List<String> _convertToMagicLaneCategories(List<String> categories) {
    final Set<String> magicLaneCategories = {};

    for (final category in categories) {
      switch (category.toLowerCase()) {
        case 'tourism':
        case 'attraction':
          magicLaneCategories.add('sightseeing');
          break;
        case 'culture':
        case 'cultural':
          magicLaneCategories.addAll(['sightseeing', 'entertainment']);
          break;
        case 'entertainment':
          magicLaneCategories.add('entertainment');
          break;
        case 'monument':
          magicLaneCategories.add('sightseeing');
          break;
        case 'museum':
          magicLaneCategories.add('sightseeing');
          break;
        case 'park':
        case 'natural':
          magicLaneCategories.add('sightseeing');
          break;
        case 'religious':
        case 'religious_site':
          magicLaneCategories.add('religious_places');
          break;
        case 'food':
        case 'restaurant':
          magicLaneCategories.add('food&drink');
          break;
        default:
          magicLaneCategories.add('sightseeing');
      }
    }

    return magicLaneCategories.toList();
  }

  /// Search for places by text query
  static Future<List<Destination>> searchPlacesByText({
    required String query,
    double? latitude,
    double? longitude,
    double radiusKm = 100,
    int maxResults = 20,
  }) async {
    if (!isConfigured) {
      return [];
    }

    try {
      print('🔍 MagicLane: Text search for "$query"');

      // Magic Lane text search payload
      final payload = {
        'type': 'free_text',
        'text': query,
        'target': ['pois', 'addresses'],
        'poi_categs': ['sightseeing', 'entertainment', 'food&drink'],
        'max_results': maxResults,
        'debug': false,
        'locale': 'en',
        if (latitude != null && longitude != null)
          'ref_location': [longitude, latitude],
      };

      final response = await http.post(
        Uri.parse(_searchUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _apiKey!,
        },
        body: jsonEncode(payload),
      );

      print('🔍 MagicLane: Response status ${response.statusCode}');
      print(
          '🔍 MagicLane: Response body: ${response.body.substring(0, min(500, response.body.length))}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 MagicLane: Parsed response data keys: ${data.keys.toList()}');

        // Try different response formats
        List<dynamic> places = [];

        if (data['results'] != null) {
          places = data['results'];
          print('🔍 MagicLane: Found ${places.length} places in results');
        } else if (data['data'] != null && data['data']['places'] != null) {
          places = data['data']['places'];
          print('🔍 MagicLane: Found ${places.length} places in data.places');
        } else if (data['places'] != null) {
          places = data['places'];
          print('🔍 MagicLane: Found ${places.length} places in places');
        } else if (data is List) {
          places = data;
          print(
              '🔍 MagicLane: Response is direct array with ${places.length} places');
        }

        final destinations = <Destination>[];

        for (final place in places) {
          print(
              '🔍 MagicLane: Processing place: ${place.runtimeType} - ${place.toString().substring(0, min(200, place.toString().length))}');

          // Try both conversion methods
          Destination? destination =
              _convertMagicLaneToDestination(place, latitude, longitude);
          if (destination == null) {
            destination =
                await _convertPlaceToDestination(place, latitude, longitude);
          }

          if (destination != null) {
            destinations.add(destination);
            print('✅ MagicLane: Successfully converted: ${destination.title}');
          } else {
            print('❌ MagicLane: Failed to convert place');
          }
        }

        print('✅ MagicLane: Returning ${destinations.length} destinations');
        return destinations;
      }

      return [];
    } catch (e) {
      print('❌ MagicLane: Text search failed: $e');
      return [];
    }
  }

  /// Convert Magic Lane API response to Destination model
  static Future<Destination?> _convertPlaceToDestination(
    Map<String, dynamic> place,
    double? userLat,
    double? userLng,
  ) async {
    try {
      // Magic Lane API response format
      final String placeId = place['name']?.toString() ?? '';
      final String name = place['name'] ?? 'Unknown Place';
      final String address = place['address']?['settlement']?.toString() ??
          place['address']?['city']?.toString() ??
          '';
      final double? rating = null; // Magic Lane doesn't provide ratings
      final List<dynamic> coordinates = place['coordinates'] ?? [];

      // Get coordinates from Magic Lane format [longitude, latitude]
      GeoCoordinates? geoCoordinates;
      double? distance;

      if (coordinates.length >= 2) {
        final lng = (coordinates[0] as num).toDouble();
        final lat = (coordinates[1] as num).toDouble();
        geoCoordinates = GeoCoordinates(latitude: lat, longitude: lng);

        // Calculate distance if user location provided
        if (userLat != null && userLng != null) {
          distance = _calculateDistance(userLat, userLng, lat, lng);
        }
      }

      // Get description from Magic Lane
      final String? description = place['description']?.toString();

      // Determine destination type from Magic Lane description
      String destinationType =
          _inferDestinationTypeFromDescription(name, description ?? '');

      // Magic Lane doesn't provide photos directly
      List<String> images = [];

      // Create historical and educational info
      HistoricalInfo? historicalInfo =
          await _createHistoricalInfo(name, description, destinationType, null);

      EducationalInfo? educationalInfo = await _createEducationalInfo(
          name, description, destinationType, [], null);

      return Destination(
        id: placeId,
        title: name,
        subtitle: address.isNotEmpty ? address : 'Location',
        imageUrl: images.isNotEmpty ? images.first : null,
        description: description,
        rating: rating,
        tags: [destinationType],
        type: destinationType,
        coordinates: geoCoordinates,
        distanceKm: distance,
        historicalInfo: historicalInfo,
        educationalInfo: educationalInfo,
        images: images,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineAvailable: false,
      );
    } catch (e) {
      print('❌ Magic Lane: Error converting place to destination: $e');
      return null;
    }
  }

  /// Infer destination type from name and description
  static String _inferDestinationTypeFromDescription(
      String name, String description) {
    final allText = '$name $description'.toLowerCase();

    if (allText.contains('museum') || allText.contains('gallery'))
      return 'museum';
    if (allText.contains('monument') ||
        allText.contains('memorial') ||
        allText.contains('landmark')) return 'monument';
    if (allText.contains('park') ||
        allText.contains('garden') ||
        allText.contains('natural')) return 'park';
    if (allText.contains('church') ||
        allText.contains('temple') ||
        allText.contains('mosque') ||
        allText.contains('worship') ||
        allText.contains('cathedral')) return 'religious_site';
    if (allText.contains('theater') ||
        allText.contains('cinema') ||
        allText.contains('entertainment')) return 'entertainment';
    if (allText.contains('cultural') ||
        allText.contains('heritage') ||
        allText.contains('historic')) return 'cultural';

    return 'attraction';
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLng = (lng2 - lng1) * (pi / 180);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get detailed place information
  static Future<Destination?> getPlaceDetails(String placeId) async {
    if (!isConfigured) {
      return null;
    }

    try {
      print('🔍 Magic Lane: Getting details for place $placeId');

      // Magic Lane doesn't have a separate details endpoint
      // Return null for now - details are included in search results
      return null;
    } catch (e) {
      print('❌ MagicLane: Get place details failed: $e');
      return null;
    }
  }

  /// Convert Magic Lane API response to Destination model
  static Destination? _convertMagicLaneToDestination(
    Map<String, dynamic> place,
    double? userLat,
    double? userLng,
  ) {
    try {
      print('🔍 Converting place: ${place.keys.toList()}');

      // Handle different field names
      final String placeId = place['id']?.toString() ??
          place['place_id']?.toString() ??
          (place['name']?.toString())?.replaceAll(' ', '_').toLowerCase() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final String name = place['name']?.toString() ??
          place['title']?.toString() ??
          place['display_name']?.toString() ??
          'Unknown Place';

      // Handle different address formats
      String address = '';
      if (place['address'] != null) {
        if (place['address'] is String) {
          address = place['address'];
        } else if (place['address'] is Map) {
          final addressMap = place['address'] as Map<String, dynamic>;
          final parts = <String>[];

          // Try common address fields
          ['city', 'town', 'village', 'state', 'country', 'settlement']
              .forEach((field) {
            if (addressMap[field] != null) {
              parts.add(addressMap[field].toString());
            }
          });

          address = parts.join(', ');
        }
      } else if (place['formatted_address'] != null) {
        address = place['formatted_address'].toString();
      } else if (place['display_name'] != null) {
        address = place['display_name'].toString();
      }

      final double? rating = (place['rating'] as num?)?.toDouble();
      final List<dynamic> categories =
          place['categories'] ?? place['types'] ?? [];

      // Get coordinates - try multiple formats
      GeoCoordinates? coordinates;
      double? distance;

      // Format 1: location object with lat/lng
      if (place['location'] != null) {
        final location = place['location'];
        if (location['lat'] != null && location['lng'] != null) {
          final lat = (location['lat'] as num).toDouble();
          final lng = (location['lng'] as num).toDouble();
          coordinates = GeoCoordinates(latitude: lat, longitude: lng);

          if (userLat != null && userLng != null) {
            distance = _calculateDistance(userLat, userLng, lat, lng);
          }
        }
      }

      // Format 2: direct lat/lng fields
      if (coordinates == null && place['lat'] != null && place['lng'] != null) {
        final lat = (place['lat'] as num).toDouble();
        final lng = (place['lng'] as num).toDouble();
        coordinates = GeoCoordinates(latitude: lat, longitude: lng);

        if (userLat != null && userLng != null) {
          distance = _calculateDistance(userLat, userLng, lat, lng);
        }
      }

      // Format 3: coordinates array [lng, lat] (Magic Lane format)
      if (coordinates == null && place['coordinates'] != null) {
        final coords = place['coordinates'];
        if (coords is List && coords.length >= 2) {
          final lng = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          coordinates = GeoCoordinates(latitude: lat, longitude: lng);

          if (userLat != null && userLng != null) {
            distance = _calculateDistance(userLat, userLng, lat, lng);
          }
        }
      }

      // Determine destination type
      String destinationType =
          _mapMagicLaneCategoryToDestinationType(categories);

      // Get photos
      List<String> images = [];
      final List<dynamic>? photos = place['images'] ?? place['photos'];
      if (photos != null && photos.isNotEmpty) {
        images = photos
            .where((photo) =>
                photo['url'] != null || photo['photo_reference'] != null)
            .map<String>((photo) =>
                photo['url']?.toString() ??
                photo['photo_reference']?.toString() ??
                '')
            .where((url) => url.isNotEmpty)
            .take(5)
            .toList();
      }

      // Create historical and educational info from Magic Lane data
      HistoricalInfo? historicalInfo;
      EducationalInfo? educationalInfo;

      final description =
          place['description']?.toString() ?? place['vicinity']?.toString();
      final historicalData = place['historical_info'];
      final educationalData = place['educational_info'];

      if (historicalData != null || description != null) {
        historicalInfo = HistoricalInfo(
          briefDescription: historicalData?['brief'] ??
              (description != null && description.length > 200
                  ? '${description.substring(0, 200)}...'
                  : description ?? ''),
          extendedDescription: historicalData?['extended'] ?? description ?? '',
          keyEvents: List<String>.from(historicalData?['key_events'] ?? []),
          relatedFigures:
              List<String>.from(historicalData?['related_figures'] ?? []),
        );
      }

      if (educationalData != null || categories.isNotEmpty) {
        educationalInfo = EducationalInfo(
          facts: List<String>.from(educationalData?['facts'] ??
              _generateFactsFromCategory(destinationType)),
          importance: educationalData?['importance'] ??
              'Significant cultural and tourist destination',
          culturalRelevance: educationalData?['cultural_relevance'] ??
              'Important local attraction with cultural significance',
          categories: categories.map((cat) => cat.toString()).toList(),
        );
      }

      print(
          '✅ Successfully created destination: $name at ${coordinates?.latitude}, ${coordinates?.longitude}');

      return Destination(
        id: placeId,
        title: name,
        subtitle: address.isNotEmpty ? address : 'Location',
        imageUrl: images.isNotEmpty ? images.first : null,
        description: description,
        rating: rating,
        tags: categories.map((cat) => cat.toString()).toList(),
        type: destinationType,
        coordinates: coordinates,
        distanceKm: distance,
        historicalInfo: historicalInfo,
        educationalInfo: educationalInfo,
        images: images,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOfflineAvailable: false,
      );
    } catch (e) {
      print('❌ MagicLane: Error converting place to destination: $e');
      return null;
    }
  }

  /// Map Magic Lane categories to our destination types
  static String _mapMagicLaneCategoryToDestinationType(
      List<dynamic> categories) {
    final categoryStrings =
        categories.map((cat) => cat.toString().toLowerCase()).toList();

    if (categoryStrings.contains('museum') ||
        categoryStrings.contains('gallery')) return 'museum';
    if (categoryStrings.contains('monument') ||
        categoryStrings.contains('landmark')) return 'monument';
    if (categoryStrings.contains('park') || categoryStrings.contains('garden'))
      return 'park';
    if (categoryStrings.contains('religious') ||
        categoryStrings.contains('temple') ||
        categoryStrings.contains('church') ||
        categoryStrings.contains('mosque')) return 'religious_site';
    if (categoryStrings.contains('entertainment') ||
        categoryStrings.contains('theater')) return 'entertainment';
    if (categoryStrings.contains('nature') ||
        categoryStrings.contains('natural')) return 'natural';
    if (categoryStrings.contains('cultural') ||
        categoryStrings.contains('heritage')) return 'cultural';

    return 'attraction';
  }

  /// Generate educational facts based on destination type
  static List<String> _generateFactsFromCategory(String type) {
    switch (type) {
      case 'museum':
        return [
          'Houses valuable artifacts and exhibits',
          'Preserves cultural and historical heritage',
          'Offers interactive learning experiences',
          'Features rotating and permanent collections'
        ];
      case 'monument':
        return [
          'Significant historical landmark',
          'Represents important cultural heritage',
          'Built with distinctive architectural style',
          'Commemorates historical events or figures'
        ];
      case 'park':
        return [
          'Natural recreation and relaxation space',
          'Supports local wildlife and biodiversity',
          'Promotes environmental conservation',
          'Provides outdoor activities and exercise opportunities'
        ];
      case 'religious_site':
        return [
          'Important spiritual and religious center',
          'Features unique architectural elements',
          'Holds cultural and historical significance',
          'Center for community gatherings and ceremonies'
        ];
      case 'cultural':
        return [
          'Showcases local traditions and customs',
          'Promotes cultural understanding',
          'Hosts cultural events and performances',
          'Preserves intangible cultural heritage'
        ];
      default:
        return [
          'Popular tourist destination',
          'Significant to local community',
          'Offers unique experiences',
          'Part of regional cultural landscape'
        ];
    }
  }

  /// Create historical information from place data
  static Future<HistoricalInfo?> _createHistoricalInfo(String name,
      String? description, String type, Map<String, dynamic>? details) async {
    if (description == null || description.isEmpty) return null;

    try {
      // Extract historical events and figures from description
      final events = _extractHistoricalEvents(description, name);
      final figures = _extractRelatedFigures(description, name);

      return HistoricalInfo(
        briefDescription: description.length > 150
            ? '${description.substring(0, 150)}...'
            : description,
        extendedDescription: description,
        keyEvents: events,
        relatedFigures: figures,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create educational information from place data
  static Future<EducationalInfo?> _createEducationalInfo(
    String name,
    String? description,
    String type,
    List<dynamic> categories,
    Map<String, dynamic>? details,
  ) async {
    try {
      final facts = _generateFactsFromType(type, description ?? '', name);
      final importance = _generateImportanceDescription(type, name);
      final culturalRelevance =
          _generateCulturalRelevance(type, description ?? '').join('. ');

      return EducationalInfo(
        facts: facts,
        importance: importance,
        culturalRelevance: culturalRelevance,
        learningObjectives: [
          'Learn about local history',
          'Understand cultural significance'
        ],
      );
    } catch (e) {
      return null;
    }
  }

  /// Extract historical events from description
  static List<String> _extractHistoricalEvents(
      String description, String name) {
    final events = <String>[];
    final text = description.toLowerCase();

    // Common historical indicators
    final eventPatterns = [
      'built in',
      'constructed in',
      'established in',
      'founded in',
      'during the',
      'in the year',
      'century',
      'war',
      'battle',
      'reign of',
      'ruled by',
      'occupied by',
      'liberated in'
    ];

    for (final pattern in eventPatterns) {
      if (text.contains(pattern)) {
        final index = text.indexOf(pattern);
        final start = max(0, index - 20);
        final end = min(description.length, index + 80);
        final event = description.substring(start, end).trim();
        if (event.isNotEmpty && !events.contains(event)) {
          events.add(event);
        }
      }
    }

    // Add some generic events based on type
    if (events.isEmpty) {
      if (text.contains('ancient') || text.contains('old')) {
        events.add('Ancient historical significance');
      }
      if (text.contains('heritage') || text.contains('cultural')) {
        events.add('Recognized as cultural heritage site');
      }
    }

    return events.take(5).toList();
  }

  /// Extract related historical figures from description
  static List<String> _extractRelatedFigures(String description, String name) {
    final figures = <String>[];
    final text = description.toLowerCase();

    // Common figure indicators
    final figurePatterns = [
      'emperor',
      'king',
      'queen',
      'prince',
      'princess',
      'architect',
      'designer',
      'builder',
      'founder',
      'ruler',
      'leader',
      'general',
      'admiral'
    ];

    for (final pattern in figurePatterns) {
      if (text.contains(pattern)) {
        final index = text.indexOf(pattern);
        final start = max(0, index - 10);
        final end = min(description.length, index + 50);
        final figure = description.substring(start, end).trim();
        if (figure.isNotEmpty && !figures.contains(figure)) {
          figures.add(figure);
        }
      }
    }

    return figures.take(3).toList();
  }

  /// Generate facts based on destination type
  static List<String> _generateFactsFromType(
      String type, String description, String name) {
    final facts = <String>[];

    switch (type) {
      case 'museum':
        facts.addAll([
          'Houses important cultural artifacts',
          'Offers educational exhibitions',
          'Preserves historical collections'
        ]);
        break;
      case 'monument':
        facts.addAll([
          'Commemorates historical events or figures',
          'Represents architectural heritage',
          'Symbol of cultural identity'
        ]);
        break;
      case 'park':
        facts.addAll([
          'Provides natural habitat for wildlife',
          'Offers recreational opportunities',
          'Contributes to environmental conservation'
        ]);
        break;
      case 'religious_site':
        facts.addAll([
          'Place of worship and spiritual significance',
          'Showcases religious architecture',
          'Center of community gatherings'
        ]);
        break;
      default:
        facts.addAll([
          'Popular tourist destination',
          'Cultural landmark of the region',
          'Offers unique visitor experiences'
        ]);
    }

    return facts;
  }

  /// Generate importance description
  static String _generateImportanceDescription(String type, String name) {
    switch (type) {
      case 'museum':
        return '$name serves as an important cultural institution, preserving and showcasing artifacts that tell the story of our heritage.';
      case 'monument':
        return '$name stands as a testament to historical events and figures, serving as a reminder of our shared past.';
      case 'park':
        return '$name provides essential green space for the community while preserving natural ecosystems.';
      case 'religious_site':
        return '$name holds deep spiritual significance and represents the religious heritage of the community.';
      default:
        return '$name is recognized as a significant cultural landmark that contributes to the region\'s identity and tourism.';
    }
  }

  /// Generate cultural relevance
  static List<String> _generateCulturalRelevance(
      String type, String description) {
    final relevance = <String>[];

    if (description.contains('traditional') ||
        description.contains('heritage')) {
      relevance.add('Preserves traditional cultural practices');
    }
    if (description.contains('art') || description.contains('artistic')) {
      relevance.add('Showcases artistic achievements');
    }
    if (description.contains('community') || description.contains('local')) {
      relevance.add('Important to local community identity');
    }

    // Default relevance based on type
    switch (type) {
      case 'museum':
        relevance.addAll(['Educational resource', 'Cultural preservation']);
        break;
      case 'monument':
        relevance.addAll(['Historical commemoration', 'National pride']);
        break;
      case 'park':
        relevance
            .addAll(['Environmental awareness', 'Recreation and wellness']);
        break;
      case 'religious_site':
        relevance.addAll(['Spiritual guidance', 'Community gathering place']);
        break;
      default:
        relevance.addAll(['Tourism development', 'Cultural exchange']);
    }

    return relevance.take(4).toList();
  }
}
