import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../domain/entities/sleep_log.dart';
import '../bloc/bloc.dart';

class SleepStatsPage extends StatefulWidget {
  const SleepStatsPage({super.key});

  @override
  State<SleepStatsPage> createState() => _SleepStatsPageState();
}

class _SleepStatsPageState extends State<SleepStatsPage> {
  String _selectedView = 'Weekly'; // 'Weekly', 'Monthly', 'Yearly'
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (_selectedView == 'Weekly') {
      // Current Week (Mon-Sun)
      int daysToSubtract = now.weekday - 1;
      start = DateTime(now.year, now.month, now.day).subtract(
        Duration(days: daysToSubtract + 1),
      ); // Extra day for overnight sleeps
      end = start.add(const Duration(days: 7));
    } else if (_selectedView == 'Monthly') {
      // Current Month (1st to last day)
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else {
      // Current Year (Jan 1 to Dec 31)
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31);
    }

    context.read<SleepBloc>().add(LoadSleepStats(start, end));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Sleep',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(
          color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.black,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
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
                  views: const ['Weekly', 'Monthly', 'Yearly'],
                  selectedView: _selectedView,
                  onSelected: (view) {
                    setState(() {
                      _selectedView = view;
                      // Reset selected date to today when view changes,
                      // or keep it if it falls within range?
                      // Simplest UX: Reset to today or nearest valid date.
                      _selectedDate = DateTime.now();
                    });
                    _loadStats();
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),

                // Date Range Text
                Text(
                  _getDateRangeText(),
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),

                // Main Avg Sleep
                _buildMainAverage(logs),
                const SizedBox(height: 32),

                // Selected Date Value Display (Overview Row)
                _buildOverviewRow(logs),
                const SizedBox(height: 32),

