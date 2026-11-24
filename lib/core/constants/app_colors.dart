import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0B0F17);
  static const Color darkSurface = Color(0xFF151D2A);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo Accent
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  static const Color secondary = Color(0xFF0EA5E9); // Sky Blue
  static const Color accent = Color(0xFF10B981); // Emerald Green

  // Status Colors (Matching requirements: Passed, Failed, Blocked, Untested)
  static const Color passed = Color(0xFF10B981); // Green
  static const Color failed = Color(0xFFEF4444); // Red
  static const Color blocked = Color(0xFFF59E0B); // Amber / Orange
  static const Color untested = Color(0xFF64748B); // Slate Grey
  static const Color inProgress = Color(0xFF3B82F6); // Blue

  // Priority Colors
  static const Color priorityCritical = Color(0xFFDC2626);
  static const Color priorityHigh = Color(0xFFEA580C);
  static const Color priorityMedium = Color(0xFFD97706);
  static const Color priorityLow = Color(0xFF16A34A);

  // Neutral Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
}
