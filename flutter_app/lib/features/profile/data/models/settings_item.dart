import 'package:flutter/material.dart';

/// Settings item data model
class SettingsItem {
  final String id;
  final String title;
  final IconData icon;
  final String? subtitle;
  final String? route;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool showArrow;

  const SettingsItem({
    required this.id,
    required this.title,
    required this.icon,
    this.subtitle,
    this.route,
    this.onTap,
    this.isEnabled = true,
    this.showArrow = true,
  });

  /// Create a copy of this item with updated fields
  SettingsItem copyWith({
    String? id,
    String? title,
    IconData? icon,
    String? subtitle,
    String? route,
    VoidCallback? onTap,
    bool? isEnabled,
    bool? showArrow,
  }) {
    return SettingsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      subtitle: subtitle ?? this.subtitle,
      route: route ?? this.route,
      onTap: onTap ?? this.onTap,
      isEnabled: isEnabled ?? this.isEnabled,
      showArrow: showArrow ?? this.showArrow,
    );
  }

  /// Convert to JSON (excluding non-serializable fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'route': route,
      'isEnabled': isEnabled,
      'showArrow': showArrow,
    };
  }

  /// Create from JSON (with default icon)
  factory SettingsItem.fromJson(Map<String, dynamic> json) {
    return SettingsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: Icons.settings, // Default icon
      subtitle: json['subtitle'] as String?,
      route: json['route'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? true,
      showArrow: json['showArrow'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SettingsItem(id: $id, title: $title, isEnabled: $isEnabled)';
  }
}
