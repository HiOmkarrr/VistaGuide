/// Geographic coordinates for destinations
class GeoCoordinates {
  final double latitude;
  final double longitude;

  const GeoCoordinates({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory GeoCoordinates.fromJson(Map<String, dynamic> json) => GeoCoordinates(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoCoordinates && 
           other.latitude == latitude && 
           other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Historical information for destinations
class HistoricalInfo {
  final String briefDescription;
  final String extendedDescription;
  final List<String> keyEvents;
  final String? timeline;
  final List<String> relatedFigures;

  const HistoricalInfo({
    required this.briefDescription,
    required this.extendedDescription,
    this.keyEvents = const [],
    this.timeline,
    this.relatedFigures = const [],
  });

  Map<String, dynamic> toJson() => {
    'briefDescription': briefDescription,
    'extendedDescription': extendedDescription,
    'keyEvents': keyEvents,
    'timeline': timeline,
    'relatedFigures': relatedFigures,
  };

  factory HistoricalInfo.fromJson(Map<String, dynamic> json) => HistoricalInfo(
    briefDescription: json['briefDescription'] as String,
    extendedDescription: json['extendedDescription'] as String,
    keyEvents: (json['keyEvents'] as List<dynamic>?)?.cast<String>() ?? [],
    timeline: json['timeline'] as String?,
    relatedFigures: (json['relatedFigures'] as List<dynamic>?)?.cast<String>() ?? [],
  );
}

/// Educational information for destinations
class EducationalInfo {
  final List<String> facts;
  final String importance;
  final String culturalRelevance;
  final List<String> learningObjectives;
  final String? architecturalStyle;
  final List<String> categories;

  const EducationalInfo({
    required this.facts,
    required this.importance,
    required this.culturalRelevance,
    this.learningObjectives = const [],
    this.architecturalStyle,
    this.categories = const [],
  });

  Map<String, dynamic> toJson() => {
    'facts': facts,
    'importance': importance,
    'culturalRelevance': culturalRelevance,
    'learningObjectives': learningObjectives,
    'architecturalStyle': architecturalStyle,
    'categories': categories,
  };

  factory EducationalInfo.fromJson(Map<String, dynamic> json) => EducationalInfo(
    facts: (json['facts'] as List<dynamic>?)?.cast<String>() ?? [],
    importance: json['importance'] as String,
    culturalRelevance: json['culturalRelevance'] as String,
    learningObjectives: (json['learningObjectives'] as List<dynamic>?)?.cast<String>() ?? [],
    architecturalStyle: json['architecturalStyle'] as String?,
    categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
  );
}

/// Enhanced Destination data model for dynamic recommendations
class Destination {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? description;
  final double? rating;
  final List<String> tags;
  final bool isFavorite;
  
  // Enhanced fields for dynamic recommendations
  final String type; // monument, museum, park, etc.
  final GeoCoordinates? coordinates;
  final double? distanceKm;
  final HistoricalInfo? historicalInfo;
  final EducationalInfo? educationalInfo;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isOfflineAvailable;

  const Destination({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.description,
    this.rating,
    this.tags = const [],
    this.isFavorite = false,
    this.type = 'attraction',
    this.coordinates,
    this.distanceKm,
    this.historicalInfo,
    this.educationalInfo,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
    this.isOfflineAvailable = false,
  });

  /// Create a copy of this destination with updated fields
  Destination copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? description,
    double? rating,
    List<String>? tags,
    bool? isFavorite,
    String? type,
    GeoCoordinates? coordinates,
    double? distanceKm,
    HistoricalInfo? historicalInfo,
    EducationalInfo? educationalInfo,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOfflineAvailable,
  }) {
    return Destination(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      type: type ?? this.type,
      coordinates: coordinates ?? this.coordinates,
      distanceKm: distanceKm ?? this.distanceKm,
      historicalInfo: historicalInfo ?? this.historicalInfo,
      educationalInfo: educationalInfo ?? this.educationalInfo,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'description': description,
      'rating': rating,
      'tags': tags,
      'isFavorite': isFavorite,
      'type': type,
      'coordinates': coordinates?.toJson(),
      'distanceKm': distanceKm,
      'historicalInfo': historicalInfo?.toJson(),
      'educationalInfo': educationalInfo?.toJson(),
      'images': images,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isOfflineAvailable': isOfflineAvailable,
    };
  }

  /// Create from JSON
  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      type: json['type'] as String? ?? 'attraction',
      coordinates: json['coordinates'] != null 
          ? GeoCoordinates.fromJson(json['coordinates'] as Map<String, dynamic>)
          : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      historicalInfo: json['historicalInfo'] != null
          ? HistoricalInfo.fromJson(json['historicalInfo'] as Map<String, dynamic>)
          : null,
      educationalInfo: json['educationalInfo'] != null
          ? EducationalInfo.fromJson(json['educationalInfo'] as Map<String, dynamic>)
          : null,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null ? _parseDateTime(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? _parseDateTime(json['updatedAt']) : null,
      isOfflineAvailable: json['isOfflineAvailable'] as bool? ?? false,
    );
  }

  /// Helper method to parse DateTime from various formats (int timestamp or Firestore Timestamp)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    // Handle Firestore Timestamp
    if (value.runtimeType.toString() == 'Timestamp') {
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (e) {
        print('Error parsing Firestore Timestamp: $e');
        return null;
      }
    }
    
    if (value is DateTime) {
      return value;
    }
    
    // Try parsing as string
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing DateTime string: $e');
        return null;
      }
    }
    
    print('Unhandled DateTime type: ${value.runtimeType}');
    return null;
  }

  /// Create a basic destination (for backward compatibility)
  factory Destination.basic({
    required String id,
    required String title,
    required String subtitle,
    String? imageUrl,
    String? description,
    double? rating,
    List<String> tags = const [],
  }) {
    return Destination(
      id: id,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      description: description,
      rating: rating,
      tags: tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Destination && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Destination(id: $id, title: $title, type: $type, rating: $rating)';
  }
}
