// lib/features/health_metrics/presentation/pages/health_metrics_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_event.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_state.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics_summary.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/widgets/horizontal_date_selector.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/widgets/metric_card.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/widgets/empty_metrics_state.dart';

class HealthMetricsPage extends StatefulWidget {
  const HealthMetricsPage({super.key});

  @override
  State<HealthMetricsPage> createState() => _HealthMetricsPageState();
}

class _HealthMetricsPageState extends State<HealthMetricsPage> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    // Dispatch initial load for today's date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthMetricsBloc>().add(GetMetricsForDate(selectedDate));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<HealthMetricsBloc, HealthMetricsState>(
          listener: (context, state) {
            // Optional: show snackbars for errors
            if (state is HealthMetricsError) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.arrow_back, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Health Metrics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Horizontal date selector
                Padding(
                  padding: const EdgeInsets.only(
                      top:
                          0.0), // Removed top padding as header provides spacing
                  child: HorizontalDateSelector(
                    initialDate: selectedDate,
                    daysBefore: 60,
                    daysAfter:
                        DateTime.now().difference(selectedDate).inDays.abs(),
                    onDateSelected: (d) {
                      setState(() => selectedDate = d);
                      // UI event + load data for date
                      context.read<HealthMetricsBloc>().add(SelectDate(d));
                    },
                  ),
                ),

                // Main content with pull-to-refresh
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _handleRefresh(context),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _buildStateContent(context, state),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final bloc = context.read<HealthMetricsBloc>();

    // Create a completer that completes when the bloc emits a non-loading state.
    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = bloc.stream.listen((s) {
      if (s is! HealthMetricsLoading) {
        if (!completer.isCompleted) completer.complete();
      }
    });

    // Trigger refresh (this will add GetMetrics with forceRefresh in the bloc)
    bloc.add(const RefreshMetrics());

    try {
      // wait for the completer, with a timeout to avoid hanging UI
      await completer.future.timeout(const Duration(seconds: 10));
    } catch (_) {
      // ignore timeout but ensure we clean up subscription
    } finally {
      await sub.cancel();
    }
  }

  Widget _buildStateContent(BuildContext context, HealthMetricsState state) {
    if (state is HealthMetricsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is HealthMetricsError) {
      return _buildError(state.message);
    }

    if (state is HealthMetricsEmpty) {
      return _buildEmpty();
    }

    if (state is HealthMetricsLoaded) {
      if (state.summary != null) {
        return _buildMetricsView(context, state.summary!);
      }
      // If loaded but no summary, show empty
      return _buildEmpty();
    }

    if (state is HealthMetricsCachedLoaded) {
      // show cached then allow refresh
      final summary = HealthMetricsSummary.fromMap(
        // If you have MetricAggregator elsewhere, you can compute summary; here we just build minimal
        // For safety, create a simple summary from available metrics (mock/light)
        // But if you prefer to wait for live data, simply show the cached metrics list
        // We'll show empty summary placeholder
        <String, dynamic>{},
        selectedDate,
      );
      return _buildMetricsView(context, summary);
    }

    if (state is HealthMetricsPermissionRequired) {
      return _buildPermissionRequired();
    }

    // fallback
    return const SizedBox.shrink();
  }

  Widget _buildPermissionRequired() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.security, size: 64, color: Colors.orange.shade400),
        const SizedBox(height: 20),
        Text('Permissions Required',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
            'To track your health metrics, we need permission to access Health Connect data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Grant Permissions'),
            onPressed: () {
              // Triggering GetMetricsForDate will re-run _ensurePermissions in the datasource
              context
                  .read<HealthMetricsBloc>()
                  .add(GetMetricsForDate(selectedDate));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: EmptyMetricsState(
        title: 'No Health Data Yet',
        message:
            'Tap refresh or allow Health permissions to start collecting data.',
        icon: Icons.health_and_safety_outlined,
        actionLabel: 'Fetch Now',
        onAction: () => context
            .read<HealthMetricsBloc>()
            .add(GetMetricsForDate(selectedDate)),
      ),
    );
  }

  Widget _buildError(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
        const SizedBox(height: 20),
        Text('Failed to load metrics',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade300)),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Try again'),
            onPressed: () => context
                .read<HealthMetricsBloc>()
                .add(GetMetricsForDate(selectedDate)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsView(BuildContext context, HealthMetricsSummary metrics) {
    // define configurations
    final metricsConfig = [
      _MetricConfig(
        label: 'Steps',
        icon: Icons.directions_walk,
        selector: (s) => s.steps,
        formatter: (val, unit) => '${val.round()} $unit',
      ),
      _MetricConfig(
        label: 'Active Energy',
        icon: Icons.local_fire_department_rounded,
        selector: (s) => s.activeEnergyBurned,
        formatter: (val, unit) => '${val.round()} $unit',
      ),
      _MetricConfig(
        label: 'Flights Climbed',
        icon: Icons.stairs_rounded,
        selector: (s) => s.flightsClimbed,
        formatter: (val, unit) => '${val.round()}',
      ),
      _MetricConfig(
        label: 'Sleep (Asleep)',
        icon: Icons.bedtime_rounded,
        selector: (s) => s.sleepAsleep,
        formatter: (val, unit) => '${(val / 60).toStringAsFixed(1)} hr',
      ),
      _MetricConfig(
        label: 'Sleep (Awake)',
        icon: Icons.wb_sunny_rounded,
        selector: (s) => s.sleepAwake,
        formatter: (val, unit) => '${(val / 60).toStringAsFixed(1)} hr',
      ),
      _MetricConfig(
        label: 'Water',
        icon: Icons.water_drop_rounded,
        selector: (s) => s.water,
        formatter: (val, unit) => '${val.toStringAsFixed(1)} $unit',
      ),
      _MetricConfig(
        label: 'Heart Rate',
        icon: Icons.favorite_rounded,
        selector: (s) => s.heartRate,
        formatter: (val, unit) => '${val.round()} BPM',
      ),
      _MetricConfig(
        label: 'Blood Pressure (Sys)',
        icon: Icons.compress,
        selector: (s) => s.bloodPressureSystolic,
        formatter: (val, unit) => '${val.round()} mmHg',
      ),
      _MetricConfig(
        label: 'Blood Pressure (Dia)',
        icon: Icons.compress_outlined,
        selector: (s) => s.bloodPressureDiastolic,
        formatter: (val, unit) => '${val.round()} mmHg',
      ),
      _MetricConfig(
        label: 'Weight',
        icon: Icons.monitor_weight_rounded,
        selector: (s) => s.weight,
        formatter: (val, unit) => '${val.toStringAsFixed(1)} $unit',
      ),
      _MetricConfig(
        label: 'Basal Energy',
        icon: Icons.battery_charging_full_rounded,
        selector: (s) => s.basalEnergyBurned,
        formatter: (val, unit) => '${val.round()} $unit',
      ),
      _MetricConfig(
        label: 'Body Fat',
        icon: Icons.accessibility_new_rounded,
        selector: (s) => s.bodyFatPercentage,
        formatter: (val, unit) => '${val.toStringAsFixed(1)}%',
      ),
      _MetricConfig(
        label: 'Body Temp',
        icon: Icons.thermostat_rounded,
        selector: (s) => s.bodyTemperature,
        formatter: (val, unit) => '${val.toStringAsFixed(1)} °C',
      ),
      _MetricConfig(
        label: 'Blood Glucose',
        icon: Icons.bloodtype_rounded,
        selector: (s) => s.bloodGlucose,
        formatter: (val, unit) => '${val.round()} $unit',
      ),
      _MetricConfig(
        label: 'Height',
        icon: Icons.height_rounded,
        selector: (s) => s.height,
      ),
      _MetricConfig(
        label: 'Sleep (Deep)',
        icon: Icons.bedtime_outlined,
        selector: (s) => s.sleepDeep,
        formatter: (val, unit) => '${(val / 60).toStringAsFixed(1)} hr',
      ),
      _MetricConfig(
        label: 'Sleep (REM)',
        icon: Icons.psychology_rounded,
        selector: (s) => s.sleepRem,
        formatter: (val, unit) => '${(val / 60).toStringAsFixed(1)} hr',
      ),
      _MetricConfig(
        label: 'Blood Oxygen',
        icon: Icons.air,
        selector: (s) => s.bloodOxygen,
        formatter: (val, unit) => '${val.round()}%',
      ),
    ];

    try {
      // Filter and build
      final availableMetrics = metricsConfig.where((config) {
        try {
          final m = config.selector(metrics);
          return m != null && m.value > 0;
        } catch (e) {
          debugPrint('Error selecting metric ${config.label}: $e');
          return false;
        }
      }).toList();

      if (availableMetrics.isEmpty) {
        return EmptyMetricsState(
          title: 'No Data for This Day',
          message:
              'It seems there are no recorded metrics for this selected date.',
          icon: Icons.insert_chart_outlined_rounded,
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: availableMetrics.length + 1, // +1 for spacing at bottom
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          if (index == availableMetrics.length) {
            return const SizedBox(height: 40);
          }

          final config = availableMetrics[index];
          final metricInfo = config.selector(metrics)!;

          return MetricCard(
            title: config.label,
            value: config.formatter(metricInfo.value, metricInfo.unit),
            icon: config.icon,
          );
        },
      );
    } catch (e, st) {
      debugPrint('Error building metrics list: $e\n$st');
      return Center(child: Text('Error displaying metrics: $e'));
    }
  }

  static String timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.yMMMd().format(t);
  }
}

class _MetricConfig {
  final String label;
  final IconData icon;
  final MetricValue? Function(HealthMetricsSummary) selector;
  final String Function(double value, String unit) formatter;

  _MetricConfig({
    required this.label,
    required this.icon,
    required this.selector,
    String Function(double, String)? formatter,
  }) : formatter = formatter ?? ((val, unit) => '$val $unit');
}
