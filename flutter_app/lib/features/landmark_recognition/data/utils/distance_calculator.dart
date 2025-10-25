import 'dart:math' as math;

/// Utility class for calculating distances between coordinates
class DistanceCalculator {
  /// Earth's radius in kilometers
  static const double earthRadiusKm = 6371.0;

  /// Calculate Haversine distance between two points in kilometers
  /// 
  /// Returns the distance in kilometers between two geographic coordinates
  static double haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    // Convert degrees to radians
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    // Haversine formula
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * 
        math.cos(lat1Rad) * math.cos(lat2Rad);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  /// Calculate Euclidean distance between two points in kilometers
  /// 
  /// Returns the Euclidean distance converted to kilometers
  /// Note: This is an approximation for nearby landmarks (< 50km)
  /// More accurate than Haversine for small distances and faster to compute
  static double euclideanDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    // Approximate conversion: 1 degree ≈ 111 km
    // For more accuracy at different latitudes, we can use cosine of average latitude
    final avgLat = (lat1 + lat2) / 2;
    final latToKm = 111.0; // 1 degree latitude ≈ 111 km
    final lonToKm = 111.0 * math.cos(_degreesToRadians(avgLat)); // Adjust for longitude
    
    final dLat = (lat2 - lat1) * latToKm;
    final dLon = (lon2 - lon1) * lonToKm;
    
    return math.sqrt(dLat * dLat + dLon * dLon);
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
