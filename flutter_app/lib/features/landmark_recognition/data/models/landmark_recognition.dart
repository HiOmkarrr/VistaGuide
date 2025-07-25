/// Landmark recognition result data model
class LandmarkRecognition {
  final String id;
  final String landmarkName;
  final String? description;
  final double confidence;
  final String? imageUrl;
  final DateTime recognizedAt;
  final String? location;
  final List<String> tags;

  const LandmarkRecognition({
    required this.id,
    required this.landmarkName,
    this.description,
    required this.confidence,
    this.imageUrl,
    required this.recognizedAt,
    this.location,
    this.tags = const [],
  });

  /// Create a copy of this recognition with updated fields
  LandmarkRecognition copyWith({
    String? id,
    String? landmarkName,
    String? description,
    double? confidence,
    String? imageUrl,
    DateTime? recognizedAt,
    String? location,
    List<String>? tags,
  }) {
    return LandmarkRecognition(
      id: id ?? this.id,
      landmarkName: landmarkName ?? this.landmarkName,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
      imageUrl: imageUrl ?? this.imageUrl,
      recognizedAt: recognizedAt ?? this.recognizedAt,
      location: location ?? this.location,
      tags: tags ?? this.tags,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'landmarkName': landmarkName,
      'description': description,
      'confidence': confidence,
      'imageUrl': imageUrl,
      'recognizedAt': recognizedAt.toIso8601String(),
      'location': location,
      'tags': tags,
    };
  }

  /// Create from JSON
  factory LandmarkRecognition.fromJson(Map<String, dynamic> json) {
    return LandmarkRecognition(
      id: json['id'] as String,
      landmarkName: json['landmarkName'] as String,
      description: json['description'] as String?,
      confidence: json['confidence'] as double,
      imageUrl: json['imageUrl'] as String?,
      recognizedAt: DateTime.parse(json['recognizedAt'] as String),
      location: json['location'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Get confidence as percentage
  String get confidencePercentage => '${(confidence * 100).toInt()}%';

  /// Check if recognition is highly confident
  bool get isHighConfidence => confidence >= 0.8;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandmarkRecognition && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LandmarkRecognition(id: $id, landmarkName: $landmarkName, confidence: $confidence)';
  }
}
