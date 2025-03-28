import 'package:flutter/material.dart';

class InstaTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final double? width;

  const InstaTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    double fontSize = (screenWidth * 0.047 + screenHeight * 0.03) / 2; // Combines both
    double inputWidth = width ?? (screenHeight * 0.12 + screenWidth * 0.64); // Default 85% of width
    double inputHeight = (screenHeight * 0.08 + screenWidth * 0.14) / 2; // Uses both

    return SizedBox(
      width: inputWidth,
      height: inputHeight,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: Colors.black, fontSize: fontSize),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: fontSize * 0.9),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: inputHeight * 0.2, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade500),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}
