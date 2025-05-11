import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/theme/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class InstaButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFilled;

  const InstaButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isFilled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    double buttonWidth = 343.w;
    double buttonHeight = 44.h;
    double fontSize =  14.sp;

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color borderColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    Color shadowColor = isDarkMode ? Colors.grey[800]! : Colors.grey[400]!;

    return SizedBox(
      height: buttonHeight,
      width: buttonWidth,
      child: PhysicalModel(
        color: Colors.transparent,
        shadowColor: shadowColor,
        elevation: 5,
        borderRadius: BorderRadius.circular(8.r), // Responsive border radius
        child: Container(
          decoration: BoxDecoration(
            gradient: isFilled ? AppColors.primaryGradient : null,
            color: isFilled ? null : Colors.transparent,
            border: isFilled ? null : Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8.r),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.normal,
                    color: isFilled ? Colors.white : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}