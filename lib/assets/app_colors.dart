import 'package:flutter/material.dart';

class AppColors {
  // Base colors
  static const Color teal = Color(0xFF006262);
  static const Color coral = Color(0xFFFF7F50);

  // Lighter gradient (for backgrounds)
  static const LinearGradient primaryGradientLight = LinearGradient(
    colors: [
    Color.fromARGB(255, 188, 221, 219), // Much lighter teal
    Color.fromARGB(255, 252, 224, 216), // Much lighter coral
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Darker gradient (for buttons, accents)
  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [
      Color(0xFF004747), // Darker teal
      Color(0xFFE55C30), // Darker coral
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
