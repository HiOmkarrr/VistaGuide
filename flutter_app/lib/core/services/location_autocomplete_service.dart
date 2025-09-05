import 'dart:async';
import 'magic_lane_service.dart';
import '../../features/home/data/models/destination.dart';

/// Location suggestion model
class LocationSuggestion {
  final String id;
  final String title;
  final String subtitle;
  final double? latitude;
  final double? longitude;
  final String? type;
  final String? country;
  final String? state;
  final String? city;

  const LocationSuggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    this.latitude,
    this.longitude,
    this.type,
    this.country,
    this.state,
    this.city,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      type: json['type']?.toString(),
      country: json['country']?.toString(),
      state: json['state']?.toString(),
      city: json['city']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'country': country,
      'state': state,
      'city': city,
    };
  }

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationSuggestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Service for location autocomplete using Magic Lane API with optimizations
class LocationAutocompleteService {
  static Timer? _debounceTimer;

  // Cache for search results to avoid repeated API calls
  static final Map<String, List<LocationSuggestion>> _searchCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 10);
  static const int _maxCacheSize = 100;

  // Track current search to cancel outdated requests
  static String? _currentSearchId;

  /// Get location suggestions with debouncing and caching
  static Future<List<LocationSuggestion>> getSuggestions(
    String query, {
    double? userLatitude,
    double? userLongitude,
    int maxResults = 10,
    Duration debounceTime = const Duration(milliseconds: 500),
  }) async {
    final trimmedQuery = query.trim().toLowerCase();

    // Early return for short queries
    if (trimmedQuery.isEmpty || trimmedQuery.length < 2) {
      return [];
    }

    if (!MagicLaneService.isConfigured) {
      print('⚠️ Location Autocomplete: Magic Lane API not configured');
      return [];
    }

    // Check cache first
    final cachedResult = _getCachedResult(trimmedQuery);
    if (cachedResult != null) {
      print('✅ Using cached result for "$trimmedQuery"');
      return cachedResult.take(maxResults).toList();
    }

    // Cancel previous timer if exists
    _debounceTimer?.cancel();

    final completer = Completer<List<LocationSuggestion>>();
    final searchId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentSearchId = searchId;

    _debounceTimer = Timer(debounceTime, () async {
      // Check if this search is still current
      if (_currentSearchId != searchId) {
        completer.complete([]);
        return;
      }

      try {
        final suggestions = await _performOptimizedSearch(
          trimmedQuery,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
          maxResults: maxResults,
        );

        // Only complete if this search is still current
        if (_currentSearchId == searchId) {
          completer.complete(suggestions);
        } else {
          completer.complete([]);
        }
      } catch (e) {
        print('❌ Location Autocomplete: Error getting suggestions: $e');
        completer.complete([]);
      }
    });

    return completer.future;
  }

  /// Get cached search result if still valid
  static List<LocationSuggestion>? _getCachedResult(String query) {
    final timestamp = _cacheTimestamps[query];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheValidDuration) {
      // Cache expired, remove it
      _searchCache.remove(query);
      _cacheTimestamps.remove(query);
      return null;
    }

    return _searchCache[query];
  }

  /// Cache search results
  static void _cacheResult(String query, List<LocationSuggestion> results) {
    // Clean old cache if it's getting too big
    if (_searchCache.length >= _maxCacheSize) {
      _cleanOldCache();
    }

    _searchCache[query] = results;
    _cacheTimestamps[query] = DateTime.now();
  }

  /// Clean old cache entries
  static void _cleanOldCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheValidDuration) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _searchCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    // If still too many, remove oldest entries
    if (_searchCache.length >= _maxCacheSize) {
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final entriesToRemove =
          sortedEntries.take(_searchCache.length - _maxCacheSize + 10);
      for (final entry in entriesToRemove) {
        _searchCache.remove(entry.key);
        _cacheTimestamps.remove(entry.key);
      }
    }
  }

  /// Perform optimized search using Magic Lane API
  static Future<List<LocationSuggestion>> _performOptimizedSearch(
    String query, {
    double? userLatitude,
    double? userLongitude,
    int maxResults = 10,
  }) async {
    try {
      print('🔍 Location Autocomplete: Searching for "$query"');

      // Use a smaller limit for API call to reduce data transfer
      final apiLimit = (maxResults * 1.5).ceil().clamp(5, 20);

      // Use Magic Lane's searchPlacesByText method
      final destinations = await MagicLaneService.searchPlacesByText(
        query: query,
        latitude: userLatitude,
        longitude: userLongitude,
        maxResults: apiLimit,
      );

      if (destinations.isEmpty) {
        print('📍 No destinations found, caching empty result');
        _cacheResult(query, []);
        return [];
      }

      // Pre-filter and convert efficiently
      final suggestions = <LocationSuggestion>[];
      final seenIds = <String>{};
      final queryLower = query.toLowerCase();

      for (final destination in destinations) {
        // Skip if we already have this ID
        if (seenIds.contains(destination.id)) continue;

        final suggestion = _convertDestinationToSuggestion(destination);
        if (suggestion != null) {
          // Quick relevance check - only include if title contains query
          if (suggestion.title.toLowerCase().contains(queryLower)) {
            suggestions.add(suggestion);
            seenIds.add(destination.id);
          }
        }

        // Early break if we have enough results
        if (suggestions.length >= maxResults) break;
      }

      // Sort efficiently using a simpler algorithm
      final sortedSuggestions = _quickSort(suggestions, queryLower);
      final finalResults = sortedSuggestions.take(maxResults).toList();

      // Cache the results
      _cacheResult(query, finalResults);

      print(
          '✅ Location Autocomplete: Returning ${finalResults.length} suggestions');
      return finalResults;
    } catch (e) {
      print('❌ Location Autocomplete: Search failed: $e');
      return [];
    }
  }

  /// Quick and efficient sorting based on relevance
  static List<LocationSuggestion> _quickSort(
      List<LocationSuggestion> suggestions, String queryLower) {
    if (suggestions.length <= 1) return suggestions;

    // Use a simple scoring system instead of complex comparisons
    final scored = suggestions.map((suggestion) {
      final titleLower = suggestion.title.toLowerCase();
      int score = 0;

      // Exact match gets highest score
      if (titleLower == queryLower) {
        score = 1000;
      }
      // Starts with query gets high score
      else if (titleLower.startsWith(queryLower)) {
        score = 500 - titleLower.length; // Shorter is better
      }
      // Contains query gets medium score
      else if (titleLower.contains(queryLower)) {
        score = 100 - titleLower.length;
      }

      return MapEntry(score, suggestion);
    }).toList();

    // Sort by score (descending)
    scored.sort((a, b) => b.key.compareTo(a.key));

    return scored.map((entry) => entry.value).toList();
  }

  /// Convert Destination to LocationSuggestion
  static LocationSuggestion? _convertDestinationToSuggestion(
      Destination destination) {
    try {
      // Build subtitle from available location data
      final subtitleParts = <String>[];

      if (destination.subtitle.isNotEmpty) {
        subtitleParts.add(destination.subtitle);
      }

      // If subtitle doesn't contain location info, try to extract from other fields
      if (subtitleParts.isEmpty || !subtitleParts.first.contains(',')) {
        // Try to build location info from type
        subtitleParts.add(_formatDestinationType(destination.type));
      }

      final subtitle = subtitleParts.join(', ');

      return LocationSuggestion(
        id: destination.id,
        title: destination.title,
        subtitle: subtitle.isNotEmpty ? subtitle : 'Location',
        latitude: destination.coordinates?.latitude,
        longitude: destination.coordinates?.longitude,
        type: destination.type,
        country: _extractCountryFromSubtitle(subtitle),
        state: _extractStateFromSubtitle(subtitle),
        city: _extractCityFromSubtitle(subtitle),
      );
    } catch (e) {
      print('❌ Location Autocomplete: Error converting destination: $e');
      return null;
    }
  }

  /// Format destination type for display
  static String _formatDestinationType(String type) {
    switch (type.toLowerCase()) {
      case 'museum':
        return 'Museum';
      case 'monument':
        return 'Monument';
      case 'park':
        return 'Park';
      case 'religious_site':
        return 'Religious Site';
      case 'entertainment':
        return 'Entertainment';
      case 'cultural':
        return 'Cultural Site';
      case 'attraction':
        return 'Tourist Attraction';
      case 'natural':
        return 'Natural Site';
      default:
        return 'Location';
    }
  }

  /// Extract country from subtitle
  static String? _extractCountryFromSubtitle(String subtitle) {
    if (subtitle.isEmpty) return null;

    final parts = subtitle.split(',');
    if (parts.length >= 2) {
      return parts.last.trim();
    }
    return null;
  }

  /// Extract state from subtitle
  static String? _extractStateFromSubtitle(String subtitle) {
    if (subtitle.isEmpty) return null;

    final parts = subtitle.split(',');
    if (parts.length >= 3) {
      return parts[parts.length - 2].trim();
    } else if (parts.length == 2) {
      return parts.first.trim();
    }
    return null;
  }

  /// Extract city from subtitle
  static String? _extractCityFromSubtitle(String subtitle) {
    if (subtitle.isEmpty) return null;

    final parts = subtitle.split(',');
    if (parts.length >= 2) {
      return parts.first.trim();
    }
    return null;
  }

  /// Clear any pending requests and optionally clear cache
  static void dispose({bool clearCache = false}) {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _currentSearchId = null;

    if (clearCache) {
      _searchCache.clear();
      _cacheTimestamps.clear();
      print('🧹 Location Autocomplete: Cache cleared');
    }
  }

  /// Clear expired cache entries (call periodically)
  static void cleanExpiredCache() {
    _cleanOldCache();
    print('🧹 Location Autocomplete: Expired cache entries cleaned');
  }
}
