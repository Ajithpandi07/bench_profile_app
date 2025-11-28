// lib/features/health_metrics/presentation/pages/health_metrics_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_event.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_state.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/widgets/circular_score_card.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/widgets/horizontal_date_selector.dart';


class HealthMetricsPage extends StatefulWidget {
  const HealthMetricsPage({super.key});

  @override
  State<HealthMetricsPage> createState() => _HealthMetricsPageState();
}

class _HealthMetricsPageState extends State<HealthMetricsPage> {
  late DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    // dispatch fetch for today's date after first frame (context ready)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthMetricsBloc>().add(GetMetricsForDate(selectedDate));
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() => selectedDate = date);
    // dispatch the date-aware event
    context.read<HealthMetricsBloc>().add(GetMetricsForDate(date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Metrics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            wordSpacing: 2.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Top: horizontal date selector
          HorizontalDateSelector(
            initialDate: selectedDate,
            daysBefore: 60,
            daysAfter: 0,
            onDateSelected: _onDateSelected,
          ),

          // Subtitle / selected date label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              children: [
                Text(
                  DateFormat.yMMMMd().format(selectedDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // jump to today
                    final today = DateTime.now();
                    _onDateSelected(DateTime(today.year, today.month, today.day));
                  },
                  icon: const Icon(Icons.today, size: 18),
                  label: const Text('Today'),
                ),
              ],
            ),
          ),

          // Content area (bloc driven)
          Expanded(
            child: BlocBuilder<HealthMetricsBloc, HealthMetricsState>(
              builder: (context, state) {
                if (state is HealthMetricsEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Press the refresh button to fetch health data.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<HealthMetricsBloc>().add(GetMetricsForDate(selectedDate)),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                } else if (state is HealthMetricsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is HealthMetricsLoaded) {
                  final HealthMetrics metrics = state.metrics;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Circular card — constrain height for consistent layout
                        SizedBox(
                          height: 220,
                          child: CircularScoreCard(
                            metrics: metrics,
                            goalSteps: 10000,
                            fullCircle: false,
                            showQuickActions: true,
                            animateDuration: const Duration(milliseconds: 700),
                            size: 180,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Card with details
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailRow('Steps', metrics.steps.toString()),
                                const SizedBox(height: 8),
                                _detailRow('Heart Rate', metrics.heartRate != null ? '${metrics.heartRate!.toStringAsFixed(1)} bpm' : 'N/A'),
                                const SizedBox(height: 8),
                                _detailRow('Weight', metrics.weight != null ? '${metrics.weight!.toStringAsFixed(1)} kg' : 'N/A'),
                                const SizedBox(height: 8),
                                _detailRow('Height', metrics.height != null ? '${metrics.height!.toStringAsFixed(1)} cm' : 'N/A'),
                                const SizedBox(height: 8),
                                _detailRow('Active Energy', metrics.activeEnergyBurned != null ? '${metrics.activeEnergyBurned!.toStringAsFixed(0)} kcal' : 'N/A'),
                              ],
                            ),
                          ),
                        ),

                        // Additional widgets / charts can go here
                      ],
                    ),
                  );
                } else if (state is HealthMetricsError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Re-fetch for currently selected date
          context.read<HealthMetricsBloc>().add(GetMetricsForDate(selectedDate));
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}