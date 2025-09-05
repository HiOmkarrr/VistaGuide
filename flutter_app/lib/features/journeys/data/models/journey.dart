import 'journey_details_data.dart';

/// Journey data model for tracking user's planned and completed trips
class Journey {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final List<String> destinations;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final JourneyDetailsData? journeyDetails;

  const Journey({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.isCompleted,
    required this.destinations,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.journeyDetails,
  });

  /// Create a copy of this journey with updated fields
  Journey copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    List<String>? destinations,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    JourneyDetailsData? journeyDetails,
  }) {
    return Journey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      destinations: destinations ?? this.destinations,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      journeyDetails: journeyDetails ?? this.journeyDetails,
    );
  }

  /// Get journey duration in days
  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Check if journey is current (ongoing)
  bool get isCurrent {
    final now = DateTime.now();
    return !isCompleted &&
        now.isAfter(startDate) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Check if journey is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    return !isCompleted && startDate.isAfter(now);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'destinations': destinations,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'journeyDetails': journeyDetails?.toJson(),
    };
  }

  /// Create from JSON
  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int),
      isCompleted: json['isCompleted'] as bool,
      destinations: (json['destinations'] as List<dynamic>).cast<String>(),
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
      journeyDetails: json['journeyDetails'] != null
          ? JourneyDetailsData.fromJson(json['journeyDetails'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Journey && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Journey(id: $id, title: $title, isCompleted: $isCompleted)';
  }
}
