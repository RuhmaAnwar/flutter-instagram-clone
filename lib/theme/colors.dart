import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryTeal = Color(0xFF229895);
  static const Color primaryCoral = Color(0xFFD2685C);
  static const Color backgroundLight = Colors.white;
  static const Color backgroundDark = Colors.black;
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF212121);
  static const Color textPrimaryLight = Colors.black;
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryLight = Colors.black54;
  static const Color textSecondaryDark = Colors.white70;
  static const Color error = Color(0xFFB00020);
  static const Color accent = Color(0xFFFFF750);

  // Added grey shades for border and fill
  static const Color greyBorderLight = Color.fromRGBO(0, 0, 0, 0.10); // Grey for light border 
  static const Color greyBorderDark = Color(0xFF29292E); // Grey for dark border
  static const Color greyLight = Color(0xFFFAFAFA); // Light grey for light mode fill
  static const Color greyDark = Color(0xFF1B1A1C); // Dark grey for dark mode fill

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryCoral],
  );
}
 
