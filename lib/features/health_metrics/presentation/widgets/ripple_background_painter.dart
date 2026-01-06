import 'package:flutter/material.dart';

class RippleBackgroundPainter extends CustomPainter {
  final Color color;
  RippleBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Base radius starts around the score card (radius ~120)
    // We want ripples expanding outwards.
    double baseRadius = 80.0; // Slightly larger than the 120 radius card
    double gap = 40.0; // Gap between ripples

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
