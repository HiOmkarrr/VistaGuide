import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Service to cache user location at regular intervals for emergency situations
class LocationCacheService {
  static final LocationCacheService _instance = LocationCacheService._internal();
  factory LocationCacheService() => _instance;
  LocationCacheService._internal();

  final Location _location = Location();
  final Battery _battery = Battery();
  Timer? _cacheTimer;
  bool _isActive = false;
  Database? _database;

  static const String _locationCacheKey = 'cached_location';
  static const String _lastUpdateKey = 'last_location_update';
  static const Duration _cacheInterval = Duration(minutes: 5);

  /// Initialize the location caching service
  Future<void> initialize() async {
    await _initializeDatabase();
    debugPrint('📍 Location Cache Service initialized');
  }

  /// Initialize SQLite database for location history
  Future<void> _initializeDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'emergency_cache.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE location_cache (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              accuracy REAL,
              battery_level INTEGER,
              address TEXT,
              timestamp INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE INDEX idx_location_timestamp ON location_cache(timestamp)
          ''');
        },
      );

      debugPrint('📍 Location cache database initialized');
    } catch (e) {
      debugPrint('❌ Error initializing location cache database: $e');
    }
  }

  /// Start location caching service
  Future<void> startLocationCaching() async {
    if (_isActive) return;

    _isActive = true;
    debugPrint('📍 Starting location caching service');

    // Cache location immediately on startup
    await _cacheCurrentLocation();

    // Start periodic caching
    _cacheTimer = Timer.periodic(_cacheInterval, (timer) {
      _cacheCurrentLocation();
    });
  }

  /// Stop location caching service
  void stopLocationCaching() {
    _isActive = false;
    _cacheTimer?.cancel();
    _cacheTimer = null;
    debugPrint('📍 Location caching service stopped');
  }

  /// Cache current location with timestamp and battery info
  Future<void> _cacheCurrentLocation() async {
    if (!_isActive) return;

    try {
      // Check location permissions
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          debugPrint('⚠️ Location service not enabled');
          return;
        }
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          debugPrint('⚠️ Location permission not granted');
          return;
        }
      }

      // Get current location with timeout
      final locationData = await _location.getLocation().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location timeout'),
      );

      if (locationData.latitude == null || locationData.longitude == null) {
        debugPrint('⚠️ Location data incomplete');
        return;
      }

      // Get battery level
      final batteryLevel = await _battery.batteryLevel;

      // Get address (simplified for now)
      final address = await _getAddressFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Store in SQLite for history
      if (_database != null) {
        await _database!.insert('location_cache', {
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'accuracy': locationData.accuracy,
          'battery_level': batteryLevel,
          'address': address,
          'timestamp': timestamp,
        });

        // Keep only last 50 location entries
        await _cleanOldLocationEntries();
      }

      // Store latest in SharedPreferences for quick access
      final cachedLocation = {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'accuracy': locationData.accuracy,
        'timestamp': timestamp,
        'battery': batteryLevel,
        'address': address,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_locationCacheKey, json.encode(cachedLocation));
      await prefs.setString(_lastUpdateKey, timestamp.toString());

      debugPrint('📍 Location cached: ${locationData.latitude}, ${locationData.longitude} (Battery: $batteryLevel%)');
    } catch (e) {
      debugPrint('❌ Error caching location: $e');
    }
  }

  /// Clean old location entries (keep only last 50)
  Future<void> _cleanOldLocationEntries() async {
    if (_database == null) return;

    try {
      final count = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM location_cache'),
      );

      if (count != null && count > 50) {
        await _database!.rawDelete('''
          DELETE FROM location_cache 
          WHERE id NOT IN (
            SELECT id FROM location_cache 
            ORDER BY timestamp DESC 
            LIMIT 50
          )
        ''');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning old location entries: $e');
    }
  }

  /// Get the most recent cached location from SharedPreferences
  Future<Map<String, dynamic>?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_locationCacheKey);
      
      if (cachedData != null) {
        return json.decode(cachedData) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('❌ Error retrieving cached location: $e');
    }
    return null;
  }

  /// Get the best available location (current or cached)
  Future<Map<String, dynamic>?> getBestAvailableLocation() async {
    try {
      debugPrint('📍 Getting best available location...');

      // Try to get current location first
      bool serviceEnabled = await _location.serviceEnabled();
      if (serviceEnabled) {
        PermissionStatus permission = await _location.hasPermission();
        if (permission == PermissionStatus.granted) {
          try {
            final locationData = await _location.getLocation().timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Location timeout'),
            );
            
            if (locationData.latitude != null && locationData.longitude != null) {
              final batteryLevel = await _battery.batteryLevel;
              final address = await _getAddressFromCoordinates(
                locationData.latitude!,
                locationData.longitude!,
              );

              debugPrint('📍 Got current location');
              return {
                'latitude': locationData.latitude,
                'longitude': locationData.longitude,
                'accuracy': locationData.accuracy,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'battery': batteryLevel,
                'address': address,
                'source': 'current'
              };
            }
          } catch (e) {
            debugPrint('⚠️ Current location failed: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not get current location, falling back to cached: $e');
    }

    // Fallback to cached location
    final cached = await getCachedLocation();
    if (cached != null) {
      cached['source'] = 'cached';
      debugPrint('📍 Using cached location');
      return cached;
    }

    debugPrint('❌ No location available');
    return null;
  }

  /// Get formatted address from coordinates (simplified)
  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    // For now, return coordinates as address
    // In production, you could use geocoding service here
    return 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
  }

  /// Check if cached location is recent (within last 30 minutes)
  Future<bool> isCachedLocationRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      
      if (lastUpdateStr != null) {
        final lastUpdate = DateTime.fromMillisecondsSinceEpoch(
          int.parse(lastUpdateStr),
        );
        final timeDiff = DateTime.now().difference(lastUpdate);
        return timeDiff.inMinutes < 30;
      }
    } catch (e) {
      debugPrint('❌ Error checking cached location age: $e');
    }
    return false;
  }

  /// Get location history from SQLite
  Future<List<Map<String, dynamic>>> getLocationHistory({int limit = 20}) async {
    if (_database == null) return [];

    try {
      final results = await _database!.query(
        'location_cache',
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      return results;
    } catch (e) {
      debugPrint('❌ Error getting location history: $e');
      return [];
    }
  }

  /// Clear cached location data
  Future<void> clearCache() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_locationCacheKey);
      await prefs.remove(_lastUpdateKey);

      // Clear SQLite
      if (_database != null) {
        await _database!.delete('location_cache');
      }

      debugPrint('📍 Location cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing location cache: $e');
    }
  }

  /// Get cache status information
  Future<Map<String, dynamic>> getCacheStatus() async {
    final cached = await getCachedLocation();
    final isRecent = await isCachedLocationRecent();
    
    return {
      'hasCache': cached != null,
      'isRecent': isRecent,
      'lastUpdate': cached?['timestamp'],
      'isActive': _isActive,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    stopLocationCaching();
    await _database?.close();
    _database = null;
  }
}
