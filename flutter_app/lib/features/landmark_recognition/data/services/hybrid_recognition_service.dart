import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart' as loc;
import '../models/landmark_data.dart';
import '../utils/distance_calculator.dart';
import 'landmark_csv_service.dart';
import 'image_embedding_service.dart';
import 'llm_service.dart';
import '../../../profile/data/services/preferences_service.dart';

/// Result of landmark recognition with scores
class RecognitionResult {
  final int? landmarkId;
  final String landmarkName;
  final String landmarkInfo;
  final double confidenceScore;
  final double? visualScore;
  final double? gpsScore;
  final bool bonusApplied;
  final bool success;

  RecognitionResult({
    this.landmarkId,
    required this.landmarkName,
    required this.landmarkInfo,
    required this.confidenceScore,
    this.visualScore,
    this.gpsScore,
    required this.bonusApplied,
    required this.success,
  });
}

/// Main hybrid landmark recognition service
/// Combines GPS-based and image-based recognition
class HybridLandmarkRecognitionService {
  static final HybridLandmarkRecognitionService _instance =
      HybridLandmarkRecognitionService._internal();
  factory HybridLandmarkRecognitionService() => _instance;
  HybridLandmarkRecognitionService._internal();

  final LandmarkCsvService _csvService = LandmarkCsvService();
  final ImageEmbeddingService _embeddingService = ImageEmbeddingService();
  final LlmService _llmService = LlmService();
  
  // Cache for nearby landmarks
  List<LandmarkData> _cachedNearbyLandmarks = [];
  DateTime? _lastCacheUpdate;
  
  // Recognition weights - Balanced for GPS + Visual
  // When GPS is strong (nearby landmark), it should have significant influence
  static const double alpha = 0.4;  // Visual score weight
  static const double beta = 0.3;   // GPS score weight
  static const double gamma = 8;   // GPS score hyperparameter
  static const double bonus = 0.3;  // Bonus when both match
  
  // Stricter thresholds for better accuracy
  static const double confidenceThreshold = 0.7;  // Overall confidence (lowered for GPS-heavy scenarios)
  static const double visualScoreThreshold = 0.6;  // Visual-only threshold
  static const double minCosineSimilarity = 0.2;  // Minimum raw similarity (lowered for better matching)
  static const double nearbyRadius = 10.0;         // Initial search radius (km)
  static const double expandedRadius = 20.0;       // Fallback radius (km)

  Map<int, List<double>>? _prototypes;