                // Avg Bedtime / WakeUp
                Row(
                  children: [
                    Expanded(
                      child: DashboardGoalCard(
                        title: 'AVG BEDTIME',
                        value: _calculateAvgBedtime(logs),
                        icon: Icons.bedtime,
                        iconColor: Theme.of(context).primaryColor,
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
                DashboardInsightCard(
                  title: 'Great job!',
                  message:
                      'Your sleep schedule is consistent.', // Placeholder message
                  iconBackgroundColor: Theme.of(context).primaryColor,
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
    if (_selectedView == 'Weekly') {
      // Mon - Sun of current week
      int daysToSubtract = now.weekday - 1;
      final start = now.subtract(Duration(days: daysToSubtract));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
    }

    final start = _selectedView == 'Monthly'
        ? DateTime(now.year, now.month, 1) // Start of month
        : DateTime(now.year, 1, 1); // Start of year

    // For end date logic to match visual expectation
    final end = _selectedView == 'Monthly'
        ? DateTime(now.year, now.month + 1, 0)
        : DateTime(now.year, 12, 31);

    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
  }

  Widget _buildMainAverage(List<SleepLog> logs) {
    // Determine which date's log is currently selected
    // If weekly, _selectedDate might be one specific day.

    // Default value
    int h = 0;
    int m = 0;

    // Logic to find log for _selectedDate
    // This depends on how _selectedDate works. In chart onBarTap, we set _selectedDate.
    // So we just find the log for that date.

    if (logs.isNotEmpty) {
      if (_selectedView == 'Weekly') {
        // Find log for _selectedDate
        final log = logs.firstWhere(
          (l) =>
              l.endTime.year == _selectedDate.year &&
              l.endTime.month == _selectedDate.month &&
              l.endTime.day == _selectedDate.day,
          orElse: () => SleepLog(
            id: '',
            startTime: DateTime.now(),
            endTime: DateTime.now(),
            quality: 0,
          ),
        );
        if (log.id.isNotEmpty || log.duration != Duration.zero) {
          h = log.duration.inHours;
          m = log.duration.inMinutes.remainder(60);
        }
      } else if (_selectedView == 'Monthly') {
        final log = logs.firstWhere(
          (l) =>
              l.endTime.year == _selectedDate.year &&
              l.endTime.month == _selectedDate.month &&
              l.endTime.day == _selectedDate.day,
          orElse: () => SleepLog(
            id: '',
            startTime: DateTime.now(),
            endTime: DateTime.now(),
            quality: 0,
          ),
        );
        if (log.id.isNotEmpty || log.duration != Duration.zero) {
          h = log.duration.inHours;
          m = log.duration.inMinutes.remainder(60);
        }
      } else {
        // Yearly - Average for month
        final monthLogs = logs.where(
          (l) =>
              l.endTime.year == _selectedDate.year &&
              l.endTime.month == _selectedDate.month,
        );
        if (monthLogs.isNotEmpty) {
          final totalMin = monthLogs.fold(
            0,
            (sum, l) => sum + l.duration.inMinutes,
          );
          final avg = totalMin ~/ monthLogs.length;
          h = avg ~/ 60;
          m = avg % 60;
        }
      }
    }

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
            Text(
              'h',
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$m',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Text(
              'm',
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Average Sleep',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  Widget _buildOverviewRow(List<SleepLog> logs) {
    String selectedValue = '0h 0m';
    String selectedLabel = '';

    if (logs.isNotEmpty) {
      if (_selectedView == 'Yearly') {
        final monthLogs = logs.where(
          (l) =>
              l.endTime.year == _selectedDate.year &&
              l.endTime.month == _selectedDate.month,
        );
        if (monthLogs.isNotEmpty) {
          final totalMin = monthLogs.fold(
            0,
            (sum, l) => sum + l.duration.inMinutes,
          );
          final avg = totalMin ~/ monthLogs.length;
          selectedValue = '${avg ~/ 60}h ${avg % 60}m';
        }
        selectedLabel = DateFormat('MMMM').format(_selectedDate);
      } else {
        final log = logs.firstWhere(
          (l) =>
              l.endTime.year == _selectedDate.year &&
              l.endTime.month == _selectedDate.month &&
              l.endTime.day == _selectedDate.day,
          orElse: () => SleepLog(
            id: '',
            startTime: _selectedDate,
            endTime: _selectedDate,
            quality: 0,
          ),
        );
        selectedValue =
            '${log.duration.inHours}h ${log.duration.inMinutes.remainder(60)}m';
        selectedLabel = DateFormat('d MMM').format(_selectedDate);
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$_selectedView Overview',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (selectedLabel.isNotEmpty)
              Text(
                selectedLabel,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
            Text(
              selectedValue,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _calculateAvgBedtime(List<SleepLog> logs) {
    if (logs.isEmpty) return '--:--';

    // Filter out naps (e.g. < 3 hours) to avoid skewing "Bedtime"
    final mainSleeps = logs.where((l) => l.duration.inHours >= 3).toList();
    if (mainSleeps.isEmpty) return '--:--';

    int totalMinutes = 0;
    for (var log in mainSleeps) {
      int min = log.startTime.hour * 60 + log.startTime.minute;
      // Identify "Night" times vs "Early Morning" times for averaging
      // e.g. 11 PM (23:00) vs 1 AM (1:00).
      // We want 1 AM to be "later" than 11 PM, so 1 AM -> 25:00.
      if (log.startTime.hour < 12) {
        min += 1440;
      }
      totalMinutes += min;
    }
    int avg = totalMinutes ~/ mainSleeps.length;
    if (avg >= 1440) avg -= 1440;

    final h = avg ~/ 60;
    final m = avg % 60;
    final dt = DateTime(2022, 1, 1, h, m);
    return DateFormat('h:mm a').format(dt);
  }

  String _calculateAvgWakeup(List<SleepLog> logs) {
    if (logs.isEmpty) return '--:--';

    // Filter out naps
    final mainSleeps = logs.where((l) => l.duration.inHours >= 3).toList();
    if (mainSleeps.isEmpty) return '--:--';

    int totalMinutes = 0;
    for (var log in mainSleeps) {
      int min = log.endTime.hour * 60 + log.endTime.minute;
      totalMinutes += min;
    }
    int avg = totalMinutes ~/ mainSleeps.length;
    final h = avg ~/ 60;
    final m = avg % 60;
    final dt = DateTime(2022, 1, 1, h, m);
    return DateFormat('h:mm a').format(dt);
  }

  Widget _buildChart(List<SleepLog> logs) {
    final now = DateTime.now();
    List<DashboardChartItem> items = [];
    double maxVal = 12; // 12 hours max default?

    if (_selectedView == 'Weekly') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);

      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));

        final log = logs.firstWhere(
          (l) =>
              l.endTime.year == date.year &&
              l.endTime.month == date.month &&
              l.endTime.day == date.day,
          orElse: () =>
              SleepLog(id: '', startTime: date, endTime: date, quality: 0),
        );

        final hours = log.duration.inMinutes / 60.0;
        if (hours > maxVal) maxVal = hours;

        items.add(
          DashboardChartItem(
            label: DateFormat('E').format(date),
            value: hours,
            isHighlight:
                date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day,
          ),
        );
      }
    } else if (_selectedView == 'Monthly') {
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(now.year, now.month, i);
        final log = logs.firstWhere(
          (l) =>
              l.endTime.year == date.year &&
              l.endTime.month == date.month &&
              l.endTime.day == date.day,
          orElse: () =>
              SleepLog(id: '', startTime: date, endTime: date, quality: 0),
        );
        final hours = log.duration.inMinutes / 60.0;
        if (hours > maxVal) maxVal = hours;

        // Sparse labels: 1, 5, 10, 15, 20, 25, 30
        String label = '';
        if (i == 1 || i % 5 == 0) {
          label = i.toString();
        }

        items.add(
          DashboardChartItem(
            label: label,
            value: hours,
            isHighlight:
                date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day,
          ),
        );
      }
    } else {
      // 12 months
      for (int i = 1; i <= 12; i++) {
        final monthLogs = logs.where(
          (l) => l.endTime.year == now.year && l.endTime.month == i,
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
            isHighlight:
                i == _selectedDate.month && now.year == _selectedDate.year,
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
      fitAll: _selectedView == 'Monthly', // Disable scrolling for monthly
      highlightColor: Theme.of(context).primaryColor,
      formatValue: (val) {
        if (val % 1 == 0) return val.toInt().toString();
        return val.toStringAsFixed(1);
      },
      onBarTap: (index) {
        setState(() {
          if (_selectedView == 'Weekly') {
            final now = DateTime.now();
            final monday = now.subtract(Duration(days: now.weekday - 1));
            final startOfWeek = DateTime(monday.year, monday.month, monday.day);
            _selectedDate = startOfWeek.add(Duration(days: index));
          } else if (_selectedView == 'Monthly') {
            // Index 0 is 1st day of month
            _selectedDate = DateTime(
              DateTime.now().year,
              DateTime.now().month,
              index + 1,
            );
          } else {
            // 12 months, index 0 is Jan
            _selectedDate = DateTime(DateTime.now().year, index + 1, 1);
          }
        });
      },
    );
  }
}
