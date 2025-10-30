/// Model representing an underrated place from the CSV dataset
class UnderratedPlace {
  final String name;
  final String? district;
  final String? state;
  final String description;
  final String category;
  final String? bestTimeToVisit;
  final String estimatedCost;
  final String anchorLocation;
  final int underratedScore;
  
  // GPS coordinates (will be populated via geocoding)
  double? latitude;
  double? longitude;

  UnderratedPlace({
    required this.name,
    this.district,
    this.state,
    required this.description,
    required this.category,
    this.bestTimeToVisit,
    required this.estimatedCost,
    required this.anchorLocation,
    required this.underratedScore,
    this.latitude,
    this.longitude,
  });

  /// Create from CSV row
  factory UnderratedPlace.fromCsvRow(List<dynamic> row) {
    return UnderratedPlace(
      name: row[0]?.toString().trim() ?? '',
      district: row[1]?.toString().trim().isEmpty == true ? null : row[1]?.toString().trim(),
      state: row[2]?.toString().trim().isEmpty == true ? null : row[2]?.toString().trim(),
      description: row[3]?.toString().trim() ?? '',
      category: row[4]?.toString().trim() ?? '',
      bestTimeToVisit: row[5]?.toString().trim().isEmpty == true ? null : row[5]?.toString().trim(),
      estimatedCost: row[6]?.toString().trim() ?? '',
      anchorLocation: row[7]?.toString().trim() ?? '',
      underratedScore: int.tryParse(row[8]?.toString().trim() ?? '0') ?? 0,
    );
  }

  /// Create from map (for caching coordinates)
  factory UnderratedPlace.fromMap(Map<String, dynamic> map) {
    return UnderratedPlace(
      name: map['name'] as String,
      district: map['district'] as String?,
      state: map['state'] as String?,
      description: map['description'] as String,
      category: map['category'] as String,
      bestTimeToVisit: map['bestTimeToVisit'] as String?,
      estimatedCost: map['estimatedCost'] as String,
      anchorLocation: map['anchorLocation'] as String,
      underratedScore: map['underratedScore'] as int,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
  }

  /// Convert to map (for caching coordinates)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'district': district,
      'state': state,
      'description': description,
      'category': category,
      'bestTimeToVisit': bestTimeToVisit,
      'estimatedCost': estimatedCost,
      'anchorLocation': anchorLocation,
      'underratedScore': underratedScore,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Get display location string
  String get displayLocation {
    final parts = <String>[];
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.isEmpty ? anchorLocation : parts.join(', ');
  }

  /// Check if has valid GPS coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  String toString() {
    return 'UnderratedPlace(name: $name, location: $displayLocation, score: $underratedScore)';
  }
}
