import 'dart:math';

/// Utility class for calculating distances between GPS coordinates
class DistanceCalculator {
  // Earth's radius in kilometers
  static const double earthRadiusKm = 6371.0;

  /// Calculate distance between two GPS coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    // Convert latitude and longitude from degrees to radians
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    // Haversine formula
    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1Rad) * cos(lat2Rad);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Distance in kilometers
    final distance = earthRadiusKm * c;

    return distance;
  }

  /// Check if a point is within a certain radius (in km) of another point
  static bool isWithinRadius({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
    required double radiusKm,
  }) {
    final distance = calculateDistance(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
    return distance <= radiusKm;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Get approximate location match score based on name similarity
  /// Returns a score from 0.0 to 1.0
  static double getLocationNameSimilarity(String location1, String location2) {
    if (location1.isEmpty || location2.isEmpty) return 0.0;

    final loc1 = location1.toLowerCase().trim();
    final loc2 = location2.toLowerCase().trim();

    // Exact match
    if (loc1 == loc2) return 1.0;

    // Contains match
    if (loc1.contains(loc2) || loc2.contains(loc1)) return 0.8;

    // Check word-by-word similarity
    final words1 = loc1.split(RegExp(r'[\s,]+'));
    final words2 = loc2.split(RegExp(r'[\s,]+'));

    int matchCount = 0;
    for (final word1 in words1) {
      for (final word2 in words2) {
        if (word1 == word2 && word1.length > 2) {
          matchCount++;
        }
      }
    }

    if (matchCount > 0) {
      return 0.5 + (matchCount / max(words1.length, words2.length)) * 0.3;
    }

    return 0.0;
  }
}
