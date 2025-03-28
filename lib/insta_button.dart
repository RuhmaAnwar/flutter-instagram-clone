// this has 2 buttons in one. use as needed by making the isFilled true or false
import 'package:flutter/material.dart';

class InstaButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFilled; // true for login, false for create account

  const InstaButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isFilled = true, // Default is filled (like Log in button on homescreen)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
     // Combines both
    double buttonWidth = screenHeight * 0.12 + screenWidth * 0.64; // Default 85% of width
    double buttonHeight = (screenHeight * 0.057 + screenWidth * 0.117) / 2; // Uses both

    double fontSize = (screenWidth * 0.04 + screenHeight * 0.023) / 2;

    return SizedBox( 
      height: isFilled? buttonHeight : buttonHeight * 1.1, 
      width: buttonWidth,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFilled ? Colors.blue[600] : Colors.white, // Filled or not
          foregroundColor: isFilled ? Colors.white : Colors.blue[600], // Text color
          side: BorderSide(color: Colors.blue.shade600, width: isFilled ? 0 : 1), // Border for outlined button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Rounded shape
          ),
          padding: EdgeInsets.symmetric(vertical: 14),
          elevation: isFilled ? 2 : 0, // Remove shadow when outlined
          shadowColor: isFilled ? Colors.black26 : Colors.transparent, // No shadow for outlined button
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.normal),
        ),
      ),
    );
  }
}