  /// Initialize the service
  Future<bool> initialize() async {
    try {
      if (kDebugMode) {
        print('🚀 Initializing hybrid landmark recognition service...');
      }

      // Load CSV data
      if (kDebugMode) print('📋 Loading CSV landmarks...');
      await _csvService.loadLandmarks();
      if (kDebugMode) print('✅ CSV loaded');
      
      // Load embedding model
      if (kDebugMode) print('🧠 Loading embedding model...');
      final embeddingLoaded = await _embeddingService.initializeModel();
      if (!embeddingLoaded) {
        if (kDebugMode) print('❌ CRITICAL: Embedding model failed to load!');
        return false;
      }
      if (kDebugMode) print('✅ Embedding model loaded');
      
      // Load prototypes
      if (kDebugMode) print('📦 Loading prototypes...');
      await _loadPrototypes();
      if (_prototypes == null || _prototypes!.isEmpty) {
        if (kDebugMode) print('❌ CRITICAL: Prototypes failed to load!');
        return false;
      }
      if (kDebugMode) print('✅ Prototypes loaded: ${_prototypes!.length} landmarks');

      // Load LLM model (optional - may fail due to size)
      try {
        await _llmService.initializeModel();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ LLM model not loaded (optional): $e');
        }
      }

      if (kDebugMode) {
        print('✅ Hybrid recognition service initialized');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing hybrid service: $e');
      }
      return false;
    }
  }

  /// Load prototypes.json file
  Future<void> _loadPrototypes() async {
    try {
      final jsonString = await rootBundle.loadString('assets/models/prototypes.json');
      final dynamic data = json.decode(jsonString);
      
      _prototypes = {};
      
      // Handle two possible formats:
      // Format 1: Map {"landmark_id": [vector], ...}
      // Format 2: Array [{"landmark_id": "id", "embedding": [vector], ...}, ...]
      
      if (data is Map<String, dynamic>) {
        // Format 1: Simple map
        data.forEach((key, value) {
          final landmarkId = int.tryParse(key);
          if (landmarkId != null && value is List) {
            _prototypes![landmarkId] = List<double>.from(value);
          }
        });
      } else if (data is List) {
        // Format 2: Array of objects (your actual format)
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final landmarkIdStr = item['landmark_id']?.toString();
            final embedding = item['embedding'];
            
            if (landmarkIdStr != null && embedding is List) {
              final landmarkId = int.tryParse(landmarkIdStr);
              if (landmarkId != null) {
                // Store embedding with landmark_id as key
                // If multiple prototypes per landmark, we'll use the first one
                // or average them later if needed
                if (!_prototypes!.containsKey(landmarkId)) {
                  _prototypes![landmarkId] = List<double>.from(embedding);
                }
              }
            }
          }
        }
      }

      if (_prototypes!.isEmpty) {
        if (kDebugMode) {
          print('⚠️ WARNING: prototypes.json is empty or invalid format!');
          print('💡 Visual recognition will be disabled until prototypes are fixed.');
        }
      } else {
        if (kDebugMode) {
          print('✅ Loaded ${_prototypes!.length} landmark prototypes');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading prototypes: $e');
        print('⚠️ Visual recognition will be disabled');
      }
      _prototypes = {};
    }
  }

  /// Update cache of nearby landmarks (should be called every 2 minutes in background)
  Future<void> updateNearbyCache() async {
    try {
      // Get user's preferred radius
      final preferencesService = PreferencesService();
      final userRadius = await preferencesService.getLandmarkRecognitionRadius();
      final expandedUserRadius = userRadius * 2; // Double the radius for fallback
      
      if (kDebugMode) {
        print('📍 Using user-defined search radius: $userRadius km');
      }
      
      // Get current location
      final location = loc.Location();
      final hasPermission = await location.hasPermission();
      
      if (hasPermission == loc.PermissionStatus.denied) {
        if (kDebugMode) {
          print('⚠️ Location permission denied');
        }
        return;
      }

      final locationData = await location.getLocation();
      
      if (locationData.latitude == null || locationData.longitude == null) {
        if (kDebugMode) {
          print('⚠️ Could not get location');
        }
        return;
      }

      // Get landmarks within user's preferred radius
      _cachedNearbyLandmarks = await _csvService.getLandmarksNearby(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        radiusKm: userRadius,
      );

      // If no landmarks found within initial radius, expand search
      if (_cachedNearbyLandmarks.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No landmarks within ${userRadius}km, expanding to ${expandedUserRadius}km...');
        }
        _cachedNearbyLandmarks = await _csvService.getLandmarksNearby(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
          radiusKm: expandedUserRadius,
        );
      }

      _lastCacheUpdate = DateTime.now();

      if (kDebugMode) {
        print('✅ Cache updated: ${_cachedNearbyLandmarks.length} nearby landmarks');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating cache: $e');
      }
    }
  }

  /// Perform full hybrid recognition
  Future<RecognitionResult> recognizeLandmark(File imageFile) async {
    try {
      if (kDebugMode) {
        print('🔍 Starting hybrid landmark recognition...');
      }

      // Step 1: GPS-based recognition
      final gpsResult = await _gpsBasedRecognition();
      
      // Step 2: Image-based recognition
      final visualResult = await _imageBasedRecognition(imageFile);

      // Step 3: Calculate combined confidence score
      final result = _calculateFinalScore(gpsResult, visualResult);

      // Step 4: Process result based on confidence and thresholds
      return await _processRecognitionResult(result);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during recognition: $e');
      }
      return RecognitionResult(
        landmarkName: 'Error',
        landmarkInfo: 'Recognition failed',
        confidenceScore: 0.0,
        bonusApplied: false,
        success: false,
      );
    }
  }

  /// GPS-based landmark recognition
  Future<Map<String, dynamic>> _gpsBasedRecognition() async {
    try {
      // Ensure cache is updated
      if (_lastCacheUpdate == null ||
          DateTime.now().difference(_lastCacheUpdate!).inMinutes > 2) {
        await updateNearbyCache();
      }

      if (_cachedNearbyLandmarks.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No cached nearby landmarks within 5km');
          print('💡 TIP: For testing, you may want to temporarily expand the radius');
        }
        return {'landmarkId': null, 'gpsScore': 0.0};
      }

      // Get current location
      final location = loc.Location();
      final locationData = await location.getLocation();

      if (locationData.latitude == null || locationData.longitude == null) {
        return {'landmarkId': null, 'gpsScore': 0.0};
      }

      // Find nearest landmark using Euclidean distance
      double minDistance = double.infinity;
      LandmarkData? nearestLandmark;

      for (final landmark in _cachedNearbyLandmarks) {
        final distance = DistanceCalculator.euclideanDistance(
          lat1: locationData.latitude!,
          lon1: locationData.longitude!,
          lat2: landmark.latitude,
          lon2: landmark.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestLandmark = landmark;
        }
      }

      if (nearestLandmark == null) {
        return {'landmarkId': null, 'gpsScore': 0.0};
      }

      // Calculate distance to nearest landmark
      final distanceKm = DistanceCalculator.euclideanDistance(
        lat1: locationData.latitude!,
        lon1: locationData.longitude!,
        lat2: nearestLandmark.latitude,
        lon2: nearestLandmark.longitude,
      );

      // Get user's preferred radius
      final preferencesService = PreferencesService();
      final radius = await preferencesService.getLandmarkRecognitionRadius();

      // Calculate GPS score using sigmoid function:
      // gpsScore = 1 / (1 + e^(gamma * ((distanceKm / radius) - 0.5)))
      // This gives higher scores for closer landmarks and approaches 0 as distance increases
      final normalizedDistance = (distanceKm / radius) - 0.5;
      final exponent = gamma * normalizedDistance;
      final gpsScore = 1.0 / (1.0 + exp(exponent));

      if (kDebugMode) {
        print('📍 GPS Recognition: ${nearestLandmark.landmarkName}');
        print('📏 Distance: ${distanceKm.toStringAsFixed(2)}km');
        print('📏 Radius: ${radius.toStringAsFixed(2)}km');
        print('📊 GPS Score: ${gpsScore.toStringAsFixed(3)}');
      }

      return {
        'landmarkId': nearestLandmark.landmarkId,
        'landmark': nearestLandmark,
        'gpsScore': gpsScore,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ GPS recognition error: $e');
      }
      return {'landmarkId': null, 'gpsScore': 0.0};
    }
  }

  /// Image-based landmark recognition using embeddings
  /// Prioritizes cached nearby landmarks if available
  Future<Map<String, dynamic>> _imageBasedRecognition(File imageFile) async {
    try {
      // Generate image embedding
      final embedding = await _embeddingService.generateEmbedding(imageFile);

      if (embedding == null || _prototypes == null || _prototypes!.isEmpty) {
        if (kDebugMode) {
          print('⚠️ Could not generate embedding or no prototypes loaded');
        }
        return {'landmarkId': null, 'visualScore': 0.0};
      }

      // Determine search scope: cached landmarks first, then all if cache is empty
      Map<int, List<double>> searchScope = {};
      
      if (_cachedNearbyLandmarks.isNotEmpty) {
        // Use only cached landmarks for faster, more accurate search
        for (final landmark in _cachedNearbyLandmarks) {
          if (_prototypes!.containsKey(landmark.landmarkId)) {
            searchScope[landmark.landmarkId] = _prototypes![landmark.landmarkId]!;
          }
        }
        if (kDebugMode) {
          print('🔍 Searching ${searchScope.length} cached landmarks');
        }
      }
      
      // Fallback to all prototypes if no cached data
      if (searchScope.isEmpty) {
        searchScope = _prototypes!;
        if (kDebugMode) {
          print('🌍 No GPS cache - searching all ${searchScope.length} landmarks');
        }
      }

      // Find best match using cosine similarity
      double maxSimilarity = -1.0;
      int? bestLandmarkId;

      for (final entry in searchScope.entries) {
        final similarity = _cosineSimilarity(embedding, entry.value);
        
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          bestLandmarkId = entry.key;
        }
      }

      // Check minimum similarity threshold
      if (maxSimilarity < minCosineSimilarity) {
        if (kDebugMode) {
          print('❌ Visual match too weak: ${maxSimilarity.toStringAsFixed(3)} < $minCosineSimilarity');
        }
        return {'landmarkId': null, 'visualScore': 0.0};
      }

      // Calculate visual score: (cosine_similarity + 1) / 2
      final visualScore = (maxSimilarity + 1) / 2;

      if (kDebugMode) {
        print('🖼️ Visual Recognition: Landmark ID $bestLandmarkId');
        print('📊 Cosine Similarity: ${maxSimilarity.toStringAsFixed(3)}');
        print('📊 Visual Score: ${visualScore.toStringAsFixed(3)}');
      }

      return {
        'landmarkId': bestLandmarkId,
        'visualScore': visualScore,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Visual recognition error: $e');
      }
      return {'landmarkId': null, 'visualScore': 0.0};
    }
  }

  /// Calculate cosine similarity between two vectors
  /// Optimized for L2-normalized embeddings (unit vectors)
  /// For normalized vectors: cosine_similarity = dot_product
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      debugPrint('⚠️ Vector length mismatch: ${a.length} vs ${b.length}');
      return 0.0;
    }
    
    // For L2-normalized embeddings: cosine similarity = dot product
    // This avoids numerical instability from unnecessary norm calculations
    double similarity = 0.0;
    for (int i = 0; i < a.length; i++) {
      similarity += a[i] * b[i];
    }
    
    // Clamp to valid range [-1.0, 1.0] to handle any floating-point errors
    return similarity.clamp(-1.0, 1.0);
  }

  /// Calculate final confidence score
  Map<String, dynamic> _calculateFinalScore(
    Map<String, dynamic> gpsResult,
    Map<String, dynamic> visualResult,
  ) {
    final gpsLandmarkId = gpsResult['landmarkId'] as int?;
    final visualLandmarkId = visualResult['landmarkId'] as int?;
    final gpsScore = gpsResult['gpsScore'] as double? ?? 0.0;
    final visualScore = visualResult['visualScore'] as double? ?? 0.0;

    // Check if both methods agree (bonus condition)
    final bonusApplied = gpsLandmarkId != null &&
        visualLandmarkId != null &&
        gpsLandmarkId == visualLandmarkId;

    // Calculate final confidence: alpha*visual + beta*gps + bonus
    double confidenceScore = alpha * visualScore + beta * gpsScore;
    if (bonusApplied) {
      confidenceScore += bonus;
    }

    // Determine which landmark ID to use (prefer visual if scores are similar)
    final finalLandmarkId = visualScore >= gpsScore
        ? visualLandmarkId
        : (gpsLandmarkId ?? visualLandmarkId);

    if (kDebugMode) {
      print('🎯 Final Scores:');
      print('   Visual Score: ${visualScore.toStringAsFixed(3)}');
      print('   GPS Score: ${gpsScore.toStringAsFixed(3)}');
      print('   Bonus Applied: $bonusApplied');
      print('   Confidence: ${confidenceScore.toStringAsFixed(3)}');
    }

    return {
      'landmarkId': finalLandmarkId,
      'landmark': gpsResult['landmark'],
      'confidenceScore': confidenceScore,
      'visualScore': visualScore,
      'gpsScore': gpsScore,
      'bonusApplied': bonusApplied,
    };
  }

  /// Process recognition result based on thresholds
  Future<RecognitionResult> _processRecognitionResult(
    Map<String, dynamic> result,
  ) async {
    final landmarkId = result['landmarkId'] as int?;
    final confidenceScore = result['confidenceScore'] as double;
    final visualScore = result['visualScore'] as double?;
    final gpsScore = result['gpsScore'] as double?;
    final bonusApplied = result['bonusApplied'] as bool;

    // Check threshold conditions
    if (confidenceScore < confidenceThreshold) {
      // Case 5: Below threshold
      return RecognitionResult(
        landmarkName: 'No Match',
        landmarkInfo: 'Sorry, no matching landmark found.',
        confidenceScore: confidenceScore,
        visualScore: visualScore,
        gpsScore: gpsScore,
        bonusApplied: bonusApplied,
        success: false,
      );
    }

    // Check conditions for success
    final passesConditions = (bonusApplied) ||
        (!bonusApplied && (visualScore ?? 0.0) >= visualScoreThreshold);

    if (!passesConditions) {
      return RecognitionResult(
        landmarkName: 'Low Confidence',
        landmarkInfo: 'Landmark detected but confidence is too low.',
        confidenceScore: confidenceScore,
        visualScore: visualScore,
        gpsScore: gpsScore,
        bonusApplied: bonusApplied,
        success: false,
      );
    }

    // Success! Fetch landmark data
    if (landmarkId == null) {
      return RecognitionResult(
        landmarkName: 'Unknown',
        landmarkInfo: 'Could not identify landmark.',
        confidenceScore: confidenceScore,
        visualScore: visualScore,
        gpsScore: gpsScore,
        bonusApplied: bonusApplied,
        success: false,
      );
    }

    final landmark = await _csvService.getLandmarkById(landmarkId);
    
    if (landmark == null) {
      return RecognitionResult(
        landmarkName: 'Unknown',
        landmarkInfo: 'Landmark data not found.',
        confidenceScore: confidenceScore,
        visualScore: visualScore,
        gpsScore: gpsScore,
        bonusApplied: bonusApplied,
        success: false,
      );
    }

    // Process landmark_info with LLM (gemma3-1B-it-int4.tflite)
    String landmarkInfo;
    try {
      if (landmark.landmarkInfo.isNotEmpty) {
        // Format existing info with LLM
        landmarkInfo = await _llmService.formatLandmarkInfo(
          landmark.landmarkName,
          landmark.landmarkInfo,
        );
      } else {
        // Generate new info with LLM
        landmarkInfo = await _llmService.generateLandmarkInfo(
          landmark.landmarkName,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ LLM processing failed, using fallback: $e');
      }
      // Fallback to raw info if LLM fails
      landmarkInfo = landmark.landmarkInfo.isNotEmpty
          ? landmark.landmarkInfo
          : '${landmark.landmarkName} is a notable landmark in ${landmark.country}. '
              'This site holds historical or cultural significance.';
    }

    return RecognitionResult(
      landmarkId: landmark.landmarkId,
      landmarkName: landmark.landmarkName,
      landmarkInfo: landmarkInfo,
      confidenceScore: confidenceScore,
      visualScore: visualScore,
      gpsScore: gpsScore,
      bonusApplied: bonusApplied,
      success: true,
    );
  }

  void dispose() {
    _embeddingService.dispose();
    _llmService.dispose();
  }
}
