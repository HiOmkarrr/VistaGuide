import 'dart:io';
import 'package:flutter/foundation.dart';

class TensorFlowLiteService {
  static final TensorFlowLiteService _instance = TensorFlowLiteService._internal();
  factory TensorFlowLiteService() => _instance;
  TensorFlowLiteService._internal();
  
  bool _isModelLoaded = false;
  
  Future<bool> initializeModel() async {
    if (kDebugMode) {
      print(' TensorFlow model loading disabled');
    }
    _isModelLoaded = false;
    return false;
  }
  
  bool get isModelLoaded => _isModelLoaded;
  
  Future<LandmarkPrediction?> recognizeLandmark(File imageFile) async {
    if (kDebugMode) {
      print(' Landmark recognition disabled');
    }
    return null;
  }
  
  List<String>? get availableLabels => null;
  
  void configure({double? scoreThreshold, int? maxResults, int? numThreads}) {}
  
  void dispose() {
    _isModelLoaded = false;
  }
}

class LandmarkPrediction {
  final String landmarkName;
  final double confidence;
  final List<LandmarkConfidence> allPredictions;
  
  LandmarkPrediction({
    required this.landmarkName,
    required this.confidence,
    required this.allPredictions,
  });
}

class LandmarkConfidence {
  final String landmarkName;
  final double confidence;
  
  LandmarkConfidence({
    required this.landmarkName,
    required this.confidence,
  });
}
