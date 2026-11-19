import 'package:flutter/material.dart';

class AppTheme {
  // The exact colors from your AnimatedSplashScreen
  static const Color navy = Color(0xFF0B1B3A);
  static const Color deep = Color(0xFF050B1E);
  static const Color pink = Color(0xFFFF4FA3);
  static const Color sky = Color(0xFF4FC3F7);
  static const Color gold = Color(0xFFFFD27A);
  static const Color violet = Color(0xFF8E6CFF);
  static const Color white = Colors.white;

  // Helper for transparent colors
  static Color glass(double opacity) => Colors.white.withOpacity(opacity);

  // The main app theme
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: pink,
      scaffoldBackgroundColor: navy,
      colorScheme: const ColorScheme.dark(
        primary: pink,
        secondary: sky,
        surface: navy,
        onPrimary: white,
        onSecondary: deep,
      ),
      
      // AppBar styling (used in WebView and Migration screens)
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: gold, // Gold title text
        ),
        iconTheme: IconThemeData(color: sky), // Sky blue back arrows
      ),

      // Elevated Buttons (used in Migration screen)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // Text Fields (used in Migration screen)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: deep, // Slightly darker than navy for contrast
        labelStyle: const TextStyle(color: sky),
        hintStyle: TextStyle(color: glass(0.4)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: glass(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: pink, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIconColor: sky,
        suffixIconColor: sky,
      ),
    );
  }
}