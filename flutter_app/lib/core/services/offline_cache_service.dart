import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/data/models/destination.dart';

/// Service for handling offline caching of destinations and recommendations
class OfflineCacheService {
  static const String _destinationsKey = 'cached_destinations';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _userLocationKey = 'last_user_location';
  static const String _preferencesKey = 'user_preferences_cache';

  /// Cache destinations for offline use
  static Future<void> cacheDestinations(List<Destination> destinations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final destinationsJson = destinations.map((d) => d.toJson()).toList();
      await prefs.setString(_destinationsKey, jsonEncode(destinationsJson));
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      
      print('✅ Cached ${destinations.length} destinations for offline use');
    } catch (e) {
      print('❌ Error caching destinations: $e');
    }
  }

  /// Get cached destinations
  static Future<List<Destination>> getCachedDestinations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_destinationsKey);
      
      if (cachedJson != null) {
        final List<dynamic> destinationsList = jsonDecode(cachedJson);
        return destinationsList
            .map((json) => Destination.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error getting cached destinations: $e');
      return [];
    }
  }

  /// Check if cache is still fresh (less than 24 hours old)
  static Future<bool> isCacheFresh({int maxAgeHours = 24}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey);
      
      if (lastSync == null) return false;
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - lastSync;
      final maxAgeMs = maxAgeHours * 60 * 60 * 1000;
      
      return cacheAge < maxAgeMs;
    } catch (e) {
      return false;
    }
  }

  /// Cache user's last known location
  static Future<void> cacheUserLocation(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userLocationKey, jsonEncode({
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    } catch (e) {
      print('❌ Error caching user location: $e');
    }
  }

  /// Get cached user location
  static Future<Map<String, double>?> getCachedUserLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = prefs.getString(_userLocationKey);
      
      if (locationJson != null) {
        final Map<String, dynamic> location = jsonDecode(locationJson);
        return {
          'lat': location['lat'] as double,
          'lng': location['lng'] as double,
        };
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting cached user location: $e');
      return null;
    }
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_destinationsKey);
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_userLocationKey);
      await prefs.remove(_preferencesKey);
      
      print('✅ Cleared all cached data');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Get cache info for debugging
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = await getCachedDestinations();
      final lastSync = prefs.getInt(_lastSyncKey);
      final isFresh = await isCacheFresh();
      
      return {
        'destinationCount': cached.length,
        'lastSync': lastSync != null 
            ? DateTime.fromMillisecondsSinceEpoch(lastSync).toIso8601String()
            : null,
        'isFresh': isFresh,
        'hasUserLocation': (await getCachedUserLocation()) != null,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
