// lib/features/health_metrics/presentation/pages/health_metrics_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_event.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_state.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/widgets/circular_score_card.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics_summary.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/widgets/horizontal_date_selector.dart';

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
      body: BlocConsumer<HealthMetricsBloc, HealthMetricsState>(
        listener: (context, state) {
          // Optional: show snackbars for errors
          if (state is HealthMetricsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Horizontal date selector
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: HorizontalDateSelector(
                  key: ValueKey(selectedDate),
                  initialDate: selectedDate,
                  daysBefore: 60,
                  daysAfter: DateTime.now().difference(selectedDate).inDays.abs(),
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

    // fallback
    return const SizedBox.shrink();
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.health_and_safety_outlined, size: 64, color: Colors.grey.shade400),
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
            onPressed: () => context.read<HealthMetricsBloc>().add(GetMetricsForDate(selectedDate)),
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
        Text('Failed to load metrics', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade300)),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Try again'),
            onPressed: () => context.read<HealthMetricsBloc>().add(GetMetricsForDate(selectedDate)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsView(BuildContext context, HealthMetricsSummary metrics) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Big circular progress / score card centered
        Center(
          child: SizedBox(
            height: 240,
            child: CircularScoreCard(
              metrics: metrics,
              goalSteps: 10000,
              fullCircle: false,
              showQuickActions: true,
              animateDuration: const Duration(milliseconds: 500),
              size: 250,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _buildSummaryGrid(metrics),
        const SizedBox(height: 18),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details', style: theme.textTheme.titleMedium),
                const Divider(),
                const SizedBox(height: 6),
                _infoRow(Icons.directions_walk, 'Steps', metrics.steps.toString(), context),
                const SizedBox(height: 8),
                _infoRow(Icons.favorite, 'Resting heart rate', metrics.heartRate != null ? '${metrics.heartRate!.toStringAsFixed(1)} bpm' : 'N/A', context),
                const SizedBox(height: 8),
                _infoRow(Icons.line_weight, 'Weight', metrics.weight != null ? '${metrics.weight!.toStringAsFixed(1)} kg' : 'N/A', context),
                const SizedBox(height: 8),
                _infoRow(Icons.height, 'Height', metrics.height != null ? '${metrics.height!.toStringAsFixed(1)} cm' : 'N/A', context),
                const SizedBox(height: 8),
                _infoRow(Icons.local_fire_department, 'Active energy', metrics.activeEnergyBurned != null ? '${metrics.activeEnergyBurned!.toStringAsFixed(0)} kcal' : 'N/A', context),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: SizedBox(
            height: 160,
            child: Center(
              child: Text('Trends & charts (coming soon)', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSummaryGrid(HealthMetricsSummary metrics) {
    final entries = <_SummaryTileData>[
      _SummaryTileData('Steps', metrics.steps.toString(), Icons.directions_walk, Colors.blue),
      _SummaryTileData('Calories', metrics.activeEnergyBurned?.toStringAsFixed(0) ?? 'N/A', Icons.local_fire_department, Colors.orange),
      _SummaryTileData('Heart Rate', metrics.heartRate != null ? '${metrics.heartRate!.round()} bpm' : 'N/A', Icons.favorite, Colors.red),
      _SummaryTileData('Water', metrics.water?.toString() ?? 'N/A', Icons.local_drink, Colors.teal),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 92, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (context, idx) {
        final e = entries[idx];
        return _SummaryTile(data: e);
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String val, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 12),
        Text(val, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

class _SummaryTileData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  _SummaryTileData(this.title, this.value, this.icon, this.color);
}

class _SummaryTile extends StatelessWidget {
  final _SummaryTileData data;
  const _SummaryTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: data.color.withOpacity(0.12),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(data.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(data.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
