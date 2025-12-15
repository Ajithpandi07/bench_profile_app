// lib/features/health_metrics/presentation/pages/health_metrics_dashboard.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_state.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics_summary.dart';
import 'package:bench_profile_app/features/auth/presentation/pages/profile_page.dart';

class HealthMetricsDashboard extends StatefulWidget {
  const HealthMetricsDashboard({super.key});

  @override
  State<HealthMetricsDashboard> createState() => _HealthMetricsDashboardState();
}

class _HealthMetricsDashboardState extends State<HealthMetricsDashboard> {
  String _activeTab = 'home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          // Main Content Area
          Positioned.fill(
            bottom: 80, // Space for bottom nav
            child: _buildBody(),
          ),

          // Custom Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    isActive: _activeTab == 'home',
                    onTap: () => setState(() => _activeTab = 'home'),
                  ),
                  _NavItem(
                    icon: Icons.favorite_border_rounded,
                    isActive: _activeTab == 'heart',
                    onTap: () => setState(() => _activeTab = 'heart'),
                  ),
                    // Center Add Button
                  GestureDetector(
                    onTap: () => setState(() => _activeTab = 'add'),
                    child: Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEE374D),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEE374D).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'H',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'serif', // Trying to match the H style roughly
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    isActive: _activeTab == 'message',
                    onTap: () => setState(() => _activeTab = 'message'),
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    isActive: _activeTab == 'settings',
                    onTap: () => setState(() => _activeTab = 'settings'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_activeTab) {
      case 'home':
        return const _HomeTab();
      case 'settings':
        return BlocBuilder<HealthMetricsBloc, HealthMetricsState>(
          builder: (context, state) {
            HealthMetricsSummary? metrics;
            if (state is HealthMetricsLoaded) {
              metrics = state.summary;
            }
            return ProfilePage(metrics: metrics);
          },
        );
      default:
        return Center(
          child: Text(
            _activeTab.toUpperCase(),
            style: const TextStyle(fontSize: 24, color: Colors.grey),
          ),
        );
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: isActive ? const Color(0xFFEE374D) : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFEE374D);

    return BlocBuilder<HealthMetricsBloc, HealthMetricsState>(
      builder: (context, state) {
        HealthMetricsSummary? metrics;
        if (state is HealthMetricsLoaded) {
          metrics = state.summary;
        } else if (state is HealthMetricsCachedLoaded) {
          // Try to construct a summary or use cached data if available in state
          // For now, we'll just use null or empty
        }

        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=32'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Circular Progress
                CircularScoreCard(
                  metrics: metrics,
                  goalSteps: 10000,
                  size: 280,
                ),

                const SizedBox(height: 32),

                // Stats Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatItem(
                        icon: Icons.restaurant,
                        sub: '+',
                        val: '0/3',
                        unit: '',
                      ),
                      _StatItem(
                        icon: Icons.water_drop,
                        sub: '+',
                        val: '${metrics?.water?.toStringAsFixed(1) ?? 0}/3.2',
                        unit: 'l',
                      ),
                      _StatItem(
                        icon: Icons.directions_run,
                        sub: '+',
                        val: '0/${(metrics?.activeEnergyBurned ?? 60).toInt()}',
                        unit: 'min',
                      ),
                      _StatItem(
                        icon: Icons.calendar_today,
                        sub: '+',
                        val: 'In 3',
                        unit: 'h',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Check-in Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CHECK-IN',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Unlock your daily plan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: ' — built to work for you, without the stress or struggles. Enjoy easy progress every day and ',
                            ),
                            TextSpan(
                              text: 'reach your goals faster',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {},
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🔓', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text(
                                'Unlock with Premium',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Today's Plan
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Today's Plan",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String sub;
  final String val;
  final String unit;

  const _StatItem({
    required this.icon,
    required this.sub,
    required this.val,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFEE374D);
    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 64, // Extra height for the badge
          child: Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        sub,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            children: [
              TextSpan(
                text: val,
                style: const TextStyle(color: Colors.black54),
              ),
              if (unit.isNotEmpty) ...[
                const TextSpan(text: ' '),
                TextSpan(text: unit),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

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

class _CircularScoreCardState extends State<CircularScoreCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.animateDuration, vsync: this);
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
    if (steps == null || steps <= 0) return 0.0;
    return math.min(steps / widget.goalSteps, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFEE374D);

    return ClipOval(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Gradient Circle (Larger than container to match design)
            // Background Ripples
            ...List.generate(4, (index) {
              final scale = 1.0 + (index * 0.25);
              final opacity = 0.05 - (index * 0.01);
              return Positioned(
                width: widget.size * scale,
                height: widget.size * scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFCED8).withOpacity(opacity > 0 ? opacity : 0.01),
                      width: 1,
                    ),
                    gradient: index == 0 ? RadialGradient(
                      colors: [
                        const Color(0xFFFFCED8).withOpacity(0.4),
                        Colors.white.withOpacity(0.0),
                      ],
                    ) : null,
                  ),
                ),
              );
            }),
            
            // White Container Background for progress
            Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
               ),
             ),

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
                      color: Colors.grey.shade300,
                      activeColor: primaryColor,
                      strokeWidth: 3,
                    ),
                  );
                },
              ),
            ),

            // Center Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Start', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const Text(
                  'Logging',
                  style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w500),
                ),
                Text('to score', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                if ((widget.metrics?.steps ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${widget.metrics!.steps}',
                      style: const TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
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
  final Color activeColor;
  final double strokeWidth;

  _DashedCirclePainter({
    required this.progress,
    required this.color,
    required this.activeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Dashed pattern: 8px dash, 6px gap
    const dashWidth = 8.0;
    const dashSpace = 6.0;

    // Draw background
    _drawDashedArc(canvas, center, radius, 0, 2 * math.pi, color, dashWidth, dashSpace);

    // Draw progress
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      // Start from top (-pi/2)
      _drawDashedArc(canvas, center, radius, -math.pi / 2, sweepAngle, activeColor, dashWidth, dashSpace);
    }
  }

  void _drawDashedArc(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, Color color,
      double dashWidth, double dashSpace) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double currentAngle = startAngle;
    final endAngle = startAngle + sweepAngle;

    // Convert dash width/space to radians
    final dashRad = dashWidth / radius;
    final spaceRad = dashSpace / radius;

    while (currentAngle < endAngle) {
      final drawLen = math.min(dashRad, endAngle - currentAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        drawLen,
        false,
        paint,
      );
      currentAngle += drawLen + spaceRad;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}