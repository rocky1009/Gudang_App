import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  final Color backgroundcolor;
  final String text;
  final Color textColor;
  const ButtonWidget({super.key, required this.backgroundcolor, required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: MediaQuery.of(context).size.height/14,
      decoration: BoxDecoration(
        color: backgroundcolor,
        borderRadius: BorderRadius.circular(40)
      ),
      child: Center(
        child: Text(text, style: TextStyle(
          fontSize: 24,
          color: textColor
        ),),
      ),
    );
  }
}