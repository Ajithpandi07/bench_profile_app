import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entities.dart';
import '../pages/pages.dart';
import '../bloc/bloc.dart';
import '../../../../../core/injection_container.dart' as di;

class CircularScoreCard extends StatefulWidget {
  final HealthMetricsSummary? metrics;
  final int goalSteps;
  final double size;
  final Duration animateDuration;

  const CircularScoreCard({
    super.key,
    required this.metrics,
    this.goalSteps = 10000,
    this.size = 280,
    this.animateDuration = const Duration(milliseconds: 800),
  });

  @override
  State<CircularScoreCard> createState() => _CircularScoreCardState();
}

class _CircularScoreCardState extends State<CircularScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animateDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: _progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(CircularScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.metrics?.steps != oldWidget.metrics?.steps) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: _progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
    // ignore: unused_local_variable
    final steps = widget.metrics?.steps;
    if (steps == null || steps.value <= 0) return 0.0;
    return math.min(steps.value / widget.goalSteps, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return ClipOval(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dashed Progress Circle
            SizedBox(
              width: widget.size * 0.85,
              height: widget.size * 0.85,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _DashedCirclePainter(
                      progress: _progressAnimation.value,
                      color: Theme.of(
                        context,
                      ).dividerColor, // Darker gray for better visibility
                      activeGradient: LinearGradient(
                        colors: [
                          primaryColor,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      activeColor: primaryColor,
                      strokeWidth: 14, // Height of the pipe bars
                    ),
                  );
                },
              ),
            ),

            // Center Content - Circular Button
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => di.sl<HealthMetricsBloc>(),
                      child: const HealthMetricsPage(),
                    ),
                  ),
                );
                if (context.mounted) {
                  // Refresh the DASHBOARD bloc upon return to catch any new syncs
                  // Does NOT change the date, just refreshes data for "Today"
                  context.read<HealthMetricsBloc>().add(const RefreshMetrics());
                  _controller.forward(from: 0);
                }
              },
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Logging',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'to score',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if ((widget.metrics?.steps?.value ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${widget.metrics!.steps!.value.toInt()}',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Gradient? activeGradient;
  final Color activeColor;
  final double strokeWidth; // Length of the pipe (radial height)

  _DashedCirclePainter({
    required this.progress,
    required this.color,
    this.activeGradient,
    required this.activeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Config for "Pipes"
    const int totalPipes = 50; // Total number of bars in the gauge
    const double pipeThickness = 3.0; // Width of each pipe

    // Geometry
    final double startAngleRad = 125 * (math.pi / 180);
    final double sweepAngle = 290 * (math.pi / 180);

    final double stepAngle = sweepAngle / (totalPipes - 1);

    // Paint Setup
    final backgroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = pipeThickness
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = pipeThickness
      ..strokeCap = StrokeCap.round;

    if (activeGradient != null) {
      activePaint.shader = activeGradient!.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    } else {
      activePaint.color = activeColor;
    }

    // Draw Loop
    for (int i = 0; i < totalPipes; i++) {
      final double currentAngle = startAngleRad + (i * stepAngle);
      final bool isActive = (i / (totalPipes - 1)) <= progress;

      // Calculate radial line segment
      // We want the pipe to be centered on 'radius' circle, with length 'strokeWidth'
      final double innerR = radius - (strokeWidth / 2);
      final double outerR = radius + (strokeWidth / 2);

      final p1 = Offset(
        center.dx + innerR * math.cos(currentAngle),
        center.dy + innerR * math.sin(currentAngle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(currentAngle),
        center.dy + outerR * math.sin(currentAngle),
      );

      canvas.drawLine(p1, p2, isActive ? activePaint : backgroundPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
