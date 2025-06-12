import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InstaTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final double? width;
  final Widget? prefixIcon;
  final Widget? suffixIcon; // Added suffixIcon
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;

  const InstaTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.width,
    this.prefixIcon,
    this.suffixIcon, // Initialized suffixIcon
    this.decoration,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double fontSize = 14.sp;
    double inputWidth = width ?? 343.w;
    double inputHeight = 44.h;

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: inputWidth,
      height: inputHeight,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          fontSize: fontSize,
        ),
        decoration: decoration ?? InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.5.h),
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontSize: fontSize,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon, // Pass suffixIcon to InputDecoration
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: isDarkMode ? AppColors.greyBorderDark : AppColors.greyBorderLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: isDarkMode ? AppColors.greyBorderDark : AppColors.greyBorderLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: isDarkMode ? AppColors.greyBorderDark : AppColors.greyBorderLight,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}