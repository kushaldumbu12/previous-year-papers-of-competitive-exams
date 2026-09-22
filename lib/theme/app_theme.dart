import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant, cheerful pastel-solid balloon palette
  static const Color background = Color(0xFFF8FAFC); // Clean off-white
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  // Curated inflated balloon color palette for cards
  static const List<Color> balloonCardColors = [
    Color(0xFFEEF2FF), // Soft Indigo / Lavender
    Color(0xFFFEF3C7), // Soft Warm Amber
    Color(0xFFECFDF5), // Soft Mint Emerald
    Color(0xFFFFEDD5), // Soft Peach Coral
    Color(0xFFF0FDF4), // Soft Lime Green
    Color(0xFFFDF2F8), // Soft Pink Rose
    Color(0xFFF0F9FF), // Soft Sky Blue
    Color(0xFFFAF5FF), // Soft Purple Orchid
    Color(0xFFFFF1F2), // Soft Crimson Blush
    Color(0xFFECFEFF), // Soft Cyan Aqua
  ];

  static const List<Color> balloonAccentColors = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFFD97706), // Amber
    Color(0xFF059669), // Emerald
    Color(0xFFEA580C), // Orange
    Color(0xFF16A34A), // Green
    Color(0xFFDB2777), // Pink
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF7C3AED), // Purple
    Color(0xFFE11D48), // Rose
    Color(0xFF0891B2), // Cyan
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surface,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
