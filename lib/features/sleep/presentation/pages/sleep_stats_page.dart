import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_loading_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/app_theme.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_average_display.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_chart.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_date_selector.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_goal_card.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_insight_card.dart';
import '../../domain/entities/sleep_log.dart';
import '../bloc/bloc.dart';

class SleepStatsPage extends StatefulWidget {
  const SleepStatsPage({super.key});

  @override
  State<SleepStatsPage> createState() => _SleepStatsPageState();
}

class _SleepStatsPageState extends State<SleepStatsPage> {
  String _selectedView = '7 days'; // '7 days', '31 days', '12 months'

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final now = DateTime.now();
    DateTime start;
    if (_selectedView == '7 days') {
      // Current Week (Mon-Sun)
      int daysToSubtract = now.weekday - 1;
      start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysToSubtract));
    } else if (_selectedView == '31 days') {
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
          if (state is SleepLoading) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: DashboardLoadingView(),
            );
          }

          List<SleepLog> logs = [];
          if (state is SleepStatsLoaded) {
            logs = state.logs;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // View Selector
                DashboardDateSelector(
                  views: const ['7 days', '31 days', '12 months'],
                  selectedView: _selectedView,
                  onSelected: (view) {
                    setState(() {
                      _selectedView = view;
                    });
                    _loadStats();
                  },
                  activeColor: const Color(0xffFF4B55),
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
                      child: DashboardGoalCard(
                        title: 'AVG BEDTIME',
                        value: _calculateAvgBedtime(logs),
                        icon: Icons.bedtime,
                        iconColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardGoalCard(
                        title: 'AVG WAKE-UP',
                        value: _calculateAvgWakeup(logs),
                        icon: Icons.wb_sunny,
                        iconColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Chart
                _buildChart(logs),

                const SizedBox(height: 32),

                // Insight Card
                const DashboardInsightCard(
                  title: 'Great job!',
                  message:
                      'Your sleep schedule is consistent.', // Placeholder message
                  iconBackgroundColor:
                      Colors.purple, // Sleep theme color often purple/indigo
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
    if (_selectedView == '7 days') {
      // Mon - Sun of current week
      int daysToSubtract = now.weekday - 1;
      final start = now.subtract(Duration(days: daysToSubtract));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
    }

    final start = _selectedView == '31 days'
        ? DateTime(now.year, now.month, 1) // Start of month
        : DateTime(now.year, 1, 1); // Start of year

    // For end date logic to match visual expectation
    final end = _selectedView == '31 days'
        ? DateTime(now.year, now.month + 1, 0)
        : DateTime(now.year, 12, 31);

    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
  }

  Widget _buildMainAverage(List<SleepLog> logs) {
    if (logs.isEmpty) {
      return const DashboardAverageDisplay(
        value: '0',
        unit: 'h 0m',
        label: 'Average Sleep',
      );
    }
    final totalMin = logs.fold(0, (sum, log) => sum + log.duration.inMinutes);
    final avgMin = totalMin ~/ logs.length;
    final h = avgMin ~/ 60;
    final m = avgMin % 60;

    // Custom display since standard is "Value Unit" side by side, but sleep usually likes "8h 30m"
    // We can reuse DashboardAverageDisplay if we format value strictly or just use custom here to match design
    // The DashboardAverageDisplay takes value and unit.
    // Let's pass "7h 30m" as value and empty unit? Or "7" as value and "h 30m" as unit?
    // Let's try to stick to the design: "8h 30m"

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
    int totalMinutes = 0;
    for (var log in logs) {
      int min = log.startTime.hour * 60 + log.startTime.minute;
      if (log.startTime.hour < 12) {
        min += 1440;
      }
      totalMinutes += min;
    }
    int avg = totalMinutes ~/ logs.length;
    if (avg >= 1440) avg -= 1440;

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

  Widget _buildChart(List<SleepLog> logs) {
    final now = DateTime.now();
    List<DashboardChartItem> items = [];
    double maxVal = 12; // 12 hours max default?

    if (_selectedView == '7 days') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        // Find log for this day (start time on this day?)
        // Sleep data usually spans days. Let's use start time.
        // Or finding log that *ends* on this day? Usually start time is logical "night of"
        // Logic in previous impl was likely simplistic. Let's check matching.

        final log = logs.firstWhere(
          (l) =>
              l.startTime.year == date.year &&
              l.startTime.month == date.month &&
              l.startTime.day == date.day,
          orElse: () =>
              SleepLog(id: '', startTime: date, endTime: date, quality: 0),
        );

        final hours = log.duration.inMinutes / 60.0;
        if (hours > maxVal) maxVal = hours;

        items.add(
          DashboardChartItem(
            label: DateFormat('E').format(date),
            value: hours,
            isHighlight: date.day == now.day,
          ),
        );
      }
    } else if (_selectedView == '31 days') {
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(now.year, now.month, i);
        // Better matching: filter list for day
        final log = logs.firstWhere(
          (l) =>
              l.startTime.year == date.year &&
              l.startTime.month == date.month &&
              l.startTime.day == date.day,
          orElse: () =>
              SleepLog(id: '', startTime: date, endTime: date, quality: 0),
        );
        final hours = log.duration.inMinutes / 60.0;
        if (hours > maxVal) maxVal = hours;

        items.add(
          DashboardChartItem(
            label: i.toString(),
            value: hours,
            isHighlight: i == now.day,
          ),
        );
      }
    } else {
      // 12 months
      for (int i = 1; i <= 12; i++) {
        final monthLogs = logs.where(
          (l) => l.startTime.year == now.year && l.startTime.month == i,
        );
        double avgHours = 0;
        if (monthLogs.isNotEmpty) {
          final totalMin = monthLogs.fold(
            0,
            (sum, l) => sum + l.duration.inMinutes,
          );
          avgHours = (totalMin / monthLogs.length) / 60.0;
        }

        if (avgHours > maxVal) maxVal = avgHours;

        items.add(
          DashboardChartItem(
            label: DateFormat('MMM').format(DateTime(now.year, i))[0],
            value: avgHours,
            isHighlight: i == now.month,
          ),
        );
      }
    }

    // Round maxVal up to even reasonable number
    maxVal = (maxVal.ceil() + 1).toDouble();
    if (maxVal < 8) maxVal = 8;

    return DashboardChart(
      items: items,
      maxVal: maxVal,
      chartHeight: 250,
      highlightColor: const Color(0xffFF4B55),
      formatValue: (val) {
        if (val % 1 == 0) return val.toInt().toString();
        return val.toStringAsFixed(1);
      },
    );
  }
}
