import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_loading_view.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/app_theme.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_average_display.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_chart.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_date_selector.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_goal_card.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_insight_card.dart';
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
              DashboardDateSelector(
                views: const ['Weekly', 'Monthly', 'Yearly'],
                selectedView: _selectedView,
                onSelected: (view) {
                  setState(() {
                    _selectedView = view;
                    _selectedDate = DateTime.now();
                  });
                },
                activeColor: const Color(0xFFE93448),
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
    double totalCaloriesInView = 0;
    int daysWithData = 0;
    double maxVal = 100; // Minimum scale

    // Prepare data based on view
    if (_selectedView == 'Weekly') {
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

        if (val > 0) {
          totalCaloriesInView += val;
          daysWithData++;
        }
        if (val > maxVal) maxVal = val;

        chartItems.add(
          DashboardChartItem(
            label: i.toString(),
            value: val,
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
        // Aggregate for month
        double monthTotal = 0;
        // Inefficient but simple: filter list
        for (var s in _allSummaries) {
          if (s.date.year == now.year && s.date.month == i) {
            monthTotal += s.totalCalories;
          }
        }

        // Calculate average daily calories for that month
        int days = DateUtils.getDaysInMonth(now.year, i);
        double monthAvg = monthTotal / days;

        if (monthTotal > 0) {
          totalCaloriesInView += monthTotal;
          daysWithData += days;
        }

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

    // Dynamic max scale rounding
    maxVal = ((maxVal + 499) ~/ 500) * 500.0;
    double averageKcal = daysWithData > 0
        ? totalCaloriesInView / daysWithData
        : 0;

    return Column(
      children: [
        // Date Range
        Text(
          _getDateRangeText(),
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Average Kcal Display
        DashboardAverageDisplay(
          value: averageKcal.toStringAsFixed(0),
          unit: 'Kcal',
          label: 'Average Kcal',
        ),

        const SizedBox(height: 32),

        // Goal Cards
        Row(
          children: [
            Expanded(
              child: DashboardGoalCard(
                title: 'TIME GOAL',
                value: '5/7',
                icon: Icons.access_time_filled,
                iconColor: Colors.pinkAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardGoalCard(
                title: 'KCAL GOAL',
                value: '${(averageKcal / 2000 * 100).toStringAsFixed(0)}%',
                icon: Icons.restaurant,
                iconColor: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Chart
        DashboardChart(
          items: chartItems,
          maxVal: maxVal,
          highlightColor: const Color(0xFFE93448),
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

  String _getDateRangeText() {
    final now = DateTime.now();
    if (_selectedView == 'Weekly') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d').format(sunday)}';
    } else if (_selectedView == 'Monthly') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
    } else {
      return 'Jan 1 - Dec 31';
    }
  }
}
