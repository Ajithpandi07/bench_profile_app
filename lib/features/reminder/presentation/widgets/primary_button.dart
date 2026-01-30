import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';

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
    final w = width ?? AppDimensions.primaryButtonWidth;
    final h = height ?? AppDimensions.primaryButtonHeight;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.transparent, // Button handles color
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.primaryButtonRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 9.2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          fixedSize: Size(w, h),
          minimumSize: Size(w, h),
          backgroundColor: Theme.of(context).primaryColor, // Red background
          foregroundColor: Theme.of(
            context,
          ).colorScheme.onPrimary, // Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppDimensions.primaryButtonRadius,
            ),
          ),
          padding: padding ?? EdgeInsets.zero,
          elevation: 0, // Disable material shadow
          shadowColor: Colors.transparent,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize ?? 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
            height: 20 / (fontSize ?? 14), // Enforce 20px line height
          ),
        ),
      ),
    );
  }
}
