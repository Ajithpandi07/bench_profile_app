// lib/features/health_metrics/presentation/widgets/circular_score_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/health_metrics.dart';

class CircularScoreCard extends StatelessWidget {
  final HealthMetrics? metrics;
  final int goalSteps;
  final bool showQuickActions;
  final bool fullCircle;
  final Duration animateDuration;
  final double? size; // optional fixed size (square), otherwise responsive

  const CircularScoreCard({
    super.key,
    this.metrics,
    this.goalSteps = 10000,
    this.showQuickActions = true,
    this.fullCircle = false,
    this.animateDuration = const Duration(milliseconds: 700),
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final steps = metrics?.steps ?? 0;
    final rawProgress = (steps / goalSteps).clamp(0.0, 1.0);

    // Responsive sizing: if size provided use it; otherwise adapt to parent's width
    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width;
      // Choose a square size; for half-circle we prefer a shorter height (half), for full circle use equal.
      final double computedSize = size ??
          (fullCircle ? width : min(width, (MediaQuery.of(context).size.height * 0.28).clamp(160.0, 320)));

      // Use TweenAnimationBuilder to smoothly animate progress when steps change.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: SizedBox(
              width: computedSize,
              height: fullCircle ? computedSize : computedSize * 0.6, // half circle uses smaller height
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: rawProgress),
                duration: animateDuration,
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(computedSize, fullCircle ? computedSize : computedSize * 0.6),
                        painter: _ArcPainter(
                          progress: animatedProgress,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                          progressColor: Theme.of(context).colorScheme.primary,
                          strokeWidth: 14.0,
                          fullCircle: fullCircle,
                        ),
                      ),
                      // Center content
                      _CenterContent(
                        metrics: metrics,
                        goalSteps: goalSteps,
                        progress: animatedProgress,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Quick actions below for semi and full circle (optional)
          if (showQuickActions)
            Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: _quickActionsRow(context),
            ),
        ],
      );
    });
  }

  Widget _quickActionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _QuickAction(
          icon: Icons.restaurant,
          current: '0',
          total: '3',
          onAdd: () => debugPrint('Add meal'),
        ),
        const SizedBox(width: 18),
        _QuickAction(
          icon: Icons.water_drop,
          current: '0.0',
          total: '3.2 L',
          onAdd: () => debugPrint('Add water'),
        ),
        const SizedBox(width: 18),
        _QuickAction(
          icon: Icons.fitness_center,
          current: '0',
          total: '60',
          onAdd: () => debugPrint('Add exercise'),
        ),
        const SizedBox(width: 18),
        const _HydrationReminder(),
      ],
    );
  }
}

/// Center widget that shows steps, heart rate and percent.
class _CenterContent extends StatelessWidget {
  final HealthMetrics? metrics;
  final int goalSteps;
  final double progress;

  const _CenterContent({
    required this.metrics,
    required this.goalSteps,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = metrics?.steps ?? 0;
    final hr = metrics?.heartRate;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          steps.toString(),
          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          hr != null ? '${hr.toStringAsFixed(1)} bpm' : 'No HR',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '${(progress * 100).toStringAsFixed(0)}% of $goalSteps',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Painter that draws either a full circular ring or a half-arc progress
class _ArcPainter extends CustomPainter {
  final double progress; // 0..1
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;
  final bool fullCircle;

  _ArcPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    this.strokeWidth = 10.0,
    this.fullCircle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bg = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint fg = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (fullCircle) {
      final double radius = (min(size.width, size.height) - strokeWidth) / 2;
      final Offset center = Offset(size.width / 2, size.height / 2);
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      final double start = -pi / 2; // start at top
      final double sweep = 2 * pi * progress;
      canvas.drawArc(rect, 0, 2 * pi, false, bg); // full background circle
      if (progress > 0) canvas.drawArc(rect, start, sweep, false, fg);
    } else {
      // semi-circle (half) — use larger rect height as original design did
      final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
      final double start = -pi; // left
      final double sweep = pi * progress; // up to 180deg
      canvas.drawArc(rect, start, pi, false, bg);
      if (progress > 0) canvas.drawArc(rect, start, sweep, false, fg);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fullCircle != fullCircle;
  }
}

/// Small quick action widget
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
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAdd,
                    customBorder: const CircleBorder(),
                    child: Icon(icon, color: color, size: 28),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.2), width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Icon(Icons.add, size: 16, color: color),
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
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Transform.rotate(
                  angle: -pi / 2,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 6,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              Icon(Icons.water_drop, color: Colors.grey.shade700, size: 24),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
