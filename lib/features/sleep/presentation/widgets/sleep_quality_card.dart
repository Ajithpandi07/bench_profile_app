import 'package:flutter/material.dart';

class SleepQualityCard extends StatelessWidget {
  final int quality;
  final String message;

  const SleepQualityCard({
    super.key,
    required this.quality,
    this.message = 'Your sleep quality was low.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFFFEAEA),
          width: 1,
        ), // Subtle border
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Top Dark Section (Night Sky)
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F2C4A), // Dark blue
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(31),
                  topRight: Radius.circular(31),
                ),
              ),
              child: Stack(
                children: [
                  // Stars (Decorative)
                  _buildStar(top: 20, left: 30, size: 8),
                  _buildStar(top: 60, left: 10, size: 4),
                  _buildStar(top: 80, left: 60, size: 6),
                  _buildStar(top: 10, right: 100, size: 6),
                  _buildStar(top: 50, right: 60, size: 5),
                  _buildStar(top: 90, right: 20, size: 6),
                  // Moon
                  Positioned(
                    left: 90,
                    top: 20,
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: CustomPaint(painter: _MoonPainter()),
                    ),
                  ),
                  // "Needs Attention" Pill
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        quality < 70 ? 'Needs Attention' : 'Good Job',
                        style: TextStyle(
                          color: quality < 70
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom White Section (Score)
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white, // Dark blue
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(31),
                  bottomRight: Radius.circular(31),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$quality',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const TextSpan(
                          text: ' /100',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStar({
    required double top,
    double? left,
    double? right,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Icon(
        Icons.star,
        color: const Color(0xFFFFAA00), // Gold/Yellow
        size: size * 1.5,
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw a crescent moon
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFE2E8F0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    // Outer circle
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));

    // Cutting circle (offset to create crescent)
    final cutPath = Path();
    cutPath.addOval(
      Rect.fromLTWH(
        size.width * 0.3,
        -size.height * 0.1,
        size.width,
        size.height,
      ),
    );

    // Result
    final moonPath = Path.combine(PathOperation.difference, path, cutPath);

    canvas.drawPath(moonPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
