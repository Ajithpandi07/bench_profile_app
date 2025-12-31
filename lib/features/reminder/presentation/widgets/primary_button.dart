import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double? fontSize;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderRadius,
    this.padding,
    this.width,
    this.height,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEE374D), // Red background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 30),
          ),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
          elevation: 4,
          shadowColor: const Color.fromRGBO(238, 55, 77, 0.3),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize ?? 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 20 / (fontSize ?? 18), // Enforce 20px line height
          ),
        ),
      ),
    );
  }
}
