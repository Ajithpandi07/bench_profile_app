import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/core.dart';
import '../../domain/entities/daily_meal_summary.dart';
import '../bloc/bloc.dart';

class MealDashboardPage extends StatefulWidget {
  const MealDashboardPage({super.key});

  @override
  State<MealDashboardPage> createState() => _MealDashboardPageState();
}

class _MealDashboardPageState extends State<MealDashboardPage> {
  String _selectedView = 'Weekly'; // Weekly, Monthly, Yearly
  List<DailyMealSummary> _allSummaries = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    DateTime start;
    DateTime end;
    final now = DateTime.now();

    if (_selectedView == 'Weekly') {
      // Weekly: Mon - Sun
      final monday = now.subtract(Duration(days: now.weekday - 1));
      start = DateUtils.dateOnly(monday);
      end = start.add(const Duration(days: 6));
    } else if (_selectedView == 'Monthly') {
      // Monthly: 1st - End of month
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else {
      // Yearly: Jan 1 - Dec 31
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31);
    }

    context.read<MealBloc>().add(LoadDashboardStats(start: start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MealBloc, MealState>(
      listener: (context, state) {
        if (state is DashboardStatsLoaded) {
          setState(() {
            _allSummaries = state.summaries;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Meal',
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
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // View Selector
              DashboardDateSelector(
                views: const ['Weekly', 'Monthly', 'Yearly'],
                selectedView: _selectedView,
                onSelected: (view) {
                  setState(() {
                    _selectedView = view;
                    _selectedDate = DateTime.now();
                  });
                  _loadStats();
                },
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 32),

              // Content
              BlocBuilder<MealBloc, MealState>(
                builder: (context, state) {
                  if (state is MealLoading) {
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
    double maxVal = 100; // Minimum scale

    // Prepare data based on view
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
      // 12 months - Display Total for month but calculate average separately
      for (int i = 1; i <= 12; i++) {
        double monthTotal = 0;
        for (var s in _allSummaries) {
          if (s.date.year == now.year && s.date.month == i) {
            monthTotal += s.totalCalories;
          }
        }

        if (monthTotal > maxVal) maxVal = monthTotal;

        chartItems.add(
          DashboardChartItem(
            label: DateFormat('MMM').format(DateTime(now.year, i))[0],
            value: monthTotal,
            isHighlight:
                i == _selectedDate.month && now.year == _selectedDate.year,
          ),
        );
      }
    }

    // Dynamic max scale rounding: Add 20% buffer then round to nearest 500
    // This ensures labels don't get cut off at the top
    maxVal = maxVal * 1.2;
    maxVal = ((maxVal + 499) ~/ 500) * 500.0;

    // Calculate goals
    int activeDays = 0;
    int goalMetDays = 0;
    int totalDaysInPeriod = 0;
    const double targetDailyKcal = 2000.0;
    double averageKcal = 0;

    if (_allSummaries.isNotEmpty) {
      DateTime rangeStart;
      DateTime rangeEnd;
      if (_selectedView == 'Weekly') {
        rangeStart = DateUtils.dateOnly(
          now.subtract(Duration(days: now.weekday - 1)),
        );
        rangeEnd = rangeStart.add(const Duration(days: 6));
        totalDaysInPeriod = 7;
      } else if (_selectedView == 'Monthly') {
        rangeStart = DateTime(now.year, now.month, 1);
        rangeEnd = DateTime(
          now.year,
          now.month,
          DateUtils.getDaysInMonth(now.year, now.month),
        );
        totalDaysInPeriod = rangeEnd.day;
      } else {
        rangeStart = DateTime(now.year, 1, 1);
        rangeEnd = DateTime(now.year, 12, 31);
        totalDaysInPeriod = 12; // months reached for yearly
      }

      final periodSummaries = _allSummaries.where((s) {
        final d = DateUtils.dateOnly(s.date);
        return (d.isAtSameMomentAs(rangeStart) || d.isAfter(rangeStart)) &&
            (d.isAtSameMomentAs(rangeEnd) || d.isBefore(rangeEnd));
      }).toList();

      if (_selectedView == 'Yearly') {
        // For yearly, we count months that had any activity
        final activeMonths = <int>{};
        for (var s in periodSummaries) {
          if (s.totalCalories > 0) {
            activeMonths.add(s.date.month);
          }
        }
        activeDays = activeMonths.length;

        // Count months where monthly total met (days * 2000)
        int metMonths = 0;
        for (int m = 1; m <= 12; m++) {
          final mTotal = periodSummaries
              .where((s) => s.date.month == m)
              .fold(0.0, (sum, s) => sum + s.totalCalories);
          if (mTotal >=
              (DateUtils.getDaysInMonth(now.year, m) * targetDailyKcal))
            metMonths++;
        }
        goalMetDays = metMonths;
      } else {
        activeDays = periodSummaries.where((s) => s.totalCalories > 0).length;
        goalMetDays = periodSummaries
            .where((s) => s.totalCalories >= targetDailyKcal)
            .length;
      }

      if (periodSummaries.isNotEmpty) {
        // Filter for active days to avoid dragging down average with 0s if they exist in summaries
        final activeSummaries = periodSummaries.where(
          (s) => s.totalCalories > 0,
        );
        if (activeSummaries.isNotEmpty) {
          final total = activeSummaries.fold(
            0.0,
            (sum, s) => sum + s.totalCalories,
          );
          averageKcal = total / activeSummaries.length;
        }
      }
    }

    // Calculate selected value
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

    String dateRangeText = '';
    if (_selectedView == 'Weekly') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      dateRangeText =
          '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d').format(sunday)}';
    } else if (_selectedView == 'Monthly') {
      dateRangeText = DateFormat('MMMM yyyy').format(now);
    } else {
      dateRangeText = DateFormat('yyyy').format(now);
    }

    return Column(
      children: [
        // Average Section (New)
        Column(
          children: [
            Text(
              dateRangeText,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: averageKcal.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const TextSpan(
                    text: ' kcal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Average Kcal',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Goal Cards
        Row(
          children: [
            Expanded(
              child: DashboardGoalCard(
                title: 'TIME GOAL',
                value: '$activeDays/$totalDaysInPeriod',
                icon: Icons.access_time_filled,
                iconColor: Colors.pinkAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardGoalCard(
                title: 'KCAL GOAL',
                value: '$goalMetDays/$totalDaysInPeriod',
                icon: Icons.restaurant,
                iconColor: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedView == 'Yearly'
                  ? 'Yearly'
                  : _selectedView == 'Monthly'
                  ? 'Monthly'
                  : 'Weekly'} Overview',
              style: const TextStyle(
                fontSize: 18,
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
                  '${selectedValue.toStringAsFixed(0)} Kcal',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Chart
        DashboardChart(
          items: chartItems,
          maxVal: maxVal,
          highlightColor: AppTheme.primaryColor,
          barBackgroundColor: const Color(0xFFFFEBEB),
          chartHeight: 250,
          formatValue: (val) =>
              val.toInt().toString(), // Explicit integer formatting
          onBarTap: (index) {
            setState(() {
              if (_selectedView == 'Weekly') {
                final now = DateTime.now();
                final monday = now.subtract(Duration(days: now.weekday - 1));
                _selectedDate = monday.add(Duration(days: index));
              } else if (_selectedView == 'Monthly') {
                // index 0 -> day 1
                _selectedDate = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  index + 1,
                );
              } else {
                // index 0 -> month 1 (Jan)
                _selectedDate = DateTime(DateTime.now().year, index + 1, 1);
              }
            });
          },
        ),

        const SizedBox(height: 32),

        // Insight Card
        const DashboardInsightCard(
          title: 'Great job!',
          message: 'You are consistently tracking your meals!',
          iconBackgroundColor: Colors.blue,
        ),
      ],
    );
  }

  DailyMealSummary? _findSummaryForDate(DateTime date) {
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
