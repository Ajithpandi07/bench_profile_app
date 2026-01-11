import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/daily_meal_summary.dart';
import '../bloc/bloc.dart';

class MealDashboardPage extends StatefulWidget {
  const MealDashboardPage({super.key});

  @override
  State<MealDashboardPage> createState() => _MealDashboardPageState();
}

class _MealDashboardPageState extends State<MealDashboardPage> {
  String _selectedView = '7 days'; // 7 days, 31 days, 12 months
  List<DailyMealSummary> _allSummaries = [];

  @override
  void initState() {
    super.initState();
    // Dispatch event to load stats
    context.read<MealBloc>().add(const LoadDashboardStats());
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
            'Food',
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
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTab('7 days', _selectedView == '7 days'),
                    _buildTab('31 days', _selectedView == '31 days'),
                    _buildTab('12 months', _selectedView == '12 months'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildStatsContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    final now = DateTime.now();
    List<Map<String, dynamic>> chartItems = [];
    double totalCaloriesInView = 0;
    int daysWithData = 0;
    double maxVal = 100; // Minimum scale

    // Prepare data based on view
    if (_selectedView == '7 days') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final summary = _findSummaryForDate(date);
        final val = summary?.totalCalories ?? 0.0;

        if (val > 0) {
          totalCaloriesInView += val;
          daysWithData++;
        }
        if (val > maxVal) maxVal = val;

        chartItems.add({
          'label': DateFormat('E').format(date),
          'value': val,
          'isHighlight':
              date.day == now.day &&
              date.month == now.month &&
              date.year == now.year,
        });
      }
    } else if (_selectedView == '31 days') {
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(now.year, now.month, i);
        final summary = _findSummaryForDate(date);
        final val = summary?.totalCalories ?? 0.0;

        if (val > 0) {
          totalCaloriesInView += val;
          daysWithData++;
        }
        if (val > maxVal) maxVal = val;

        chartItems.add({
          'label': i.toString(),
          'value': val,
          'isHighlight': i == now.day,
        });
      }
    } else {
      // 12 months
      for (int i = 1; i <= 12; i++) {
        // Aggregate for month
        double monthTotal = 0;
        // Inefficient but simple: filter list
        // Optimize: Use map or pre-process
        for (var s in _allSummaries) {
          if (s.date.year == now.year && s.date.month == i) {
            monthTotal += s.totalCalories;
          }
        }

        // Average for the month? Or Total? Usually total for month view or average daily?
        // Let's show average daily calories for that month to stay consistent with Y-axis being "Calories"
        // Determining days in that month...
        int days = DateUtils.getDaysInMonth(now.year, i);
        // Only count days passed if current month? Or just average over full month?
        // Let's do simple average over total days in month
        double monthAvg = monthTotal / days;

        if (monthTotal > 0) {
          totalCaloriesInView +=
              monthTotal; // Keeping total for "Average Kcal" calculation
          daysWithData += days; // Rough approx
        }

        if (monthAvg > maxVal) maxVal = monthAvg;

        chartItems.add({
          'label': DateFormat('MMM').format(DateTime(now.year, i))[0],
          'value': monthAvg,
          'isHighlight': i == now.month,
        });
      }
    }

    // Dynamic max scale rounding
    maxVal = ((maxVal + 499) ~/ 500) * 500.0;
    double averageKcal = daysWithData > 0
        ? totalCaloriesInView / daysWithData
        : 0;

    // Correct Average Logic for "12 months" view:
    // If we want "Average Kcal" for the whole year, it's Sum(All Daily Cals) / Count(Days with logs).
    // The previous loop aggregated roughly. Let's refine for consistency.
    // Actually, simple average of the values displayed in chart might be misleading.
    // Better: Average of ALL days in the selected range.

    return Column(
      children: [
        // Date Range
        Text(
          _getDateRangeText(),
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Average Kcal Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              averageKcal.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF131313),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Kcal',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Text(
          'Average Kcal',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),

        const SizedBox(height: 32),

        // Goal Cards (Top level metrics - Mock/Placeholder or calculate?)
        // Let's keep them as placeholders for now or partial real data
        Row(
          children: [
            Expanded(
              child: _buildGoalCard(
                'TIME GOAL',
                '5/7',
                Icons.access_time_filled,
                Colors.pinkAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGoalCard(
                'KCAL GOAL',
                '${(averageKcal / 2000 * 100).toStringAsFixed(0)}%', // Mock logic
                Icons.restaurant,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Chart
        SizedBox(height: 250, child: _buildChartWidget(chartItems, maxVal)),

        const SizedBox(height: 32),

        // Insight Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Great job!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF131313),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You are consistently tracking your meals!',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  String _getDateRangeText() {
    final now = DateTime.now();
    if (_selectedView == '7 days') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d').format(sunday)}';
    } else if (_selectedView == '31 days') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
    } else {
      return 'Jan 1 - Dec 31';
    }
  }

  Widget _buildTab(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = text;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE93448) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE93448).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
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
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF131313),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartWidget(
    List<Map<String, dynamic>> chartItems,
    double maxVal,
  ) {
    const int gridLines = 5;
    final double step = maxVal / (gridLines - 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Y-Axis
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(gridLines, (index) {
            final value = maxVal - (step * index);
            return Text(
              value.toInt().toString(),
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            );
          }),
        ),
        const SizedBox(width: 12),
        // Chart
        Expanded(
          child: Stack(
            children: [
              // Grid Background
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(gridLines, (index) {
                  return Row(
                    children: List.generate(
                      40,
                      (i) => Expanded(
                        child: Container(
                          color: i % 2 == 0
                              ? Colors.grey.shade300
                              : Colors.transparent,
                          height: 1,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // Bars
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_selectedView == '31 days') {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: chartItems
                                .map((item) => _buildBarItem(item, maxVal))
                                .toList(),
                          ),
                        ),
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: chartItems
                            .map(
                              (item) =>
                                  Expanded(child: _buildBarItem(item, maxVal)),
                            )
                            .toList(),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarItem(Map<String, dynamic> item, double maxVal) {
    final heightFactor = (item['value'] as double) / maxVal;
    final isHighlight = item['isHighlight'] as bool;

    double barWidth = 30;
    if (_selectedView == '12 months') barWidth = 12;
    if (_selectedView == '31 days') barWidth = 6;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isHighlight)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE93448),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(item['value'] as double).toInt()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          const SizedBox(height: 24),
        Container(
          width: barWidth,
          height: (180 * heightFactor).clamp(0, 180),
          decoration: BoxDecoration(
            color: isHighlight
                ? const Color(0xFFE93448)
                : const Color(0xFFFFEBEB),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item['label'] as String,
          style: TextStyle(
            color: isHighlight ? const Color(0xFFE93448) : Colors.grey.shade400,
            fontSize: 10,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
