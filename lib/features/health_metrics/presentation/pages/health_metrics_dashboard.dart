// lib/features/health_metrics/presentation/pages/health_metrics_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../../../core/injection_container.dart';
import '../../../auth/auth.dart';

import '../bloc/bloc.dart';
import '../widgets/widgets.dart';
import '../../domain/entities/entities.dart';

import '../../../sleep/presentation.dart';
import '../../../hydration/presentation.dart';
import '../../../meals/presentation.dart';
import '../../../activity/presentation/pages/activity_report_page.dart';
import '../../../activity/presentation/bloc/activity_bloc.dart';
import '../../../activity/presentation/bloc/activity_event.dart';

class HealthMetricsDashboard extends StatefulWidget {
  const HealthMetricsDashboard({super.key});

  @override
  State<HealthMetricsDashboard> createState() => _HealthMetricsDashboardState();
}

class _HealthMetricsDashboardState extends State<HealthMetricsDashboard>
    with WidgetsBindingObserver {
  String _activeTab = 'home';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger initial fetch when dashboard mounts
    context.read<HealthMetricsBloc>().add(GetMetricsForDate(DateTime.now()));
    // Automatically trigger restore/sync on load (safe check for empty local data)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<HealthMetricsBloc>().add(const RestoreAllData());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh metrics when returning from settings/background
      // But only if this page is actually visible (top of stack)
      // If we are in Detail Page, that page will handle its own lifecycle if needed.
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        context.read<HealthMetricsBloc>().add(
          GetMetricsForDate(DateTime.now()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _activeTab == 'home',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _activeTab = 'home';
        });
      },
      child: BlocListener<HealthMetricsBloc, HealthMetricsState>(
        listener: (context, state) {
          if (state is HealthMetricsPermissionRequired) {
            showDialog(
              context: context,
              builder: (ctx) => const PermissionRequiredDialog(),
            );
          } else if (state is HealthMetricsHealthConnectRequired) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const HealthConnectInstallDialog(),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
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
                child: CustomBottomNavigationBar(
                  activeTab: _activeTab,
                  onTabSelected: (tab) => setState(() => _activeTab = tab),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_activeTab != 'home') return null; // Or custom app bars for other tabs

    return AppBar(
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(
          'Home',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24.0),
          child: BlocBuilder<HealthMetricsBloc, HealthMetricsState>(
            builder: (context, state) {
              final bool isSyncing =
                  state is HealthMetricsSyncing ||
                  (state is HealthMetricsLoaded && state.isSyncing);

              if (isSyncing) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 0.1,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 217, 214, 214),
                      ),
                    ),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD9D9D9),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('assets/images/user_avatar.png'),
                ),
              );
            },
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

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size;

    // Calculate Vertical Center of the Card to align background
    // StatusBar + HeaderPadding(16) + HeaderHeight(56 approx) + Spacing(20) + CardRadius(240/2)
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double cardCenterY = statusBarHeight + 16 + 56 + 20 + (240 / 2);

    return BlocBuilder<HealthMetricsBloc, HealthMetricsState>(
      builder: (context, state) {
        HealthMetricsSummary? metrics;
        int mealCount = 0;
        int mealGoal = 3;
        double waterConsumed = 0;
        double waterGoal = 3.2;

        if (state is HealthMetricsLoaded) {
          metrics = state.summary;
          mealCount = state.mealCount;
          mealGoal = state.mealGoal;
          waterConsumed = state.waterConsumed;
          waterGoal = state.waterGoal;
        }

        // Persistent Permission State UI
        if (state is HealthMetricsPermissionRequired) {
          return PermissionRequiredView(
            cardCenterY: cardCenterY,
            size: size,
            primaryColor: primaryColor,
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Stack(
            children: [
              // Main Scrollable Content

              // Main Scrollable Content
              RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  // Trigger sync manually
                  context.read<HealthMetricsBloc>().add(const RefreshMetrics());
                  // Wait briefly for UI feel or until state changes (handled by bloc)
                  await Future.delayed(const Duration(milliseconds: 1500));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top:
                        MediaQuery.of(context).padding.top +
                        2, // approximate header space
                  ),
                  child: Column(
                    children: [
                      // Hint text
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -85 - (size.height * 1.2 / 2),
                            left: 0,
                            right: 0,
                            height: size.height * 1.2,
                            child: ClipPath(
                              clipper: _RippleBoxClipper(),
                              child: Container(
                                color: AppTheme.rippleBackground.withOpacity(
                                  0.3,
                                ),
                                child: CustomPaint(
                                  painter: RippleBackgroundPainter(
                                    color: primaryColor.withOpacity(0.05),
                                    centerOffset: const Offset(
                                      0,
                                      205,
                                    ), // Align ripple center to ScoreCard
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                CircularScoreCard(
                                  metrics: metrics,
                                  goalSteps: 10000,
                                  size: 240,
                                  animateDuration: const Duration(
                                    milliseconds: 700,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 0,
                                        ), // Highest point (outer)
                                        child: GestureDetector(
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                settings: const RouteSettings(
                                                  name:
                                                      MealReportPage.routeName,
                                                ),
                                                builder: (context) =>
                                                    BlocProvider.value(
                                                      value: sl<MealBloc>(),
                                                      child:
                                                          const MealReportPage(),
                                                    ),
                                              ),
                                            );
                                            if (context.mounted) {
                                              context
                                                  .read<HealthMetricsBloc>()
                                                  .add(const RefreshMetrics());
                                            }
                                          },
                                          child: _StatItem(
                                            icon: Icons.restaurant,
                                            sub: '+',
                                            val: '$mealCount/$mealGoal',
                                            unit: '',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 40,
                                        ), // Lower point (inner)
                                        child: GestureDetector(
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                settings: const RouteSettings(
                                                  name: HydrationReportPage
                                                      .routeName,
                                                ),
                                                builder: (context) =>
                                                    BlocProvider.value(
                                                      value:
                                                          sl<HydrationBloc>(),
                                                      child:
                                                          const HydrationReportPage(),
                                                    ),
                                              ),
                                            );
                                            if (context.mounted) {
                                              context
                                                  .read<HealthMetricsBloc>()
                                                  .add(const RefreshMetrics());
                                            }
                                          },
                                          child: _StatItem(
                                            icon: Icons.water_drop,
                                            sub: '+',
                                            val:
                                                '${waterConsumed.toStringAsFixed(1)}/${waterGoal.toStringAsFixed(1)}',
                                            unit: 'l', // Fixed unit letter
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 40,
                                        ), // Lower point (inner)
                                        child: GestureDetector(
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                settings: const RouteSettings(
                                                  name: ActivityReportPage
                                                      .routeName,
                                                ),
                                                builder: (context) => MultiBlocProvider(
                                                  providers: [
                                                    BlocProvider<ActivityBloc>(
                                                      create: (context) =>
                                                          sl<ActivityBloc>()..add(
                                                            LoadActivitiesForDate(
                                                              DateTime.now(),
                                                            ),
                                                          ),
                                                    ),
                                                    BlocProvider<
                                                      HealthMetricsBloc
                                                    >(
                                                      create: (context) =>
                                                          sl<
                                                              HealthMetricsBloc
                                                            >()
                                                            ..add(
                                                              GetMetricsForDate(
                                                                DateTime.now(),
                                                              ),
                                                            ),
                                                    ),
                                                  ],
                                                  child:
                                                      const ActivityReportPage(),
                                                ),
                                              ),
                                            );
                                            if (context.mounted) {
                                              context
                                                  .read<HealthMetricsBloc>()
                                                  .add(const RefreshMetrics());
                                            }
                                          },
                                          child: _StatItem(
                                            icon: Icons.directions_run,
                                            sub: '+',
                                            val:
                                                '0/${(metrics?.activeEnergyBurned?.value ?? 60).toInt()}',
                                            unit: 'min',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 0,
                                        ), // Highest point (outer)
                                        child: GestureDetector(
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                settings: const RouteSettings(
                                                  name: SleepPage.routeName,
                                                ),
                                                builder: (context) =>
                                                    BlocProvider<SleepBloc>(
                                                      create: (context) =>
                                                          sl<SleepBloc>(),
                                                      child: const SleepPage(),
                                                    ),
                                              ),
                                            );
                                            if (context.mounted) {
                                              context
                                                  .read<HealthMetricsBloc>()
                                                  .add(const RefreshMetrics());
                                            }
                                          },
                                          child: _StatItem(
                                            icon:
                                                Icons.brightness_3, // Moon icon
                                            sub: '+',
                                            val: 'In 3 h',
                                            unit: '',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Check-in Card
                      // const CheckInCard(),
                    ],
                  ),
                ),
              ),
            ],
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
    final primaryColor = Theme.of(context).primaryColor;
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
                        style: TextStyle(
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

class _RippleBoxClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Calculate vertical reference points based on the center of the ripple
    // Center is at size.height / 2
    // We want the curve to drop down to cover the buttons.
    // ScoreCard center Y is 120 (relative to stack top)
    // Background center Y is 120 (relative to stack top)
    // Buttons are roughly at Stack Y=400 area.
    // Stack Y 400 corresponds to Painter Y = 400 - (120 - H/2) = 280 + H/2
    // Let's rely on relative sizing to center.

    final centerY = size.height / 2;
    final curveBottomY = centerY + 350; // Use reasonable offset

    path.lineTo(0, curveBottomY - 150); // Start of curve at sides

    path.cubicTo(
      size.width * 0.35,
      curveBottomY + 100, // Control Point 1
      size.width * 0.65,
      curveBottomY - 150, // Control Point 2
      size.width,
      -100, // Go way up
    );
    // Wait, the previous cubic wasn't symmetric.
    // Previous: 0,650 -> (350,870) -> (650,650) -> (1000, -1800)
    // It swoops down then up-right.
    // Let's replicate the swoop but responsive.

    // 0, SideHeight
    // C1 (W*0.35, BottomDepth)
    // C2 (W*0.65, SideHeight)
    // End (W, -TopDepth)

    // We need to cover the buttons on the right side too.
    // Previous endDepth was -size.height (way up), creating a steep diagonal.
    // We'll lower the endDepth to be closer to 0 (top of view) or even positive,
    // to flatten the curve and ensure it stays behind the right-side buttons.

    // Reverted to standardized symmetric U-shape (pre-adjustment).
    // Start/End at 350, Depth at 450 for wide coverage.

    final startHeight = centerY + 350;
    final endHeight = centerY + 350;
    final controlDepth = centerY + 450;

    path.reset();
    path.lineTo(0, startHeight);
    path.cubicTo(
      size.width * 0.25, // C1 X
      controlDepth, // C1 Y
      size.width * 0.75, // C2 X
      controlDepth, // C2 Y
      size.width, // End X
      endHeight, // End Y
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
