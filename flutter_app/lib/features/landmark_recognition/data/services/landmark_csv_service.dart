import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import '../models/landmark_data.dart';

/// Service for loading and parsing the India_Landmarks.csv file
class LandmarkCsvService {
  static final LandmarkCsvService _instance = LandmarkCsvService._internal();
  factory LandmarkCsvService() => _instance;
  LandmarkCsvService._internal();

  List<LandmarkData>? _allLandmarks;
  bool _isLoaded = false;

  /// Load all landmarks from CSV file
  Future<List<LandmarkData>> loadLandmarks() async {
    if (_isLoaded && _allLandmarks != null) {
      return _allLandmarks!;
    }

    try {
      if (kDebugMode) {
        print('📂 Loading India_Landmarks.csv...');
      }

      // Load CSV file from assets as bytes and decode with UTF-8
      final ByteData data = await rootBundle.load('assets/dataset/India_Landmarks.csv');
      final csvString = utf8.decode(
        data.buffer.asUint8List(),
        allowMalformed: true, // Skip invalid UTF-8 sequences
      );
      
      // Parse CSV with allowInvalid to handle malformed data
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
        fieldDelimiter: ',',
        allowInvalid: true, // Allow rows with different column counts
      );

      if (kDebugMode) {
        print('📊 CSV loaded: ${csvData.length} rows');
      }

      // Skip header row and convert to LandmarkData objects
      _allLandmarks = [];
      for (int i = 1; i < csvData.length; i++) {
        try {
          if (csvData[i].length >= 12) {
            final landmark = LandmarkData.fromCsvRow(csvData[i]);
            _allLandmarks!.add(landmark);
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error parsing row $i: $e');
          }
        }
      }

      _isLoaded = true;

      if (kDebugMode) {
        print('✅ Loaded ${_allLandmarks!.length} landmarks');
      }

      return _allLandmarks!;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading landmarks CSV: $e');
      }
      return [];
    }
  }

  /// Get landmarks within radius from a point (using Haversine distance)
  Future<List<LandmarkData>> getLandmarksNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final landmarks = await loadLandmarks();
    
    final nearby = <LandmarkData>[];
    
    for (final landmark in landmarks) {
      final distance = _calculateEuclideanDistance(
        latitude,
        longitude,
        landmark.latitude,
        landmark.longitude,
      );
      
      if (distance <= radiusKm) {
        nearby.add(landmark);
      }
    }

    if (kDebugMode) {
      print('🗺️ Found ${nearby.length} landmarks within ${radiusKm}km');
    }

    return nearby;
  }

  /// Calculate Euclidean distance in kilometers
  /// Approximation for nearby landmarks (faster than Haversine)
  double _calculateEuclideanDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Approximate conversion: 1 degree ≈ 111 km
    // Adjust longitude for latitude
    final avgLat = (lat1 + lat2) / 2;
    final latToKm = 111.0;
    final lonToKm = 111.0 * _cos(avgLat * 3.141592653589793 / 180);
    
    final dLat = (lat2 - lat1) * latToKm;
    final dLon = (lon2 - lon1) * lonToKm;
    
    return _sqrt(dLat * dLat + dLon * dLon);
  }
  
  // Math helper functions for Euclidean distance
  double _cos(double x) {
    // Taylor series approximation for cosine
    double result = 1.0;
    double term = 1.0;
    for (int n = 1; n < 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }
  
  double _sqrt(double x) {
    if (x < 0) return 0;
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// Get landmark by ID
  Future<LandmarkData?> getLandmarkById(int landmarkId) async {
    final landmarks = await loadLandmarks();
    
    try {
      return landmarks.firstWhere((l) => l.landmarkId == landmarkId);
    } catch (e) {
      return null;
    }
  }

  /// Get all landmarks (for debugging)
  Future<List<LandmarkData>> getAllLandmarks() async {
    return await loadLandmarks();
  }
}
