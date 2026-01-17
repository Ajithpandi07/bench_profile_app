import 'package:flutter/material.dart';

class RippleBackgroundPainter extends CustomPainter {
  final Color color;
  final Offset centerOffset; // Add this parameter

  RippleBackgroundPainter({
    required this.color,
    this.centerOffset = Offset.zero, // Default to zero
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(centerOffset); // Apply offset to center
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Base radius starts around the score card (radius ~120)
    // We want ripples expanding outwards.
    // Base radius starts around the score card (radius ~120)
    // We want ripples expanding outwards.
    // Card radius is 120.
    // If we start at 125, the first ripple is clearly visible just outside the card.
    double baseRadius = 125.0;
    double gap = 35.0; // Slightly tighter gap for better aesthetics

    // Draw multiple concentric circles
    // We want them to go off screen, so we can draw until radius > screen max dimension
    // Draw fixed number of concentric circles
    // 0: 80 (hidden by card)
    // 1: 120 (edge of card)
    // 2: 160 (1st visible ripple)
    // 3: 200 (2nd visible ripple)
    double currentRadius = baseRadius;
    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(center, currentRadius, paint);
      currentRadius += gap;
    }
  }

  @override
  bool shouldRepaint(covariant RippleBackgroundPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
