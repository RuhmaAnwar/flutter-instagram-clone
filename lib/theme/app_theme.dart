import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryTeal,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryTeal,
      secondary: AppColors.accent,
      surface: AppColors.surfaceLight,
      onSecondaryFixed: AppColors.surfaceDark,
      error: AppColors.error,
      onPrimary: AppColors.textPrimaryLight,
      onSecondary: AppColors.greyDark,
      onSurface: AppColors.textPrimaryLight,
      onError: AppColors.backgroundLight,

      
    ),
    textTheme: AppTypography.lightTextTheme,
    // elevatedButtonTheme: ElevatedButtonThemeData(
    //   style: ButtonStyle(
    //     backgroundColor: WidgetStateProperty.all(Colors.transparent),
    //     foregroundColor: WidgetStateProperty.all(AppColors.textPrimaryLight),
    //     overlayColor: WidgetStateProperty.all(AppColors.accent.withOpacity(0.1)),
    //     shape: WidgetStateProperty.all(
    //       RoundedRectangleBorder(
    //         borderRadius: BorderRadius.circular(8),
    //       ),
    //     ),
    //     textStyle: WidgetStateProperty.all(AppTypography.lightTextTheme.labelLarge),
    //     backgroundGradient: WidgetStateProperty.all(AppColors.primaryGradient),
    //   ),
    // ),

    // // text field light theme:
    inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.greyLight, // Light grey for light mode
          
          contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.5.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.greyBorderLight), // Grey border
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.greyBorderLight), // Grey border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.greyBorderLight), // Grey border
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),   
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryTeal,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryTeal,
      secondary: AppColors.accent,
      surface: AppColors.surfaceDark,
      onSecondaryFixed: AppColors.textSecondaryDark,
      error: AppColors.error,
      onPrimary: AppColors.textPrimaryDark,
      onSecondary: AppColors.greyDark,
      onSurface: AppColors.textPrimaryDark,
      onError: AppColors.backgroundDark,
    ),
    textTheme: AppTypography.darkTextTheme,

    // elevatedButtonTheme: ElevatedButtonThemeData(
    //   style: ButtonStyle(
    //     backgroundColor: WidgetStateProperty.all(Colors.transparent),
    //     foregroundColor: WidgetStateProperty.all(AppColors.textPrimaryDark),
    //     overlayColor: WidgetStateProperty.all(AppColors.accent.withOpacity(0.1)),
    //     shape: WidgetStateProperty.all(
    //       RoundedRectangleBorder(
    //         borderRadius: BorderRadius.circular(8),
    //       ),
    //     ),
    //     textStyle: WidgetStateProperty.all(AppTypography.darkTextTheme.labelLarge),
    //     backgroundGradient: WidgetStateProperty.all(AppColors.primaryGradient),
    //   ),
    // ),

    // // text field dark theme:
    inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.greyDark, // Dark grey for dark mode
          contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.5.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.greyBorderDark), // Grey border
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.greyBorderDark), // Grey border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.greyBorderDark), // Grey border
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ), 

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
    ),
  );
}