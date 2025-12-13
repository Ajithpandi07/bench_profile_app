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
  
  late Paint _backgroundPaint;
  late Paint _foregroundPaint;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePaints();
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
    if (widget.size != oldWidget.size || widget.fullCircle != oldWidget.fullCircle) {
      _updatePaints();
    }
  }

  void _updatePaints() {
    final theme = Theme.of(context);
    final strokeWidth = widget.size / 12;

    _backgroundPaint = Paint()
      ..color = theme.colorScheme.surface.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    _foregroundPaint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
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
          // Optimization: Build static child once
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
          builder: (context, child) {
            return CustomPaint(
              painter: _CirclePainter(
                progress: _animation.value,
                fullCircle: widget.fullCircle,
                backgroundPaint: _backgroundPaint,
                foregroundPaint: _foregroundPaint,
              ),
              child: child,
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
  final Paint backgroundPaint;
  final Paint foregroundPaint;

  _CirclePainter({
    required this.progress,
    required this.fullCircle,
    required this.backgroundPaint,
    required this.foregroundPaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = backgroundPaint.strokeWidth;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

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
      backgroundPaint != oldDelegate.backgroundPaint ||
      foregroundPaint != oldDelegate.foregroundPaint;
}