// lib/features/health_metrics/presentation/pages/health_metrics_dashboard.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_state.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics_summary.dart';
import 'package:bench_profile_app/features/auth/presentation/pages/profile_page.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/pages/health_metrics_page.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_event.dart';

class HealthMetricsDashboard extends StatefulWidget {
  const HealthMetricsDashboard({super.key});

  @override
  State<HealthMetricsDashboard> createState() => _HealthMetricsDashboardState();
}

class _HealthMetricsDashboardState extends State<HealthMetricsDashboard> {
  String _activeTab = 'home';

  @override
  void initState() {
    super.initState();
    // Trigger initial fetch when dashboard mounts
    context.read<HealthMetricsBloc>().add(GetMetricsForDate(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HealthMetricsBloc, HealthMetricsState>(
      listener: (context, state) {
        if (state is HealthMetricsPermissionRequired) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Permission Required',
                style: TextStyle(
                  color: Color(0xFFEE374D),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'To track your progress, this app needs access to your health data. Please grant the necessary permissions in settings.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE374D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: _buildAppBar(),
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
                        // margin: const EdgeInsets.only(bottom: 24),
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
                              fontFamily:
                                  'serif', // Trying to match the H style roughly
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
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_activeTab != 'home') return null; // Or custom app bars for other tabs

    return AppBar(
      automaticallyImplyLeading: false,
      title: const Padding(
        padding: EdgeInsets.only(left: 8.0),
        child: Text(
          'Home',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEE374D),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24.0),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color.fromRGBO(226, 146, 146, 1),
            backgroundImage:
                const NetworkImage('https://i.pravatar.cc/150?img=32'),
          ),
        ),
      ],
      backgroundColor: Colors.transparent, // Let body color show or use white
      elevation: 0,
      scrolledUnderElevation: 0,
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
    final size = MediaQuery.of(context).size;

    // Calculate Vertical Center of the Card to align background
    // StatusBar + HeaderPadding(16) + HeaderHeight(56 approx) + Spacing(20) + CardRadius(240/2)
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double cardCenterY = statusBarHeight + 16 + 56 + 20 + (240 / 2);

    return BlocBuilder<HealthMetricsBloc, HealthMetricsState>(
      builder: (context, state) {
        HealthMetricsSummary? metrics;
        if (state is HealthMetricsLoaded) {
          metrics = state.summary;
        }

        // Persistent Permission State UI
        if (state is HealthMetricsPermissionRequired) {
          // Keep the background but replace content
          return Stack(
            children: [
              Positioned(
                top: cardCenterY - size.width,
                left: -size.width * 0.5,
                right: -size.width * 0.5,
                height: size.width * 1.65,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.08),
                      width: 1.5,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        Color.fromARGB(255, 207, 2, 153).withOpacity(0.04),
                        Color.fromARGB(255, 16, 16, 16).withOpacity(0.0),
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 64, color: primaryColor.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Permissions Locked',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Health permissions are required to show your dashboard. Please grant them in settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () => openAppSettings(),
                        child: const Text('Open Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            // Massive Background Single Circle - Concentric with Card
            Positioned(
              top: cardCenterY - size.width, // CenterY - Radius
              left: -size.width * 0.5,
              right: -size.width * 0.5,
              height: size.width * 1.50, // Radius = width
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withOpacity(0.08),
                    width: 1.5,
                  ),
                  gradient: RadialGradient(
                    colors: [
                      Color.fromARGB(255, 207, 2, 153).withOpacity(0.04),
                      Color.fromARGB(255, 147, 21, 21).withOpacity(0.0),
                    ],
                    stops: const [0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Main Scrollable Content
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Header removed (moved to AppBar)
                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    // Circular Progress (Now smaller and tighter)
                    CircularScoreCard(
                      metrics: metrics,
                      goalSteps: 10000,
                      size:
                          240, // Reduced from 360 to wrap tightly around 160 button
                    ),

                    const SizedBox(height: 40), // Spacing to grid

                    // Stats Grid
                    // Stats Grid - Arced Layout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 0), // Highest point (outer)
                            child: _StatItem(
                              icon: Icons.restaurant,
                              sub: '+',
                              val: '0/3',
                              unit: '',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 40), // Lower point (inner)
                            child: _StatItem(
                              icon: Icons.water_drop,
                              sub: '+',
                              val:
                                  '${metrics?.water?.value.toStringAsFixed(1) ?? 0}/3.2',
                              unit: 'l',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 40), // Lower point (inner)
                            child: _StatItem(
                              icon: Icons.directions_run,
                              sub: '+',
                              val:
                                  '0/${(metrics?.activeEnergyBurned?.value ?? 60).toInt()}',
                              unit: 'min',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 0), // Highest point (outer)
                            child: _StatItem(
                              icon: Icons.calendar_today,
                              sub: '+',
                              val: 'In 3',
                              unit: 'h',
                            ),
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
                                  text:
                                      ' — built to work for you, without the stress or struggles. Enjoy easy progress every day and ',
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
            ),
          ],
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

class _CircularScoreCardState extends State<CircularScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: widget.animateDuration, vsync: this);
    _progressAnimation = Tween<double>(begin: 0, end: _progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CircularScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.metrics?.steps != oldWidget.metrics?.steps) {
      _progressAnimation =
          Tween<double>(begin: _progressAnimation.value, end: _progress)
              .animate(
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
    // if (steps == null || steps <= 0) return 0.0;
    return math.min(7000 / widget.goalSteps, 1.0);
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
            // Background Ripples
            // Background Gradient Circle (Larger than container to match design)
            // Background Ripples removed - now handled in parent Stack

            // White Container Background for progress

            // Container(
            //   width: widget.size * 1.95,
            //   height: widget.size * 1.95,
            //   decoration: const BoxDecoration(
            //       color: Color(0x99FFCED8), shape: BoxShape.circle),
            // ),

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
                      color: Colors.grey.shade200, // Lighter background
                      activeGradient: const LinearGradient(
                        colors: [Color(0xFFEE374D), Color(0xFFFF8A65)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      strokeWidth: 14, // Height of the pipe bars
                    ),
                  );
                },
              ),
            ),

            // Center Content - Circular Button
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HealthMetricsPage()),
                );
              },
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    Text('Start',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const Text(
                      'Logging',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                    Text('to score',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    if ((widget.metrics?.steps?.value ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${widget.metrics!.steps!.value.toInt()}',
                          style: const TextStyle(
                              color: primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
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
  final double strokeWidth; // Length of the pipe (radial height)

  _DashedCirclePainter({
    required this.progress,
    required this.color,
    this.activeGradient,
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
      activePaint.shader = activeGradient!
          .createShader(Rect.fromCircle(center: center, radius: radius));
    } else {
      activePaint.color = const Color(0xFFEE374D);
    }

    // Draw Loop
    for (int i = 0; i < totalPipes; i++) {
      final double currentAngle = startAngleRad + (i * stepAngle);
      final bool isActive = (i / (totalPipes - 1)) <= progress;

      // Calculate radial line segment
      // We want the pipe to be centered on 'radius' circle, with length 'strokeWidth'
      final double innerR = radius - (strokeWidth / 2);
      final double outerR = radius + (strokeWidth / 2);

      final p1 = Offset(center.dx + innerR * math.cos(currentAngle),
          center.dy + innerR * math.sin(currentAngle));
      final p2 = Offset(center.dx + outerR * math.cos(currentAngle),
          center.dy + outerR * math.sin(currentAngle));

      canvas.drawLine(p1, p2, isActive ? activePaint : backgroundPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
