import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/journey.dart';
import '../models/journey_details_data.dart';

/// Repository for journey persistence using SQLite
class JourneyRepository {
  static final JourneyRepository _instance = JourneyRepository._internal();
  factory JourneyRepository() => _instance;
  JourneyRepository._internal();

  static const String _databaseName = 'vistaguide_journeys.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _journeysTable = 'journeys';
  static const String _journeyDetailsTable = 'journey_details';

  Database? _database;

  /// Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with tables
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Create journeys table
    await db.execute('''
      CREATE TABLE $_journeysTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        is_completed INTEGER NOT NULL,
        destinations TEXT NOT NULL,
        image_url TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    // Create journey details table
    await db.execute('''
      CREATE TABLE $_journeyDetailsTable (
        journey_id TEXT PRIMARY KEY,
        weather_type TEXT NOT NULL,
        weather_temperature TEXT NOT NULL,
        weather_best_time TEXT NOT NULL,
        what_to_bring TEXT NOT NULL,
        safety_notes TEXT NOT NULL,
        emergency_medical TEXT NOT NULL,
        emergency_police TEXT NOT NULL,
        places_events TEXT NOT NULL,
        packing_checklist TEXT NOT NULL,
        FOREIGN KEY (journey_id) REFERENCES $_journeysTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indices for better performance
    await db.execute('CREATE INDEX idx_journeys_created_at ON $_journeysTable(created_at DESC)');
    await db.execute('CREATE INDEX idx_journeys_is_completed ON $_journeysTable(is_completed)');
    await db.execute('CREATE INDEX idx_journeys_start_date ON $_journeysTable(start_date)');
  }

  // ==================== JOURNEY CRUD OPERATIONS ====================

  /// Insert a journey
  Future<void> insertJourney(Journey journey) async {
    final db = await database;
    try {
      await db.insert(
        _journeysTable,
        journey.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Journey saved to database: ${journey.title}');
    } catch (e) {
      print('❌ Failed to insert journey: $e');
      throw Exception('Failed to save journey: $e');
    }
  }

  /// Get all journeys
  Future<List<Journey>> getAllJourneys() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _journeysTable,
        orderBy: 'created_at DESC',
      );

      final journeys = <Journey>[];
      for (final map in maps) {
        final journey = Journey.fromMap(map);
        
        // Load journey details if they exist
        final details = await getJourneyDetails(journey.id);
        if (details != null) {
          journeys.add(journey.copyWith(journeyDetails: details));
        } else {
          journeys.add(journey);
        }
      }

      print('✅ Loaded ${journeys.length} journeys from database');
      return journeys;
    } catch (e) {
      print('❌ Failed to load journeys: $e');
      return [];
    }
  }

  /// Get journey by ID
  Future<Journey?> getJourneyById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _journeysTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;

      final journey = Journey.fromMap(maps.first);
      final details = await getJourneyDetails(id);
      
      return details != null 
          ? journey.copyWith(journeyDetails: details)
          : journey;
    } catch (e) {
      print('❌ Failed to get journey by ID: $e');
      return null;
    }
  }

  /// Update a journey
  Future<void> updateJourney(Journey journey) async {
    final db = await database;
    try {
      await db.update(
        _journeysTable,
        journey.toMap(),
        where: 'id = ?',
        whereArgs: [journey.id],
      );
      print('✅ Journey updated: ${journey.title}');
    } catch (e) {
      print('❌ Failed to update journey: $e');
      throw Exception('Failed to update journey: $e');
    }
  }

  /// Delete a journey
  Future<void> deleteJourney(String journeyId) async {
    final db = await database;
    try {
      // Delete journey details first (foreign key constraint)
      await db.delete(
        _journeyDetailsTable,
        where: 'journey_id = ?',
        whereArgs: [journeyId],
      );

      // Delete journey
      await db.delete(
        _journeysTable,
        where: 'id = ?',
        whereArgs: [journeyId],
      );
      print('✅ Journey deleted: $journeyId');
    } catch (e) {
      print('❌ Failed to delete journey: $e');
      throw Exception('Failed to delete journey: $e');
    }
  }

  // ==================== JOURNEY DETAILS OPERATIONS ====================

  /// Insert or update journey details
  Future<void> saveJourneyDetails(String journeyId, JourneyDetailsData details) async {
    final db = await database;
    try {
      await db.insert(
        _journeyDetailsTable,
        details.toMap(journeyId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Journey details saved for: $journeyId');
    } catch (e) {
      print('❌ Failed to save journey details: $e');
      throw Exception('Failed to save journey details: $e');
    }
  }

  /// Get journey details by journey ID
  Future<JourneyDetailsData?> getJourneyDetails(String journeyId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _journeyDetailsTable,
        where: 'journey_id = ?',
        whereArgs: [journeyId],
      );

      if (maps.isEmpty) return null;

      return JourneyDetailsData.fromMap(maps.first);
    } catch (e) {
      print('❌ Failed to get journey details: $e');
      return null;
    }
  }

  /// Delete journey details
  Future<void> deleteJourneyDetails(String journeyId) async {
    final db = await database;
    try {
      await db.delete(
        _journeyDetailsTable,
        where: 'journey_id = ?',
        whereArgs: [journeyId],
      );
      print('✅ Journey details deleted for: $journeyId');
    } catch (e) {
      print('❌ Failed to delete journey details: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get filtered journeys
  Future<List<Journey>> getJourneysFiltered({
    bool? isCompleted,
    DateTime? startDateAfter,
    DateTime? startDateBefore,
    int limit = 100,
  }) async {
    try {
      final db = await database;
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (isCompleted != null) {
        whereClause += ' AND is_completed = ?';
        whereArgs.add(isCompleted ? 1 : 0);
      }

      if (startDateAfter != null) {
        whereClause += ' AND start_date > ?';
        whereArgs.add(startDateAfter.millisecondsSinceEpoch);
      }

      if (startDateBefore != null) {
        whereClause += ' AND start_date < ?';
        whereArgs.add(startDateBefore.millisecondsSinceEpoch);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _journeysTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      final journeys = <Journey>[];
      for (final map in maps) {
        final journey = Journey.fromMap(map);
        final details = await getJourneyDetails(journey.id);
        if (details != null) {
          journeys.add(journey.copyWith(journeyDetails: details));
        } else {
          journeys.add(journey);
        }
      }

      return journeys;
    } catch (e) {
      print('❌ Failed to get filtered journeys: $e');
      return [];
    }
  }

  /// Clear all journeys (for testing/debugging)
  Future<void> clearAllJourneys() async {
    final db = await database;
    try {
      await db.delete(_journeyDetailsTable);
      await db.delete(_journeysTable);
      print('✅ All journeys cleared from database');
    } catch (e) {
      print('❌ Failed to clear journeys: $e');
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
