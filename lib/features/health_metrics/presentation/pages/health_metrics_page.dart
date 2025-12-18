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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.health_and_safety_outlined,
            size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 20),
        Text(
          'No health data yet',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap refresh or allow Health permissions to start collecting data.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Fetch now'),
            onPressed: () => context
                .read<HealthMetricsBloc>()
                .add(GetMetricsForDate(selectedDate)),
          ),
        ),
      ],
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        MetricCard(
          title: 'Steps',
          value: '${metrics.steps}',
          icon: Icons.directions_walk,
        ),
        MetricCard(
          title: 'Heart Rate',
          value: metrics.heartRate != null
              ? '${metrics.heartRate!.round()} bpm'
              : 'N/A',
          icon: Icons.favorite_rounded,
        ),
        MetricCard(
          title: 'Active Energy',
          value: metrics.activeEnergyBurned != null
              ? '${metrics.activeEnergyBurned!.round()} kcal'
              : 'N/A',
          icon: Icons.local_fire_department_rounded,
        ),
        MetricCard(
          title: 'Water',
          value: '${metrics.water?.toStringAsFixed(1) ?? 0} L',
          icon: Icons.water_drop_rounded,
        ),
        MetricCard(
          title: 'Weight',
          value: metrics.weight != null ? '${metrics.weight} kg' : 'N/A',
          icon: Icons.monitor_weight_rounded,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  static String timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.yMMMd().format(t);
  }
}
