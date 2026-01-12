import '../../../../core/presentation/widgets/dashboard/dashboard_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_average_display.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_chart.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_date_selector.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_goal_card.dart';
import '../../../../core/presentation/widgets/dashboard/dashboard_insight_card.dart';
import '../../domain/entities/hydration_daily_summary.dart';
import '../bloc/bloc.dart';

class HydrationDashboardPage extends StatefulWidget {
  const HydrationDashboardPage({super.key});

  @override
  State<HydrationDashboardPage> createState() => _HydrationDashboardPageState();
}

class _HydrationDashboardPageState extends State<HydrationDashboardPage> {
  String _selectedView = 'Weekly'; // 'Weekly', 'Monthly', 'Yearly'
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (_selectedView == 'Weekly') {
      // Calendar Week (Mon - Sun)
      // Find Monday of current week
      // weekday: Mon=1 ... Sun=7
      final daysToSubtract = now.weekday - 1;
      final start = now.subtract(Duration(days: daysToSubtract));
      startDate = DateTime(start.year, start.month, start.day);
      final end = startDate.add(const Duration(days: 6));
      endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    } else if (_selectedView == 'Monthly') {
      // Calendar Month (1st to End)
      startDate = DateTime(now.year, now.month, 1);
      // Last day of month: 1st of next month minus 1 day
      endDate = DateTime(now.year, now.month + 1, 0);
    } else {
      // Yearly: Jan - Dec
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
    }

