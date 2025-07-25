/// Destination data model for recommended destinations
class Destination {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? description;
  final double? rating;
  final List<String> tags;
  final bool isFavorite;

  const Destination({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.description,
    this.rating,
    this.tags = const [],
    this.isFavorite = false,
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
      rating: json['rating'] as double?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isFavorite: json['isFavorite'] as bool? ?? false,
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
    return 'Destination(id: $id, title: $title, rating: $rating)';
  }
}
