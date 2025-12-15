// lib/features/health_metrics/presentation/widgets/circular_score_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics_summary.dart';

/// A widget that displays a circular score card with quick actions,
/// adopting a specific design with meals, water, and exercise shortcuts.
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
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animateDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: _progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CircularScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.metrics?.steps != oldWidget.metrics?.steps) {
      _progressAnimation = Tween<double>(begin: _progressAnimation.value, end: _progress).animate(
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
    // Scale factor to adapt the fixed-pixel design to the widget.size
    // The design assumes roughly 300-350px width.
    final double scale = widget.size / 320.0;
    final double buttonSize = 56 * scale;
    final double iconSize = 20 * scale;
    final double fontSize = 12 * scale;

    final steps = widget.metrics?.steps;
    final hasData = steps != null && steps > 0;

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Outer Circle Border
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.purple.shade100.withOpacity(0.5),
                  width: 8 * scale,
                ),
              ),
            ),

            // 2. Inner Content (Center Text)
            Positioned(
              top: widget.size * 0.25,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasData) ...[
                    // Score / Steps View
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        final currentSteps = (widget.goalSteps * _progressAnimation.value).toInt();
                        return Text(
                          '$currentSteps',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 32 * scale,
                            color: Colors.grey.shade800,
                          ),
                        );
                      },
                    ),
                    Text(
                      'of ${widget.goalSteps} steps',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 14 * scale,
                      ),
                    ),
                  ] else ...[
                    // "Start logging" View
                    Text(
                      'Start logging',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 18 * scale,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'to score',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade800,
                            fontSize: 14 * scale,
                          ),
                        ),
                        SizedBox(width: 4 * scale),
                        Icon(Icons.info_outline, size: 14 * scale, color: Colors.grey.shade400),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 3. Quick Actions positioned at the bottom
            if (widget.showQuickActions)
              Positioned(
                bottom: widget.size * 0.08,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Meals (Placeholder)
                    _QuickAction(
                      icon: Icons.restaurant,
                      label: 'meals',
                      current: '0',
                      total: '3',
                      size: buttonSize,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      onAdd: () {},
                    ),
                    SizedBox(width: 16 * scale),

                    // Water
                    _QuickAction(
                      icon: Icons.water_drop,
                      label: 'water',
                      current: widget.metrics?.water?.toStringAsFixed(1) ?? '0.0',
                      total: '2.5 l',
                      size: buttonSize,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      onAdd: () {},
                    ),
                    SizedBox(width: 16 * scale),

                    // Exercise (Mapped to Calories/Energy)
                    _QuickAction(
                      icon: Icons.directions_walk,
                      label: 'kcal',
                      current: widget.metrics?.activeEnergyBurned?.toInt().toString() ?? '0',
                      total: '500',
                      size: buttonSize,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      onAdd: () {},
                    ),
                    SizedBox(width: 16 * scale),

                    // Hydration Reminder (Mini Progress)
                    _HydrationAction(
                      size: buttonSize,
                      iconSize: iconSize,
                      fontSize: fontSize,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String current;
  final String total;
  final double size;
  final double iconSize;
  final double fontSize;
  final VoidCallback onAdd;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.current,
    required this.total,
    required this.size,
    required this.iconSize,
    required this.fontSize,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Material(
                color: Colors.white,
                elevation: 2,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onAdd,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: Icon(icon, size: iconSize * 1.2, color: Colors.grey.shade700),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: size * 0.35,
                  height: size * 0.35,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.purple.shade50, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: Colors.purple.shade600,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current / $total',
          style: TextStyle(fontSize: fontSize * 0.8, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _HydrationAction extends StatelessWidget {
  final double size;
  final double iconSize;
  final double fontSize;

  const _HydrationAction({
    required this.size,
    required this.iconSize,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress Circle
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 0.75,
                  strokeWidth: 4,
                  backgroundColor: Colors.purple.shade100,
                  color: Colors.purple.shade400,
                ),
              ),
              // Icon
              Icon(Icons.water_drop, size: iconSize, color: Colors.grey.shade700),
              // Play/Action indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow, size: iconSize * 0.6, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'In 3 h',
          style: TextStyle(fontSize: fontSize * 0.8, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}