import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../domain/entities/daily_activity_summary.dart';
import '../bloc/activity_bloc.dart';
import '../bloc/activity_event.dart';
import '../bloc/activity_state.dart';

class ActivityStatsPage extends StatefulWidget {
  const ActivityStatsPage({super.key});

  @override
  State<ActivityStatsPage> createState() => _ActivityStatsPageState();
}

class _ActivityStatsPageState extends State<ActivityStatsPage> {
  String _selectedView = 'Weekly'; // Weekly, Monthly, Yearly
  List<DailyActivitySummary> _allSummaries = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<ActivityBloc>().add(const LoadActivityStats());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActivityBloc, ActivityState>(
      listener: (context, state) {
        if (state is ActivityStatsLoaded) {
          setState(() {
            _allSummaries = state.summaries;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Activity',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false, // Explicitly left-align
          leading: const BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              DashboardDateSelector(
                views: const ['Weekly', 'Monthly', 'Yearly'],
                selectedView: _selectedView,
                onSelected: (view) {
                  setState(() {
                    _selectedView = view;
                    _selectedDate = DateTime.now();
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 32),
              BlocBuilder<ActivityBloc, ActivityState>(
                builder: (context, state) {
                  if (state is ActivityLoading) {
                    return const DashboardLoadingView();
                  }
                  return _buildStatsContent();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    final now = DateTime.now();
    List<DashboardChartItem> chartItems = [];
    double maxVal = 100;

    // 1. Determine Date Range and Total Days based on View
    DateTime rangeStart;
    DateTime rangeEnd;
    int totalDaysInPeriod;
    String dateRangeString;

    if (_selectedView == 'Weekly') {
      // Current Week: Mon - Sun
      final monday = now.subtract(Duration(days: now.weekday - 1));
      rangeStart = DateUtils.dateOnly(monday);
      rangeEnd = rangeStart.add(const Duration(days: 6));
      totalDaysInPeriod = 7;

      final startStr = DateFormat('MMM d').format(rangeStart);
      final endStr = DateFormat('MMM d').format(rangeEnd);
      dateRangeString = '$startStr - $endStr';
    } else if (_selectedView == 'Monthly') {
      // Current Month
      rangeStart = DateTime(now.year, now.month, 1);
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      rangeEnd = DateTime(now.year, now.month, daysInMonth);
      totalDaysInPeriod = daysInMonth;

      dateRangeString = DateFormat('MMMM yyyy').format(now);
    } else {
      // Current Year
      rangeStart = DateTime(now.year, 1, 1);
      rangeEnd = DateTime(now.year, 12, 31);
      totalDaysInPeriod = 365 + (now.year % 4 == 0 ? 1 : 0); // Leap year approx

      dateRangeString = DateFormat('yyyy').format(now);
    }

    // 2. Calculate Stats from _allSummaries for this Range
    // Filter summaries strictly within rangeStart and rangeEnd
    final summariesInPeriod = _allSummaries.where((s) {
      final date = DateUtils.dateOnly(s.date);
      return (date.isAfter(rangeStart) || date.isAtSameMomentAs(rangeStart)) &&
          (date.isBefore(rangeEnd) || date.isAtSameMomentAs(rangeEnd));
    }).toList();

    double totalKcalInPeriod = 0;
    int activeDaysCount = 0;
    int kcalGoalMetCount = 0;
    const double dailyKcalGoal = 400; // Hardcoded goal for now

    for (var s in summariesInPeriod) {
      totalKcalInPeriod += s.totalCalories;
      if (s.totalCalories > 0) activeDaysCount++;
      if (s.totalCalories >= dailyKcalGoal) kcalGoalMetCount++;
    }

    // Average Kcal (for period, or daily avg?)
    // "Average Kcal" usually means Daily Average.
    // If no data, 0. If data, average over active days or total days?
    // User mockup shows "842 Kcal Average Kcal".
    // Usually avg over active days is more encouraging, or avg over passed days.
    // Let's use avg over active days for now to match "days achieved" vibe.
    double averageKcal = activeDaysCount > 0
        ? totalKcalInPeriod / activeDaysCount
        : 0;

    // 3. Build Chart Items (Visuals)
    // Reuse existing logic but ensuring it matches the range
    // NOTE: The existing loops below use 'now' to generate items.
    // This matches our rangeStart/End logic (Current Week/Month/Year).

    // ... (Loop logic below remains mostly same but we can assume loop matches range) ...
    // Let's keep the loop logic for chart items generation as is,
    // but we won't calculate totals inside it to avoid double logic.

    if (_selectedView == 'Weekly') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final summary = _findSummaryForDate(date);
        final val = summary?.totalCalories ?? 0.0;

        if (val > maxVal) maxVal = val;

        chartItems.add(
          DashboardChartItem(
            label: DateFormat('E').format(date),
            value: val,
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
        final summary = _findSummaryForDate(date);
        final val = summary?.totalCalories ?? 0.0;

        if (val > maxVal) maxVal = val;

        chartItems.add(
          DashboardChartItem(
            label: (i == 1 || i % 5 == 0) ? i.toString() : '',
            value: val,
            isHighlight:
                date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day,
          ),
        );
      }
    } else {
      for (int i = 1; i <= 12; i++) {
        double monthTotal = 0;
        for (var s in _allSummaries) {
          if (s.date.year == now.year && s.date.month == i) {
            monthTotal += s.totalCalories;
          }
        }
        int days = DateUtils.getDaysInMonth(now.year, i);
        double monthAvg = monthTotal / days;
        // Note: Chart shows Monthly Avg Kcal/Day? Or Monthly Total?
        // Code below shows monthAvg.
        if (monthAvg > maxVal) maxVal = monthAvg;

        chartItems.add(
          DashboardChartItem(
            label: DateFormat('MMM').format(DateTime(now.year, i))[0],
            value: monthAvg,
            isHighlight:
                i == _selectedDate.month && now.year == _selectedDate.year,
          ),
        );
      }
    }

    maxVal = ((maxVal + 499) ~/ 500) * 500.0;

    // double selectedValue = 0; // Unused
    // String selectedLabel = ''; // Unused

    // if (_selectedView == 'Yearly') {
    //   final monthSum = _allSummaries
    //       .where(
    //         (s) =>
    //             s.date.year == _selectedDate.year &&
    //             s.date.month == _selectedDate.month,
    //       )
    //       .fold(0.0, (sum, s) => sum + s.totalCalories);
    //   selectedValue = monthSum;
    //   selectedLabel = DateFormat('MMMM').format(_selectedDate);
    // } else {
    //   final summary = _findSummaryForDate(_selectedDate);
    //   selectedValue = summary?.totalCalories ?? 0.0;
    //   selectedLabel = DateFormat('d MMM').format(_selectedDate);
    // }

    // Calculate selected value for "Preview"
    double selectedValue = 0;
    String selectedLabel = '';

    if (_selectedView == 'Yearly') {
      final monthSum = _allSummaries
          .where(
            (s) =>
                s.date.year == _selectedDate.year &&
                s.date.month == _selectedDate.month,
          )
          .fold(0.0, (sum, s) => sum + s.totalCalories);
      selectedValue = monthSum;
      selectedLabel = DateFormat('MMMM').format(_selectedDate);
    } else {
      final summary = _findSummaryForDate(_selectedDate);
      selectedValue = summary?.totalCalories ?? 0.0;
      selectedLabel = DateFormat('d MMM').format(_selectedDate);
    }

    return Column(
      children: [
        Column(
          children: [
            Text(
              dateRangeString,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: averageKcal.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const TextSpan(
                    text: ' Kcal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Average Kcal',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                Text(
                  '${selectedValue.toStringAsFixed(0)} Kcal', // Selected Value
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.access_time_filled,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'TIME GOAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$activeDaysCount', // Dynamic
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          TextSpan(
                            text: '/$totalDaysInPeriod', // Dynamic
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'days achieved',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.local_fire_department,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'KCAL GOAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$kcalGoalMetCount', // Dynamic
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          TextSpan(
                            text: '/$totalDaysInPeriod', // Dynamic
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'days achieved',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const SizedBox(height: 24),
        DashboardChart(
          items: chartItems,
          maxVal: maxVal,
          highlightColor: AppTheme.primaryColor,
          barBackgroundColor: const Color(
            0xFFF3F4F6,
          ), // Light grey for non-selected
          chartHeight: 200,
          formatValue: (val) => val.toInt().toString(),
          onBarTap: (index) {
            setState(() {
              if (_selectedView == 'Weekly') {
                final now = DateTime.now();
                final monday = now.subtract(Duration(days: now.weekday - 1));
                _selectedDate = monday.add(Duration(days: index));
              } else if (_selectedView == 'Monthly') {
                // Determine day from index (index 0 = day 1)
                final day = index + 1;
                // Ensure valid day for month
                final daysInMonth = DateUtils.getDaysInMonth(
                  _selectedDate.year,
                  _selectedDate.month,
                );
                if (day <= daysInMonth) {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    day,
                  );
                }
              } else {
                _selectedDate = DateTime(DateTime.now().year, index + 1, 1);
              }
            });
          },
          fitAll: _selectedView == 'Monthly',
        ),
        const SizedBox(height: 32),
        const DashboardInsightCard(
          title: 'Great job!',
          message:
              'Your average activity increased by 18% compared to last month. Keep it up!',
          iconBackgroundColor: Color(0xFFE8F1FF), // Light blue bg
          iconColor: Color(0xFF4B8AE6), // Blue icon
          icon: Icons.auto_awesome,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  DailyActivitySummary? _findSummaryForDate(DateTime date) {
    try {
      return _allSummaries.firstWhere(
        (s) =>
            s.date.year == date.year &&
            s.date.month == date.month &&
            s.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }
}
