import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/health_metrics.dart';

class CircularScoreCard extends StatelessWidget {
  final HealthMetrics? metrics;
  final int goalSteps;
  final bool showQuickActions;

  const CircularScoreCard({super.key, this.metrics, this.goalSteps = 10000, this.showQuickActions = true});

  @override
  Widget build(BuildContext context) {
    final progress = ((metrics?.steps ?? 0) / goalSteps).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 2 / 1, // Use a 2:1 aspect ratio for a semi-circle
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // The custom painter for the half-circle
              CustomPaint(
                size: const Size(double.infinity, double.infinity),
                painter: _HalfCirclePainter(
                  progress: progress,
                  backgroundColor: Colors.purple.shade50,
                  progressColor: Colors.purple.shade400,
                  strokeWidth: 12,
                ),
              ),

              // Center content: steps / heart rate or placeholder
              FractionallySizedBox(
                heightFactor: 0.8, // Adjust to position content within the arc
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (metrics == null) ...[
                      const Text('Start logging', style: TextStyle(fontSize: 18, color: Color.fromARGB(221, 243, 239, 239))),
                      const SizedBox(height: 4),
                      Row(mainAxisSize: MainAxisSize.min, children: const [
                        Text('to score', style: TextStyle(color: Colors.black87)),
                        SizedBox(width: 4),
                        Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      ]),
                    ] else ...[
                      Text('${metrics?.steps ?? 0}', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(metrics?.heartRate != null ? '${metrics!.heartRate!.toStringAsFixed(1)} bpm' : 'No HR', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Text('${(progress * 100).toStringAsFixed(0)}% of $goalSteps steps', style: Theme.of(context).textTheme.bodySmall),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showQuickActions)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuickAction(
                  icon: Icons.restaurant,
                  current: '0',
                  total: '3',
                  onAdd: () => print('Add meal'),
                ),
                const SizedBox(width: 24),
                _QuickAction(
                  icon: Icons.water_drop,
                  current: '0.0',
                  total: '3.2 l',
                  onAdd: () => print('Add water'),
                ),
                const SizedBox(width: 24),
                _QuickAction(
                  icon: Icons.fitness_center,
                  current: '0',
                  total: '60 min',
                  onAdd: () => print('Add exercise'),
                ),
                const SizedBox(width: 24),
                const _HydrationReminder(),
              ],
            ),
          ),
      ],
    );
  }
}

/// A custom painter to draw a semi-circular progress indicator.
class _HalfCirclePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _HalfCirclePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    this.strokeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final startAngle = -pi; // Start from the left (180 degrees)
    final sweepAngle = pi; // Sweep 180 degrees to the right

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _HalfCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String current;
  final String total;
  final VoidCallback onAdd;

  const _QuickAction({
    required this.icon,
    required this.current,
    required this.total,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main button
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAdd,
                    customBorder: const CircleBorder(),
                    child: Icon(icon, color: Colors.grey.shade800, size: 28),
                  ),
                ),
              ),
              // '+' icon
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.purple.shade50, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Icon(Icons.add, size: 16, color: Colors.purple.shade600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('$current / $total', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _HydrationReminder extends StatelessWidget {
  const _HydrationReminder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular progress indicator
              SizedBox(
                width: 64,
                height: 64,
                child: Transform.rotate(
                  angle: -pi / 2,
                  child: CircularProgressIndicator(
                    value: 0.75, // 75% progress
                    strokeWidth: 6,
                    backgroundColor: Colors.purple.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
                  ),
                ),
              ),
              // Droplet icon
              Icon(Icons.water_drop, color: Colors.grey.shade700, size: 24),
              // Play indicator
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: Colors.purple.shade600, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('In 3 h', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}