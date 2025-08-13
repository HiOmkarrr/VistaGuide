import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/home/data/models/destination.dart';

/// Simplified offline storage service without Hive (to avoid blocking initialization)
/// Uses SQLite for structured data and SharedPreferences for simple settings
class SimpleOfflineStorageService {
  static final SimpleOfflineStorageService _instance = 
      SimpleOfflineStorageService._internal();
  factory SimpleOfflineStorageService() => _instance;
  SimpleOfflineStorageService._internal();

  // Database and storage instances
  Database? _database;
  SharedPreferences? _prefs;
  
  bool _initialized = false;

  /// Initialize storage systems (simplified)
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      print('🚀 Initializing Simple Offline Storage...');
      
      // Initialize SQLite
      await _initializeSQLite();
      
      // Initialize SharedPreferences
      await _initializeSharedPreferences();
      
      // Create image cache directory
      await _initializeImageCache();
      
      _initialized = true;
      print('✅ Simple Offline Storage initialized successfully');
      
    } catch (e) {
      print('❌ Failed to initialize Simple Offline Storage: $e');
      // Don't throw - let app continue without offline storage
    }
  }

  /// Initialize SQLite for structured data storage
  Future<void> _initializeSQLite() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'vistaguide_simple.db');
      
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
      );
      
      print('✅ SQLite database initialized');
    } catch (e) {
      print('❌ SQLite initialization failed: $e');
    }
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Simplified destinations table
    await db.execute('''
      CREATE TABLE destinations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT,
        description TEXT,
        image_url TEXT,
        rating REAL,
        type TEXT,
        latitude REAL,
        longitude REAL,
        distance_km REAL,
        tags TEXT,
        cached_at INTEGER NOT NULL,
        source TEXT DEFAULT 'unknown'
      )
    ''');

    // Index for better performance
    await db.execute('CREATE INDEX idx_destinations_location ON destinations(latitude, longitude)');
    await db.execute('CREATE INDEX idx_destinations_cached_at ON destinations(cached_at)');
  }

  /// Initialize SharedPreferences
  Future<void> _initializeSharedPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      print('✅ SharedPreferences initialized');
    } catch (e) {
      print('❌ SharedPreferences initialization failed: $e');
    }
  }

  /// Initialize image cache directory
  Future<void> _initializeImageCache() async {
    try {
      final directory = await _getImageCacheDirectory();
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      print('✅ Image cache directory initialized: ${directory.path}');
    } catch (e) {
      print('❌ Image cache initialization failed: $e');
    }
  }

  /// Get image cache directory
  Future<Directory> _getImageCacheDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return Directory(join(documentsDir.path, 'vistaguide_images'));
  }

  // ==================== DESTINATION STORAGE ====================

  /// Store destinations with simplified offline support
  Future<void> storeDestinations(
    List<Destination> destinations, {
    bool downloadImages = false, // Default false for faster operation
    String source = 'api',
  }) async {
    if (!_initialized || _database == null) {
      print('⚠️ Storage not initialized, skipping destination storage');
      return;
    }
    
    try {
      print('💾 Storing ${destinations.length} destinations...');
      
      final batch = _database!.batch();
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      for (final destination in destinations) {
        batch.insert(
          'destinations',
          {
            'id': destination.id,
            'title': destination.title,
            'subtitle': destination.subtitle,
            'description': destination.description ?? '',
            'image_url': destination.imageUrl ?? '',
            'rating': destination.rating ?? 0.0,
            'type': destination.type,
            'latitude': destination.coordinates?.latitude,
            'longitude': destination.coordinates?.longitude,
            'distance_km': destination.distanceKm,
            'tags': jsonEncode(destination.tags),
            'cached_at': currentTime,
            'source': source,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit();
      print('✅ Stored ${destinations.length} destinations');
      
    } catch (e) {
      print('❌ Failed to store destinations: $e');
    }
  }

  /// Get destinations from offline storage
  Future<List<Destination>> getOfflineDestinations({
    double? nearLatitude,
    double? nearLongitude,
    double? radiusKm,
    List<String>? types,
    int limit = 20,
  }) async {
    if (!_initialized || _database == null) {
      print('⚠️ Storage not initialized, returning empty list');
      return [];
    }
    
    try {
      String query = 'SELECT * FROM destinations WHERE 1=1';
      List<dynamic> args = [];
      
      // Filter by types
      if (types != null && types.isNotEmpty) {
        final placeholders = types.map((_) => '?').join(',');
        query += ' AND type IN ($placeholders)';
        args.addAll(types);
      }
      
      // Filter by location (basic bounding box)
      if (nearLatitude != null && nearLongitude != null && radiusKm != null) {
        final latRange = radiusKm / 111.0; // Rough km to degree conversion
        final lngRange = radiusKm / (111.0 * cos(nearLatitude * pi / 180));
        
        query += '''
          AND latitude BETWEEN ? AND ?
          AND longitude BETWEEN ? AND ?
        ''';
        args.addAll([
          nearLatitude - latRange,
          nearLatitude + latRange,
          nearLongitude - lngRange,
          nearLongitude + lngRange,
        ]);
      }
      
      query += ' ORDER BY cached_at DESC LIMIT ?';
      args.add(limit);
      
      final results = await _database!.rawQuery(query, args);
      
      final destinations = <Destination>[];
      for (final row in results) {
        final destination = _convertRowToDestination(row);
        if (destination != null) {
          destinations.add(destination);
        }
      }
      
      print('📱 Retrieved ${destinations.length} destinations from offline storage');
      return destinations;
      
    } catch (e) {
      print('❌ Failed to get offline destinations: $e');
      return [];
    }
  }

  /// Convert database row to Destination object
  Destination? _convertRowToDestination(Map<String, dynamic> row) {
    try {
      // Parse coordinates
      GeoCoordinates? coordinates;
      if (row['latitude'] != null && row['longitude'] != null) {
        coordinates = GeoCoordinates(
          latitude: row['latitude'],
          longitude: row['longitude'],
        );
      }
      
      return Destination(
        id: row['id'],
        title: row['title'],
        subtitle: row['subtitle'] ?? 'Location',
        description: row['description']?.isEmpty ?? true ? null : row['description'],
        imageUrl: row['image_url']?.isEmpty ?? true ? null : row['image_url'],
        rating: row['rating']?.toDouble(),
        type: row['type'] ?? 'attraction',
        coordinates: coordinates,
        distanceKm: row['distance_km']?.toDouble(),
        tags: List<String>.from(jsonDecode(row['tags'] ?? '[]')),
        images: [], // Simplified - no image list for now
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['cached_at']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['cached_at']),
        isOfflineAvailable: false, // Simplified
      );
      
    } catch (e) {
      print('❌ Failed to convert row to destination: $e');
      return null;
    }
  }

  /// Store user preferences
  Future<void> storeUserPreferences(Map<String, dynamic> preferences) async {
    if (_prefs == null) return;
    
    try {
      await _prefs!.setString('user_preferences', jsonEncode(preferences));
    } catch (e) {
      print('❌ Failed to store preferences: $e');
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    if (_prefs == null) return null;
    
    try {
      final prefsString = _prefs!.getString('user_preferences');
      if (prefsString != null) {
        return jsonDecode(prefsString);
      }
    } catch (e) {
      print('❌ Failed to get preferences: $e');
    }
    
    return null;
  }

  /// Get simple cache statistics
  Future<Map<String, dynamic>> getCacheStatistics() async {
    if (!_initialized || _database == null) {
      return {'error': 'Storage not initialized'};
    }
    
    try {
      final destCount = await _database!.rawQuery('SELECT COUNT(*) as count FROM destinations');
      final destinationCount = destCount.first['count'] as int;
      
      return {
        'destinations': destinationCount,
        'isInitialized': _initialized,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    if (!_initialized || _database == null) return;
    
    try {
      await _database!.delete('destinations');
      await _prefs?.clear();
      print('✅ All cached data cleared');
    } catch (e) {
      print('❌ Failed to clear cache: $e');
    }
  }
}
