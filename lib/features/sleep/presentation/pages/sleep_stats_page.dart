import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/app_theme.dart';
import '../../domain/entities/sleep_log.dart';
import '../bloc/bloc.dart';
import '../widgets/sleep_chart.dart';
import '../widgets/sleep_insight_card.dart';

class SleepStatsPage extends StatefulWidget {
  const SleepStatsPage({super.key});

  @override
  State<SleepStatsPage> createState() => _SleepStatsPageState();
}

class _SleepStatsPageState extends State<SleepStatsPage> {
  int _selectedViewIndex = 0; // 0: 7 days, 1: 31 days, 2: 12 months
  final List<String> _views = ['7 days', '31 days', '12 months'];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final now = DateTime.now();
    DateTime start;
    if (_selectedViewIndex == 0) {
      // Current Week (Mon-Sun)
      int daysToSubtract = now.weekday - 1;
      start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysToSubtract));
    } else if (_selectedViewIndex == 1) {
      // Current Month (1st to last day)
      start = DateTime(now.year, now.month, 1);
    } else {
      // Current Year (Jan 1 to Dec 31)
      start = DateTime(now.year, 1, 1);
    }

    context.read<SleepBloc>().add(LoadSleepStats(start, now));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Sleep',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<SleepBloc, SleepState>(
        builder: (context, state) {
          List<SleepLog> logs = [];
          if (state is SleepStatsLoaded) {
            logs = state.logs;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: List.generate(_views.length, (index) {
                      final isSelected = _selectedViewIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedViewIndex = index;
                            });
                            _loadStats();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xffFF4B55)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                _views[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Date Range Text
                Text(
                  _getDateRangeText(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),

                // Main Avg Sleep
                _buildMainAverage(logs),
                const SizedBox(height: 32),

                // Avg Bedtime / WakeUp
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'AVG BEDTIME',
                        _calculateAvgBedtime(logs),
                        Icons.bedtime,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'AVG WAKE-UP',
                        _calculateAvgWakeup(logs),
                        Icons.wb_sunny,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Insight Card
                const SleepInsightCard(
                  percentageChange: 12,
                ), // Static for now as requested
                const SizedBox(height: 32),

                // Chart
                Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    DateTime start;
                    SleepChartViewMode mode;

                    if (_selectedViewIndex == 0) {
                      int daysToSubtract = now.weekday - 1;
                      start = DateTime(
                        now.year,
                        now.month,
                        now.day,
                      ).subtract(Duration(days: daysToSubtract));
                      mode = SleepChartViewMode.weekly;
                    } else if (_selectedViewIndex == 1) {
                      start = DateTime(now.year, now.month, 1);
                      mode = SleepChartViewMode.monthly;
                    } else {
                      start = DateTime(now.year, 1, 1);
                      mode = SleepChartViewMode.yearly;
                    }
                    return SleepChart(
                      logs: logs,
                      startDate: start,
                      viewMode: mode,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    if (_selectedViewIndex == 0) {
      // Mon - Sun of current week
      int daysToSubtract = now.weekday - 1;
      final start = now.subtract(Duration(days: daysToSubtract));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
    }

    final start = _selectedViewIndex == 1
        ? now.subtract(const Duration(days: 30))
        : DateTime(now.year - 1, now.month, now.day);

    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(now)}';
  }

  Widget _buildMainAverage(List<SleepLog> logs) {
    if (logs.isEmpty) {
      return const Text(
        'No Data',
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      );
    }
    final totalMin = logs.fold(0, (sum, log) => sum + log.duration.inMinutes);
    final avgMin = totalMin ~/ logs.length;
    final h = avgMin ~/ 60;
    final m = avgMin % 60;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$h',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const Text('h', style: TextStyle(fontSize: 24, color: Colors.grey)),
            const SizedBox(width: 8),
            Text(
              '$m',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const Text('m', style: TextStyle(fontSize: 24, color: Colors.grey)),
          ],
        ),
        const Text('Average Sleep', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  String _calculateAvgBedtime(List<SleepLog> logs) {
    if (logs.isEmpty) return '--:--';
    // Average logic: Convert time to minutes from midnight. Handle crossing midnight.
    // E.g. 23:00 is -60 min? Or 1380 min?
    // Best to average timestamps of "bedtimes" normalized to a single reference date?
    int totalMinutes = 0;
    for (var log in logs) {
      int min = log.startTime.hour * 60 + log.startTime.minute;
      // If time is between 00:00 and 12:00 (noon), add 24h (1440 min) to make it "late night" for averaging?
      // E.g. 1AM should be > 11PM. 11PM = 23*60 = 1380. 1AM = 1*60 = 60.
      // If we treat 1AM as 25:00 (1500), then (1380+1500)/2 = 1440 (midnight). Correct.
      if (log.startTime.hour < 12) {
        min += 1440;
      }
      totalMinutes += min;
    }
    int avg = totalMinutes ~/ logs.length;
    if (avg >= 1440) avg -= 1440; // Normalize back

    final h = avg ~/ 60;
    final m = avg % 60;
    final dt = DateTime(2022, 1, 1, h, m);
    return DateFormat('h:mm a').format(dt);
  }

  String _calculateAvgWakeup(List<SleepLog> logs) {
    if (logs.isEmpty) return '--:--';
    int totalMinutes = 0;
    for (var log in logs) {
      int min = log.endTime.hour * 60 + log.endTime.minute;
      totalMinutes += min;
    }
    int avg = totalMinutes ~/ logs.length;
    final h = avg ~/ 60;
    final m = avg % 60;
    final dt = DateTime(2022, 1, 1, h, m);
    return DateFormat('h:mm a').format(dt);
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: title.contains('BED') ? Colors.red : Colors.orange,
              ), // Bedtime Red, Wakeup Orange
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