    context.read<HydrationBloc>().add(
      LoadHydrationStats(startDate: startDate, endDate: endDate),
    );
  }

  List<DashboardChartItem> _processChartData(
    List<HydrationDailySummary> rawStats,
  ) {
    // We must generate ALL slots even if empty, to maintain static axis
    final now = DateTime.now();
    List<HydrationDailySummary> processed = [];
    List<DashboardChartItem> chartItems = [];

    if (_selectedView == 'Yearly') {
      // Jan - Dec
      for (int i = 1; i <= 12; i++) {
        final monthStats = rawStats.where(
          (e) => e.date.month == i && e.date.year == now.year,
        );
        double total = monthStats.fold(0.0, (sum, e) => sum + e.totalLiters);
        processed.add(
          HydrationDailySummary(
            date: DateTime(now.year, i, 1),
            totalLiters: total,
          ),
        );
      }
    } else if (_selectedView == 'Monthly') {
      // 1 - End of Month
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(now.year, now.month, i);
        final summary = rawStats.firstWhere(
          (e) =>
              e.date.year == date.year &&
              e.date.month == date.month &&
              e.date.day == date.day,
          orElse: () => HydrationDailySummary(date: date, totalLiters: 0),
        );
        processed.add(summary);
      }
    } else {
      // Weekly: Mon - Sun
      final monday = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final summary = rawStats.firstWhere(
          (e) =>
              e.date.year == date.year &&
              e.date.month == date.month &&
              e.date.day == date.day,
          orElse: () => HydrationDailySummary(date: date, totalLiters: 0),
        );
        processed.add(summary);
      }
    }

    // Convert to DashboardChartItem
    for (var item in processed) {
      String label;
      if (_selectedView == 'Weekly') {
        label = DateFormat('E').format(item.date); // Mon
      } else if (_selectedView == 'Yearly') {
        label = DateFormat('MMM').format(item.date)[0]; // J, F, M...
      } else {
        // Monthly: 1, 5, 10... logic handled in chart or here?
        // Let's pass full label and let chart handle density or manual here
        if (item.date.day == 1 || item.date.day % 5 == 0) {
          label = item.date.day.toString();
        } else {
          label = '';
        }
      }

      final isHighlight = _selectedView == 'Yearly'
          ? (item.date.month == _selectedDate.month &&
                item.date.year == _selectedDate.year)
          : (item.date.year == _selectedDate.year &&
                item.date.month == _selectedDate.month &&
                item.date.day == _selectedDate.day);

      chartItems.add(
        DashboardChartItem(
          label: label,
          value: item.totalLiters,
          isHighlight: isHighlight,
        ),
      );
    }

    return chartItems;
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    if (_selectedView == 'Weekly') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d').format(sunday)}';
    } else if (_selectedView == 'Monthly') {
      return DateFormat('MMMM yyyy').format(now);
    } else {
      return DateFormat('yyyy').format(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Water',
          style: TextStyle(
            color: Color(0xFFEE374D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Tab Selector
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
                activeColor: const Color(0xFFEE374D),
              ),
              const SizedBox(height: 32),

              // Main Content Area with unified loading state
              BlocBuilder<HydrationBloc, HydrationState>(
                builder: (context, state) {
                  if (state is HydrationLoading) {
                    return const DashboardLoadingView();
                  }

                  // Default values
                  double average = 0;
                  String waterGoal = '0/7';
                  String timeGoal = '0/7';
                  List<DashboardChartItem> chartData = [];
                  double maxVal = 10.0;

                  if (state is HydrationStatsLoaded) {
                    // Process Average
                    final processedItems = _processChartData(state.stats);
                    if (processedItems.isNotEmpty) {
                      double total = processedItems.fold(
                        0.0,
                        (sum, item) => sum + item.value,
                      );
                      average = (total * 1000) / processedItems.length;
                    }

                    // Process Goals
                    int achieved = state.stats
                        .where((e) => e.totalLiters >= 3.0)
                        .length;
                    int totalDays = 7;
                    if (_selectedView == 'Monthly')
                      totalDays = 30;
                    else if (_selectedView == 'Yearly')
                      totalDays = 12;

                    waterGoal = '$achieved/$totalDays';
                    timeGoal = '$achieved/$totalDays';

                    // Process Chart
                    chartData = processedItems;
                    double calculatedMax = chartData.fold(
                      0.0,
                      (prev, e) => e.value > prev ? e.value : prev,
                    );
                    // Ensure sensible minimum and nice rounding for grid lines
                    // Round up to nearest integer for clean quarters (0.25, 0.5, 0.75 steps)
                    if (calculatedMax < 2.0) calculatedMax = 2.0;
                    maxVal = calculatedMax.ceilToDouble();
                    // Add buffer if close to top
                    if (maxVal - calculatedMax < 0.2) maxVal += 1.0;
                  }

                  return Column(
                    children: [
                      Text(
                        _getDateRangeText(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Average Display
                      DashboardAverageDisplay(
                        value: average > 0 ? average.toStringAsFixed(0) : '0',
                        unit: 'ml',
                        label: 'Average Hydration',
                      ),
                      const SizedBox(height: 32),

                      // Goals Row
                      Row(
                        children: [
                          Expanded(
                            child: DashboardGoalCard(
                              title: 'TIME GOAL',
                              value: timeGoal,
                              icon: Icons.schedule,
                              iconColor: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DashboardGoalCard(
                              title: 'WATER GOAL',
                              value: waterGoal,
                              icon: Icons.water_drop,
                              iconColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Chart
                      DashboardChart(
                        items: chartData,
                        maxVal: maxVal,
                        highlightColor: const Color(0xFFEE374D),
                        chartHeight: 250,
                        formatValue: (val) {
                          if (val % 1 == 0) return val.toInt().toString();
                          return val.toStringAsFixed(1);
                        },
                        onBarTap: (index) {
                          setState(() {
                            if (_selectedView == 'Weekly') {
                              final now = DateTime.now();
                              final monday = now.subtract(
                                Duration(days: now.weekday - 1),
                              );
                              _selectedDate = monday.add(Duration(days: index));
                            } else if (_selectedView == 'Monthly') {
                              _selectedDate = DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                index + 1,
                              );
                            } else {
                              _selectedDate = DateTime(
                                DateTime.now().year,
                                index + 1,
                                1,
                              );
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Insight Card
                      const DashboardInsightCard(
                        title: 'Great job!',
                        message:
                            'Your hydration consistency has increased. Keep maintaining this schedule.',
                        iconBackgroundColor: Colors.blue,
                        backgroundColor: Color(0xFFEBF6FF),
                      ),
                      const SizedBox(height: 30),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
