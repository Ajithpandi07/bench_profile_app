// lib/features/health_metrics/presentation/pages/health_metrics_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/core.dart';
import '../../../auth/auth.dart';

import '../bloc/bloc.dart';
import '../widgets/widgets.dart';
import '../../domain/entities/entities.dart';

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
    // Automatically trigger restore/sync on load (delayed to allow initial load to settle)
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
        context
            .read<HealthMetricsBloc>()
            .add(GetMetricsForDate(DateTime.now()));
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
              final bool isSyncing = state is HealthMetricsSyncing ||
                  (state is HealthMetricsLoaded && state.isSyncing);

              if (isSyncing) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromARGB(255, 19, 19, 19)),
                    ),
                  ),
                );
              }
              return CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryLight,
                child: Builder(
                  builder: (context) {
                    String initial = 'U';
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user?.email?.isNotEmpty == true) {
                        initial = user!.email![0].toUpperCase();
                      }
                    } catch (_) {}

                    return Text(
                      initial,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 19, 19, 19),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  },
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
        if (state is HealthMetricsLoaded) {
          metrics = state.summary;
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
                        Color.fromARGB(255, 207, 2, 153).withOpacity(
                            0.08), // Increased opacity for visibility
                        Color.fromARGB(255, 147, 21, 21).withOpacity(0.02),
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: cardCenterY - size.width * 1, // CenterY - Radius
                left: -size.width * 0.5,
                right: -size.width * 0.5,
                height: size.width * 1.31, // Radius = width
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Main Scrollable Content
              SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () async {
                    // Trigger sync manually
                    context
                        .read<HealthMetricsBloc>()
                        .add(const RefreshMetrics());
                    // Wait briefly for UI feel or until state changes (handled by bloc)
                    await Future.delayed(const Duration(milliseconds: 1500));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Hint text

                        // Header removed (moved to AppBar)
                        const SizedBox(height: 20),

                        const SizedBox(height: 20),

                        // Circular Progress (Now smaller and tighter)
                        CircularScoreCard(
                          metrics: metrics,
                          goalSteps: 10000,
                          size:
                              240, // Reduced from 360 to wrap tightly around 160 button
                          animateDuration: const Duration(milliseconds: 700),
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

                        // Check-in Card
                        // const CheckInCard(),
                      ],
                    ),
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
