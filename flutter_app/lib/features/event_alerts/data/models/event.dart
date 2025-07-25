import 'package:flutter/material.dart';

/// Event data model
class Event {
  final String id;
  final String title;
  final String date;
  final String description;
  final String category;
  final Color color;
  final IconData icon;
  final String? location;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isFavorite;

  const Event({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.category,
    required this.color,
    required this.icon,
    this.location,
    this.startTime,
    this.endTime,
    this.isFavorite = false,
  });

  /// Create a copy of this event with updated fields
  Event copyWith({
    String? id,
    String? title,
    String? date,
    String? description,
    String? category,
    Color? color,
    IconData? icon,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    bool? isFavorite,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'description': description,
      'category': category,
      'location': location,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  /// Create from JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      color: Colors.blue, // Default color, would be mapped from category
      icon: Icons.event, // Default icon, would be mapped from category
      location: json['location'] as String?,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Event(id: $id, title: $title, category: $category, date: $date)';
  }
}
