import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/app_theme.dart';
import '../../domain/entities/hydration_daily_summary.dart';
import '../bloc/bloc.dart';
import '../widgets/water_list_shimmer.dart';

class HydrationDashboardPage extends StatefulWidget {
  const HydrationDashboardPage({super.key});

  @override
  State<HydrationDashboardPage> createState() => _HydrationDashboardPageState();
}

class _HydrationDashboardPageState extends State<HydrationDashboardPage> {
  String _selectedView = 'Weekly'; // Default to Weekly as per request focus

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    if (_selectedView == 'Today') {
      startDate = now;
      endDate = now;
    } else if (_selectedView == 'Weekly') {
      // Last 7 days including today
      startDate = now.subtract(const Duration(days: 6));
    } else {
      // Monthly (Start of current month)
      startDate = DateTime(now.year, now.month, 1);
    }

    // Ensure we strip time for accurate date comparisons in logic if needed,
    // though the repo handles it.
    context.read<HydrationBloc>().add(
      LoadHydrationStats(startDate: startDate, endDate: endDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Hydration Dashboard',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // View Selectors
            Row(
              children: [
                _buildViewButton('Today'),
                const SizedBox(width: 8),
                _buildViewButton('Weekly'),
                const SizedBox(width: 8),
                _buildViewButton('Monthly'),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: BlocBuilder<HydrationBloc, HydrationState>(
                builder: (context, state) {
                  if (state is HydrationLoading) {
                    return const WaterListShimmer();
                  } else if (state is HydrationStatsLoaded) {
                    return _buildStatsView(state.stats);
                  } else if (state is HydrationFailure) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewButton(String view) {
    final isSelected = _selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = view;
          });
          _loadStats();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              view,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsView(List<HydrationDailySummary> stats) {
    // Calculate total from stats
    double total = stats.fold(0, (sum, item) => sum + item.totalLiters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Total Intake (${_selectedView})',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '${total.toStringAsFixed(1)} L',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 7 Days Chart (Only for Weekly/Monthly view to show trends)
        if (_selectedView == 'Weekly') ...[
          const Text(
            'Last 7 Days',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBarChart(stats)),
        ] else if (_selectedView == 'Monthly') ...[
          const Text(
            'Daily Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBarChart(stats)),
        ],
      ],
    );
  }

  Widget _buildBarChart(List<HydrationDailySummary> stats) {
    if (stats.isEmpty) return const Center(child: Text("No data available"));

    // Find max value for normalization
    double maxVal = stats.fold(
      0,
      (max, item) => item.totalLiters > max ? item.totalLiters : max,
    );
    if (maxVal == 0) maxVal = 1; // Avoid division by zero

    // For Weekly, we want to ensure we show 7 bars even if data is missing
    List<HydrationDailySummary> chartData = [];

    if (_selectedView == 'Weekly') {
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final summary = stats.firstWhere(
          (element) =>
              element.date.year == date.year &&
              element.date.month == date.month &&
              element.date.day == date.day,
          orElse: () => HydrationDailySummary(date: date, totalLiters: 0),
        );
        chartData.add(summary);
      }
    } else {
      chartData = stats;
      // create a full month view if needed, but for now just showing what we have is okay or
      // better yet, fill holes for simple bar chart
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: chartData.map((data) {
            final height =
                (data.totalLiters / maxVal) *
                constraints.maxHeight *
                0.7; // 70% max height
            final isToday = DateUtils.isSameDay(data.date, DateTime.now());

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (data.totalLiters > 0)
                  Text(
                    '${data.totalLiters.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: height > 0 ? height : 1, // Min height
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('E').format(data.date), // Mon, Tue
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
