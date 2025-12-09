// lib/features/health_metrics/presentation/widgets/circular_score_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics_summary.dart';

/// A widget that displays a primary metric (like steps) in a circular progress
/// indicator, with a score and secondary information in the center.
class CircularScoreCard extends StatefulWidget {
  final HealthMetricsSummary? metrics;
  final int goalSteps;
  final double size;
  final bool fullCircle;
  final bool showQuickActions;
  final Duration animateDuration;

  const CircularScoreCard({
    super.key,
    required this.metrics,
    this.goalSteps = 10000,
    this.size = 200,
    this.fullCircle = false,
    this.showQuickActions = false,
    this.animateDuration = const Duration(milliseconds: 800),
  });

  @override
  State<CircularScoreCard> createState() => _CircularScoreCardState();
}

class _CircularScoreCardState extends State<CircularScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animateDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: _progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CircularScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.metrics?.steps != oldWidget.metrics?.steps) {
      _animation = Tween<double>(begin: _animation.value, end: _progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _progress {
    final steps = widget.metrics?.steps;
    if (steps == null || steps <= 0) {
      return 0.0;
    }
    return min(steps / widget.goalSteps, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = widget.metrics?.steps ?? 0;

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: _CirclePainter(
                progress: _animation.value,
                fullCircle: widget.fullCircle,
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.primary,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${steps.toInt()}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'of ${widget.goalSteps} steps',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final bool fullCircle;
  final Color backgroundColor;
  final Color foregroundColor;

  _CirclePainter({
    required this.progress,
    required this.fullCircle,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width / 12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final foregroundPaint = Paint()
      ..color = foregroundColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      fullCircle != oldDelegate.fullCircle ||
      backgroundColor != oldDelegate.backgroundColor ||
      foregroundColor != oldDelegate.foregroundColor;
}