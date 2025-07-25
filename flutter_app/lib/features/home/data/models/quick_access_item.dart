import 'package:flutter/material.dart';

/// Quick access item data model
class QuickAccessItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final bool isEnabled;

  const QuickAccessItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    this.isEnabled = true,
  });

  /// Create a copy of this item with updated fields
  QuickAccessItem copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? color,
    String? route,
    bool? isEnabled,
  }) {
    return QuickAccessItem(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      route: route ?? this.route,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Convert to JSON (excluding non-serializable fields like IconData and Color)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'route': route,
      'isEnabled': isEnabled,
    };
  }

  /// Create from JSON (with default icon and color)
  factory QuickAccessItem.fromJson(Map<String, dynamic> json) {
    return QuickAccessItem(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: Icons.apps, // Default icon
      color: Colors.blue, // Default color
      route: json['route'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuickAccessItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QuickAccessItem(id: $id, title: $title, route: $route)';
  }
}
