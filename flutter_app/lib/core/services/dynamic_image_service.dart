import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service to dynamically fetch destination images from multiple sources
class DynamicImageService {
  static final DynamicImageService _instance = DynamicImageService._internal();
  factory DynamicImageService() => _instance;
  DynamicImageService._internal();

  // Cache for image URLs to avoid repeated API calls
  static final Map<String, String> _imageCache = {};
  static const Duration _cacheDuration = Duration(hours: 24);
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Get image URL for a destination
  /// Priority: 1. Firestore imageUrl, 2. Firestore images array, 3. Unsplash API
  Future<String?> getDestinationImageUrl({
    required String destinationId,
    required String destinationName,
    String? firestoreImageUrl,
    List<String>? firestoreImages,
    String destinationType = 'landmark',
  }) async {
    // Check cache first
    if (_imageCache.containsKey(destinationId)) {
      final cacheTime = _cacheTimestamps[destinationId];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheDuration) {
        debugPrint('📸 Using cached image for $destinationName');
        return _imageCache[destinationId];
      }
    }

    // Priority 1: Use Firestore imageUrl if available
    if (firestoreImageUrl != null && firestoreImageUrl.isNotEmpty) {
      debugPrint('📸 Using Firestore imageUrl for $destinationName');
      _cacheImage(destinationId, firestoreImageUrl);
      return firestoreImageUrl;
    }

    // Priority 2: Use first image from Firestore images array
    if (firestoreImages != null && firestoreImages.isNotEmpty) {
      final imageUrl = firestoreImages.first;
      debugPrint('📸 Using Firestore images array for $destinationName');
      _cacheImage(destinationId, imageUrl);
      return imageUrl;
    }

    // Priority 3: Fetch from Unsplash API (free, no API key required for basic usage)
    try {
      final unsplashUrl = await _fetchUnsplashImage(
        query: '$destinationName $destinationType India',
        destinationId: destinationId,
      );
      if (unsplashUrl != null) {
        return unsplashUrl;
      }
    } catch (e) {
      debugPrint('⚠️ Unsplash API failed for $destinationName: $e');
    }

    // Priority 4: Try Pexels API (alternative free source)
    try {
      final pexelsUrl = await _fetchPexelsImage(
        query: '$destinationName India',
        destinationId: destinationId,
      );
      if (pexelsUrl != null) {
        return pexelsUrl;
      }
    } catch (e) {
      debugPrint('⚠️ Pexels API failed for $destinationName: $e');
    }

    debugPrint('❌ No image source available for $destinationName');
    return null;
  }

  /// Fetch image from Unsplash API
  Future<String?> _fetchUnsplashImage({
    required String query,
    required String destinationId,
  }) async {
    try {
      // Using Unsplash Source API (no API key needed, but limited)
      // For production, get a free API key from https://unsplash.com/developers
      
      // Method 1: Direct source URL (simple but less control)
      final searchQuery = Uri.encodeComponent(query);
      final sourceUrl = 'https://source.unsplash.com/800x600/?$searchQuery';
      
      debugPrint('📸 Fetching from Unsplash: $query');
      
      // Verify the URL is accessible
      final response = await http.head(Uri.parse(sourceUrl))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        _cacheImage(destinationId, sourceUrl);
        debugPrint('✅ Unsplash image found for $query');
        return sourceUrl;
      }
    } catch (e) {
      debugPrint('⚠️ Unsplash fetch error: $e');
    }
    return null;
  }

  /// Fetch image from Pexels API
  Future<String?> _fetchPexelsImage({
    required String query,
    required String destinationId,
  }) async {
    try {
      // For Pexels, you need a free API key from https://www.pexels.com/api/
      // Get your free key and add to .env file as PEXELS_API_KEY=your_key_here
      final pexelsApiKey = dotenv.env['PEXELS_API_KEY'] ?? '';
      
      if (pexelsApiKey.isEmpty) {
        debugPrint('⚠️ Pexels API key not configured - skipping');
        return null; // Skip if API key not configured
      }

      final searchQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
          'https://api.pexels.com/v1/search?query=$searchQuery&per_page=1&orientation=landscape');

      final response = await http.get(
        url,
        headers: {'Authorization': pexelsApiKey},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['photos'] != null && (data['photos'] as List).isNotEmpty) {
          final imageUrl = data['photos'][0]['src']['large'] as String;
          _cacheImage(destinationId, imageUrl);
          debugPrint('✅ Pexels image found for $query');
          return imageUrl;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Pexels fetch error: $e');
    }
    return null;
  }

  /// Cache image URL
  void _cacheImage(String destinationId, String imageUrl) {
    _imageCache[destinationId] = imageUrl;
    _cacheTimestamps[destinationId] = DateTime.now();
  }

  /// Clear cache
  void clearCache() {
    _imageCache.clear();
    _cacheTimestamps.clear();
    debugPrint('🗑️ Image cache cleared');
  }

  /// Get cached image URL
  String? getCachedImageUrl(String destinationId) {
    if (_imageCache.containsKey(destinationId)) {
      final cacheTime = _cacheTimestamps[destinationId];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheDuration) {
        return _imageCache[destinationId];
      }
    }
    return null;
  }

  /// Preload images for a list of destinations
  Future<void> preloadDestinationImages({
    required List<Map<String, dynamic>> destinations,
  }) async {
    debugPrint('📸 Preloading ${destinations.length} destination images...');
    
    for (final dest in destinations) {
      try {
        await getDestinationImageUrl(
          destinationId: dest['id'] as String,
          destinationName: dest['name'] as String,
          firestoreImageUrl: dest['imageUrl'] as String?,
          firestoreImages: (dest['images'] as List<dynamic>?)?.cast<String>(),
          destinationType: dest['type'] as String? ?? 'landmark',
        );
      } catch (e) {
        debugPrint('⚠️ Error preloading image for ${dest['name']}: $e');
      }
    }
    
    debugPrint('✅ Image preloading complete');
  }
}
