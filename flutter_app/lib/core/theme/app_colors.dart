import 'package:flutter/material.dart';

/// App color constants following the Figma design
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF2196F3); // Blue from the design
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);
  
  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  
  // Emergency colors
  static const Color emergency = Color(0xFFE53E3E);
  static const Color emergencyLight = Color(0xFFFF6B6B);
  static const Color emergencyDark = Color(0xFFD32F2F);
  
  // Success and status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Neutral colors
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Bottom navigation colors
  static const Color bottomNavSelected = primary;
  static const Color bottomNavUnselected = grey500;
  
  // Event category colors
  static const Color festivalColor = Color(0xFFE91E63);
  static const Color concertColor = Color(0xFF9C27B0);
  static const Color exhibitionColor = Color(0xFF673AB7);
  static const Color foodColor = Color(0xFFFF5722);
  static const Color outdoorColor = Color(0xFF4CAF50);
}
