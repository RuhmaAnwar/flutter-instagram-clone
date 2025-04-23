import 'package:flutter/material.dart';

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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double buttonWidth = screenHeight * 0.12 + screenWidth * 0.64;
    double buttonHeight = (screenHeight * 0.057 + screenWidth * 0.117) / 2;
    double fontSize = (screenWidth * 0.04 + screenHeight * 0.023) / 2;

    return SizedBox(
      height: buttonHeight,
      width: buttonWidth,
      child: PhysicalModel(
        color: isFilled ? Colors.black : Colors.white,
        // ignore: deprecated_member_use
        shadowColor: Colors.grey,
        elevation: 5, // More elevation = more 3D
        borderRadius: BorderRadius.circular(30),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isFilled ? Colors.black : Colors.white,
            foregroundColor: isFilled ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0, // Use PhysicalModel's elevation instead
            padding: const EdgeInsets.symmetric(vertical: 14),
            shadowColor: Colors.grey, // shadow comes from PhysicalModel
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
