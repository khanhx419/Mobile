import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryEmerald = Color(0xFF059669);
  static const Color primaryAmber = Color(0xFFD97706);
  static const Color primaryRose = Color(0xFFE11D48);
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color primaryCyan = Color(0xFF0891B2);

  // Palette presets for Subjects & Categories (inspired by Cashew's color palette)
  static const List<Color> presetColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF4F46E5), // Indigo
    Color(0xFF9333EA), // Purple
    Color(0xFFE11D48), // Rose
    Color(0xFFEA580C), // Orange
    Color(0xFFD97706), // Amber
    Color(0xFF059669), // Emerald
    Color(0xFF0D9488), // Teal
    Color(0xFF0891B2), // Cyan
    Color(0xFF475569), // Slate
  ];

  // Category Colors
  static const Color lectureColor = Color(0xFF3B82F6);    // Blue
  static const Color assignmentColor = Color(0xFFEF4444); // Red/Orange
  static const Color referenceColor = Color(0xFF10B981);  // Green
  static const Color examColor = Color(0xFFF59E0B);       // Amber
  static const Color notesColor = Color(0xFF8B5CF6);      // Purple

  // Background & Surface
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
}
