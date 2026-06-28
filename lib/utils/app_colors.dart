import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1A2A4A); // Navy Blue
  static const Color secondary = Color(0xFF2E3F6E);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  // Background
  static const Color backgroundLight = Color(0xFFF5F5F5);

  // Card Colors
  static const Color cardColor = Colors.white;

  static const Color neutral = Colors.grey;

  // Status Colors
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;

  // Optional: transparent overlays
  static Color whiteOpacity(double value) => Colors.white.withValues(alpha: value);
}