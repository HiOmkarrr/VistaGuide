import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service to manage app preferences
class PreferencesService {
  static const String _underratedPlacesRadiusKey = 'underrated_places_radius';
  static const String _landmarkRecognitionRadiusKey = 'landmark_recognition_radius';
  static const String _objectDetectionEnabledKey = 'object_detection_enabled';
  
  // Default values
  static const double defaultUnderratedPlacesRadius = 10.0;
  static const double defaultLandmarkRecognitionRadius = 10.0;
  static const bool defaultObjectDetectionEnabled = true;

  /// Get underrated places search radius (in km)
  Future<double> getUnderratedPlacesRadius() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_underratedPlacesRadiusKey) ?? defaultUnderratedPlacesRadius;
    } catch (e) {
      debugPrint('❌ Error getting underrated places radius: $e');
      return defaultUnderratedPlacesRadius;
    }
  }

  /// Set underrated places search radius (in km)
  Future<void> setUnderratedPlacesRadius(double radius) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_underratedPlacesRadiusKey, radius);
      debugPrint('✅ Underrated places radius updated: $radius km');
    } catch (e) {
      debugPrint('❌ Error setting underrated places radius: $e');
    }
  }

  /// Get object detection enabled status
  Future<bool> getObjectDetectionEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_objectDetectionEnabledKey) ?? defaultObjectDetectionEnabled;
    } catch (e) {
      debugPrint('❌ Error getting object detection enabled: $e');
      return defaultObjectDetectionEnabled;
    }
  }

  /// Set object detection enabled status
  Future<void> setObjectDetectionEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_objectDetectionEnabledKey, enabled);
      debugPrint('✅ Object detection enabled updated: $enabled');
    } catch (e) {
      debugPrint('❌ Error setting object detection enabled: $e');
    }
  }

  /// Get landmark recognition search radius (in km)
  Future<double> getLandmarkRecognitionRadius() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_landmarkRecognitionRadiusKey) ?? defaultLandmarkRecognitionRadius;
    } catch (e) {
      debugPrint('❌ Error getting landmark recognition radius: $e');
      return defaultLandmarkRecognitionRadius;
    }
  }

  /// Set landmark recognition search radius (in km)
  Future<void> setLandmarkRecognitionRadius(double radius) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_landmarkRecognitionRadiusKey, radius);
      debugPrint('✅ Landmark recognition radius updated: $radius km');
    } catch (e) {
      debugPrint('❌ Error setting landmark recognition radius: $e');
    }
  }

  /// Reset all preferences to default
  Future<void> resetToDefaults() async {
    try {
      await setUnderratedPlacesRadius(defaultUnderratedPlacesRadius);
      await setLandmarkRecognitionRadius(defaultLandmarkRecognitionRadius);
      await setObjectDetectionEnabled(defaultObjectDetectionEnabled);
      debugPrint('✅ All preferences reset to defaults');
    } catch (e) {
      debugPrint('❌ Error resetting preferences: $e');
    }
  }
}
