import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../features/home/data/models/destination.dart';

/// Comprehensive offline storage service with multi-layered caching
/// Uses SQLite for structured data, Hive for fast key-value pairs, 
/// SharedPreferences for simple settings, and file system for images
class EnhancedOfflineStorageService {
  static final EnhancedOfflineStorageService _instance = 
      EnhancedOfflineStorageService._internal();
  factory EnhancedOfflineStorageService() => _instance;
  EnhancedOfflineStorageService._internal();

  // Database and storage instances
  Database? _database;
  Box<String>? _destinationBox;
  Box<String>? _cacheMetaBox;
  SharedPreferences? _prefs;
  
  // Cache settings
  static const int _maxCacheAgeDays = 7;
  static const int _maxImageCacheMB = 100;
  
  bool _initialized = false;

  /// Initialize all storage systems
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      print('🚀 Initializing Enhanced Offline Storage...');
      
      // Initialize Hive
      await _initializeHive();
      
      // Initialize SQLite
      await _initializeSQLite();
      
      // Initialize SharedPreferences
      await _initializeSharedPreferences();
      
      // Create image cache directory
      await _initializeImageCache();
      
      _initialized = true;
      print('✅ Enhanced Offline Storage initialized successfully');
      
      // Clean up old data
      await _performMaintenanceTasks();
      
    } catch (e) {
      print('❌ Failed to initialize Enhanced Offline Storage: $e');
      throw Exception('Offline storage initialization failed: $e');
    }
  }

  /// Initialize Hive for fast key-value storage
  Future<void> _initializeHive() async {
    await Hive.initFlutter('vistaguide_cache');
    
    // Open boxes
    _destinationBox = await Hive.openBox<String>('destinations');
    _cacheMetaBox = await Hive.openBox<String>('cache_metadata');
    
    print('✅ Hive boxes initialized');
  }

  /// Initialize SQLite for structured data storage
  Future<void> _initializeSQLite() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'vistaguide_offline.db');
    
    _database = await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
    
    print('✅ SQLite database initialized');
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Destinations table
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
        tags TEXT, -- JSON array
        images TEXT, -- JSON array
        historical_info TEXT, -- JSON object
        educational_info TEXT, -- JSON object
        is_favorite INTEGER DEFAULT 0,
        visit_count INTEGER DEFAULT 0,
        last_visited_at INTEGER,
        cached_at INTEGER NOT NULL,
        source TEXT DEFAULT 'unknown',
        is_offline_available INTEGER DEFAULT 0
      )
    ''');

    // User preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        id INTEGER PRIMARY KEY,
        preferred_types TEXT, -- JSON array
        preferred_tags TEXT, -- JSON array
        max_distance REAL DEFAULT 50.0,
        min_rating REAL DEFAULT 3.0,
        language TEXT DEFAULT 'en',
        updated_at INTEGER NOT NULL
      )
    ''');

    // Search history table
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        results_count INTEGER DEFAULT 0,
        searched_at INTEGER NOT NULL
      )
    ''');

    // Cached images table
    await db.execute('''
      CREATE TABLE cached_images (
        url TEXT PRIMARY KEY,
        local_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        cached_at INTEGER NOT NULL,
        last_accessed INTEGER NOT NULL
      )
    ''');

    // Indexes for better performance
    await db.execute('CREATE INDEX idx_destinations_location ON destinations(latitude, longitude)');
    await db.execute('CREATE INDEX idx_destinations_type ON destinations(type)');
    await db.execute('CREATE INDEX idx_destinations_cached_at ON destinations(cached_at)');
    await db.execute('CREATE INDEX idx_cached_images_last_accessed ON cached_images(last_accessed)');
  }

  /// Upgrade database tables
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE destinations ADD COLUMN source TEXT DEFAULT "unknown"');
      await db.execute('ALTER TABLE destinations ADD COLUMN is_offline_available INTEGER DEFAULT 0');
    }
  }

  /// Initialize SharedPreferences
  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    print('✅ SharedPreferences initialized');
  }

  /// Initialize image cache directory
  Future<void> _initializeImageCache() async {
    final directory = await _getImageCacheDirectory();
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    print('✅ Image cache directory initialized: ${directory.path}');
  }

  /// Get image cache directory
  Future<Directory> _getImageCacheDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return Directory(join(documentsDir.path, 'vistaguide_images'));
  }

  // ==================== DESTINATION STORAGE ====================

  /// Store destinations with full offline support
  Future<void> storeDestinations(
    List<Destination> destinations, {
    bool downloadImages = true,
    String source = 'api',
  }) async {
    if (!_initialized) await initialize();
    
    try {
      print('💾 Storing ${destinations.length} destinations offline...');
      
      final batch = _database!.batch();
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      for (final destination in destinations) {
        // Store in SQLite
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
            'images': jsonEncode(destination.images),
            'historical_info': destination.historicalInfo != null 
                ? jsonEncode(destination.historicalInfo!.toJson()) : null,
            'educational_info': destination.educationalInfo != null
                ? jsonEncode(destination.educationalInfo!.toJson()) : null,
            'cached_at': currentTime,
            'source': source,
            'is_offline_available': downloadImages ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        // Store in Hive for fast access
        await _destinationBox!.put(
          destination.id, 
          jsonEncode(destination.toJson())
        );
      }
      
      await batch.commit();
      
      // Download and cache images if requested
      if (downloadImages) {
        await _downloadDestinationImages(destinations);
      }
      
      // Update cache metadata
      await _updateCacheMetadata('destinations', destinations.length, source);
      
      print('✅ Stored ${destinations.length} destinations offline');
      
    } catch (e) {
      print('❌ Failed to store destinations offline: $e');
      throw Exception('Failed to store destinations: $e');
    }
  }

  /// Get destinations from offline storage
  Future<List<Destination>> getOfflineDestinations({
    double? nearLatitude,
    double? nearLongitude,
    double? radiusKm,
    List<String>? types,
    int limit = 20,
    bool onlyOfflineAvailable = false,
  }) async {
    if (!_initialized) await initialize();
    
    try {
      String query = '''
        SELECT * FROM destinations
        WHERE 1=1
      ''';
      
      List<dynamic> args = [];
      
      // Filter by offline availability
      if (onlyOfflineAvailable) {
        query += ' AND is_offline_available = 1';
      }
      
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
        final destination = await _convertRowToDestination(row);
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

  /// Get single destination from cache
  Future<Destination?> getOfflineDestination(String id) async {
    if (!_initialized) await initialize();
    
    try {
      // Try Hive first for speed
      final hiveData = _destinationBox!.get(id);
      if (hiveData != null) {
        final json = jsonDecode(hiveData);
        return Destination.fromJson(json);
      }
      
      // Fallback to SQLite
      final results = await _database!.query(
        'destinations',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        return await _convertRowToDestination(results.first);
      }
      
      return null;
    } catch (e) {
      print('❌ Failed to get offline destination: $e');
      return null;
    }
  }

  /// Convert database row to Destination object
  Future<Destination?> _convertRowToDestination(Map<String, dynamic> row) async {
    try {
      // Parse coordinates
      GeoCoordinates? coordinates;
      if (row['latitude'] != null && row['longitude'] != null) {
        coordinates = GeoCoordinates(
          latitude: row['latitude'],
          longitude: row['longitude'],
        );
      }
      
      // Parse historical info
      HistoricalInfo? historicalInfo;
      if (row['historical_info'] != null) {
        final histData = jsonDecode(row['historical_info']);
        historicalInfo = HistoricalInfo.fromJson(histData);
      }
      
      // Parse educational info
      EducationalInfo? educationalInfo;
      if (row['educational_info'] != null) {
        final eduData = jsonDecode(row['educational_info']);
        educationalInfo = EducationalInfo.fromJson(eduData);
      }
      
      // Get offline image paths
      final images = <String>[];
      final imageUrlsJson = row['images'] ?? '[]';
      final imageUrls = List<String>.from(jsonDecode(imageUrlsJson));
      
      for (final url in imageUrls) {
        final localPath = await _getLocalImagePath(url);
        if (localPath != null) {
          images.add(localPath);
        } else {
          images.add(url); // Fallback to URL
        }
      }
      
      return Destination(
        id: row['id'],
        title: row['title'],
        subtitle: row['subtitle']?.isEmpty ?? true ? null : row['subtitle'],
        description: row['description']?.isEmpty ?? true ? null : row['description'],
        imageUrl: images.isNotEmpty ? images.first : 
                 (row['image_url']?.isEmpty ?? true ? null : row['image_url']),
        rating: row['rating']?.toDouble(),
        type: row['type'] ?? 'attraction',
        coordinates: coordinates,
        distanceKm: row['distance_km']?.toDouble(),
        tags: List<String>.from(jsonDecode(row['tags'] ?? '[]')),
        images: images,
        historicalInfo: historicalInfo,
        educationalInfo: educationalInfo,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['cached_at']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['cached_at']),
        isOfflineAvailable: (row['is_offline_available'] ?? 0) == 1,
      );
      
    } catch (e) {
      print('❌ Failed to convert row to destination: $e');
      return null;
    }
  }

  // ==================== IMAGE CACHING ====================

  /// Download and cache images for destinations
  Future<void> _downloadDestinationImages(List<Destination> destinations) async {
    print('🖼️ Downloading images for ${destinations.length} destinations...');
    
    int downloaded = 0;
    for (final destination in destinations) {
      final imageUrls = [
        if (destination.imageUrl != null) destination.imageUrl!,
        ...destination.images,
      ];
      
      for (final url in imageUrls) {
        if (await _downloadAndCacheImage(url)) {
          downloaded++;
        }
      }
    }
    
    print('✅ Downloaded $downloaded images');
  }

  /// Download and cache a single image
  Future<bool> _downloadAndCacheImage(String url) async {
    try {
      // Check if already cached
      final existingPath = await _getLocalImagePath(url);
      if (existingPath != null && File(existingPath).existsSync()) {
        // Update last accessed time
        await _updateImageAccessTime(url);
        return true;
      }
      
      // Download image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final filename = _generateImageFilename(url);
        final directory = await _getImageCacheDirectory();
        final file = File(join(directory.path, filename));
        
        await file.writeAsBytes(response.bodyBytes);
        
        // Store in database
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        await _database!.insert(
          'cached_images',
          {
            'url': url,
            'local_path': file.path,
            'file_size': response.bodyBytes.length,
            'cached_at': currentTime,
            'last_accessed': currentTime,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('⚠️ Failed to download image $url: $e');
      return false;
    }
  }

  /// Get local path for cached image
  Future<String?> _getLocalImagePath(String url) async {
    try {
      final results = await _database!.query(
        'cached_images',
        columns: ['local_path'],
        where: 'url = ?',
        whereArgs: [url],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        final path = results.first['local_path'] as String;
        if (File(path).existsSync()) {
          return path;
        } else {
          // File doesn't exist, remove from database
          await _database!.delete('cached_images', where: 'url = ?', whereArgs: [url]);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generate filename for cached image
  String _generateImageFilename(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    final filename = pathSegments.isNotEmpty ? pathSegments.last : 'image';
    
    // Create hash of URL for uniqueness
    final hash = url.hashCode.abs().toString();
    final extension = filename.contains('.') ? 
        filename.split('.').last : 'jpg';
    
    return '${hash}_$filename.$extension';
  }

  /// Update image last accessed time
  Future<void> _updateImageAccessTime(String url) async {
    await _database!.update(
      'cached_images',
      {'last_accessed': DateTime.now().millisecondsSinceEpoch},
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  // ==================== USER PREFERENCES ====================

  /// Store user preferences
  Future<void> storeUserPreferences(Map<String, dynamic> preferences) async {
    if (!_initialized) await initialize();
    
    await _prefs!.setString('user_preferences', jsonEncode(preferences));
    
    // Also store in SQLite for complex queries
    await _database!.insert(
      'user_preferences',
      {
        'id': 1, // Single row for user preferences
        'preferred_types': jsonEncode(preferences['preferredTypes'] ?? []),
        'preferred_tags': jsonEncode(preferences['preferredTags'] ?? []),
        'max_distance': preferences['maxDistance'] ?? 50.0,
        'min_rating': preferences['minRating'] ?? 3.0,
        'language': preferences['language'] ?? 'en',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    if (!_initialized) await initialize();
    
    final prefsString = _prefs!.getString('user_preferences');
    if (prefsString != null) {
      return jsonDecode(prefsString);
    }
    
    return null;
  }

  // ==================== MAINTENANCE ====================

  /// Perform maintenance tasks
  Future<void> _performMaintenanceTasks() async {
    print('🧹 Performing offline storage maintenance...');
    
    await _cleanupOldDestinations();
    await _cleanupOldImages();
    await _optimizeDatabase();
    
    print('✅ Maintenance tasks completed');
  }

  /// Cleanup old cached destinations
  Future<void> _cleanupOldDestinations() async {
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: _maxCacheAgeDays))
        .millisecondsSinceEpoch;
    
    final deletedCount = await _database!.delete(
      'destinations',
      where: 'cached_at < ?',
      whereArgs: [cutoffTime],
    );
    
    if (deletedCount > 0) {
      print('🗑️ Cleaned up $deletedCount old destinations');
    }
  }

  /// Cleanup old cached images
  Future<void> _cleanupOldImages() async {
    try {
      // Get cache size
      final cacheDir = await _getImageCacheDirectory();
      int totalSize = 0;
      final files = <FileSystemEntity>[];
      
      if (cacheDir.existsSync()) {
        files.addAll(cacheDir.listSync());
        for (final file in files) {
          if (file is File) {
            totalSize += file.lengthSync();
          }
        }
      }
      
      final sizeMB = totalSize / (1024 * 1024);
      
      if (sizeMB > _maxImageCacheMB) {
        print('🧹 Image cache size: ${sizeMB.toStringAsFixed(1)}MB, cleaning up...');
        
        // Get oldest accessed images
        final oldImages = await _database!.query(
          'cached_images',
          orderBy: 'last_accessed ASC',
          limit: (files.length * 0.3).round(), // Remove 30% of oldest images
        );
        
        int deletedCount = 0;
        for (final row in oldImages) {
          final path = row['local_path'] as String;
          final file = File(path);
          
          if (file.existsSync()) {
            await file.delete();
            deletedCount++;
          }
          
          // Remove from database
          await _database!.delete(
            'cached_images',
            where: 'url = ?',
            whereArgs: [row['url']],
          );
        }
        
        print('🗑️ Cleaned up $deletedCount cached images');
      }
    } catch (e) {
      print('⚠️ Failed to cleanup images: $e');
    }
  }

  /// Optimize database
  Future<void> _optimizeDatabase() async {
    await _database!.execute('VACUUM');
    await _database!.execute('ANALYZE');
  }

  /// Update cache metadata
  Future<void> _updateCacheMetadata(String type, int count, String source) async {
    final metadata = {
      'type': type,
      'count': count,
      'source': source,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await _cacheMetaBox!.put(type, jsonEncode(metadata));
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStatistics() async {
    if (!_initialized) await initialize();
    
    try {
      // Destination count
      final destCount = await _database!.rawQuery('SELECT COUNT(*) as count FROM destinations');
      final destinationCount = destCount.first['count'] as int;
      
      // Image count and size
      final imgCount = await _database!.rawQuery('SELECT COUNT(*) as count, SUM(file_size) as size FROM cached_images');
      final imageCount = imgCount.first['count'] as int;
      final imageSize = imgCount.first['size'] as int? ?? 0;
      
      // Cache age
      final oldestDest = await _database!.rawQuery('SELECT MIN(cached_at) as oldest FROM destinations');
      final oldestTime = oldestDest.first['oldest'] as int?;
      
      return {
        'destinations': destinationCount,
        'images': imageCount,
        'imageSizeMB': (imageSize / (1024 * 1024)).toStringAsFixed(2),
        'oldestCacheAge': oldestTime != null ? 
            DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(oldestTime)).inDays : 0,
        'isInitialized': _initialized,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    if (!_initialized) await initialize();
    
    try {
      // Clear database tables
      await _database!.delete('destinations');
      await _database!.delete('cached_images');
      await _database!.delete('search_history');
      
      // Clear Hive boxes
      await _destinationBox!.clear();
      await _cacheMetaBox!.clear();
      
      // Clear SharedPreferences
      await _prefs!.clear();
      
      // Clear image cache directory
      final cacheDir = await _getImageCacheDirectory();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
      
      print('✅ All cached data cleared');
    } catch (e) {
      print('❌ Failed to clear cache: $e');
      throw Exception('Failed to clear cache: $e');
    }
  }
}
