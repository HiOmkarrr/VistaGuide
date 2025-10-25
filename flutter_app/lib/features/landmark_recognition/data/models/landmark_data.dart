/// Model representing a landmark from India_Landmarks.csv
class LandmarkData {
  final int landmarkId;
  final String category;
  final String supercategory;
  final String hierarchicalLabel;
  final String naturalOrHumanMade;
  final String images;
  final double latitude;
  final double longitude;
  final String landmarkName;
  final String landmarkInfo;
  final String infoLanguage;
  final String country;

  LandmarkData({
    required this.landmarkId,
    required this.category,
    required this.supercategory,
    required this.hierarchicalLabel,
    required this.naturalOrHumanMade,
    required this.images,
    required this.latitude,
    required this.longitude,
    required this.landmarkName,
    required this.landmarkInfo,
    required this.infoLanguage,
    required this.country,
  });

  /// Create LandmarkData from CSV row
  factory LandmarkData.fromCsvRow(List<dynamic> row) {
    return LandmarkData(
      landmarkId: int.tryParse(row[0].toString()) ?? 0,
      category: row[1]?.toString() ?? '',
      supercategory: row[2]?.toString() ?? '',
      hierarchicalLabel: row[3]?.toString() ?? '',
      naturalOrHumanMade: row[4]?.toString() ?? '',
      images: row[5]?.toString() ?? '',
      latitude: double.tryParse(row[6]?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(row[7]?.toString() ?? '0') ?? 0.0,
      landmarkName: row[8]?.toString() ?? '',
      landmarkInfo: row[9]?.toString() ?? '',
      infoLanguage: row[10]?.toString() ?? '',
      country: row[11]?.toString() ?? '',
    );
  }

  /// Create LandmarkData from Map (for caching)
  factory LandmarkData.fromMap(Map<String, dynamic> map) {
    return LandmarkData(
      landmarkId: map['landmarkId'] ?? 0,
      category: map['category'] ?? '',
      supercategory: map['supercategory'] ?? '',
      hierarchicalLabel: map['hierarchicalLabel'] ?? '',
      naturalOrHumanMade: map['naturalOrHumanMade'] ?? '',
      images: map['images'] ?? '',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      landmarkName: map['landmarkName'] ?? '',
      landmarkInfo: map['landmarkInfo'] ?? '',
      infoLanguage: map['infoLanguage'] ?? '',
      country: map['country'] ?? '',
    );
  }

  /// Convert to Map (for caching)
  Map<String, dynamic> toMap() {
    return {
      'landmarkId': landmarkId,
      'category': category,
      'supercategory': supercategory,
      'hierarchicalLabel': hierarchicalLabel,
      'naturalOrHumanMade': naturalOrHumanMade,
      'images': images,
      'latitude': latitude,
      'longitude': longitude,
      'landmarkName': landmarkName,
      'landmarkInfo': landmarkInfo,
      'infoLanguage': infoLanguage,
      'country': country,
    };
  }

  @override
  String toString() {
    return 'LandmarkData(id: $landmarkId, name: $landmarkName, lat: $latitude, lon: $longitude)';
  }
}
