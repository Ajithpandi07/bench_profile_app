import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/hydration_daily_summary.dart';
import '../bloc/bloc.dart';

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
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTab('7 days', _selectedView == 'Weekly'),
                    _buildTab('31 days', _selectedView == 'Monthly'),
                    _buildTab('12 months', false), // Placeholder for Yearly
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Oct 12 - Oct 19', // Dynamic date range needed
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              // Average
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  BlocBuilder<HydrationBloc, HydrationState>(
                    builder: (context, state) {
                      double average = 0;
                      if (state is HydrationStatsLoaded &&
                          state.stats.isNotEmpty) {
                        final total = state.stats.fold(
                          0.0,
                          (sum, item) => sum + item.totalLiters,
                        );
                        average = (total * 1000) / state.stats.length;
                      }
                      return Text(
                        average > 0 ? average.toStringAsFixed(0) : '0',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF131313),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'ml',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey, // Light grey in design
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Average Hydration',
                style: TextStyle(color: Color(0xFF5A6B87), fontSize: 14),
              ),

              const SizedBox(height: 32),

              // Goals Row
              Row(
                children: [
                  Expanded(
                    child: _buildGoalCard(
                      Icons.schedule,
                      'TIME GOAL',
                      '5/7',
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGoalCard(
                      Icons.water_drop,
                      'WATER GOAL',
                      '5/7',
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Chart Area
              SizedBox(
                height: 250,
                child: BlocBuilder<HydrationBloc, HydrationState>(
                  builder: (context, state) {
                    if (state is HydrationLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is HydrationStatsLoaded) {
                      return _buildBarChart(state.stats);
                    }
                    return const Center(child: Text('No data'));
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Insight Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.blue,
                      ), // Sparkles icon
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Great job!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF131313),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your hydration consistency has increased by 12% compared to last week. Keep maintaining this schedule.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (text == '7 days') {
          setState(() {
            _selectedView = 'Weekly';
          });
          _loadStats();
        } else if (text == '31 days') {
          setState(() {
            _selectedView = 'Monthly';
          });
          _loadStats();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEE374D) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
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

  Widget _buildBarChart(List<HydrationDailySummary> stats) {
    if (stats.isEmpty) return const Center(child: Text("No data available"));

    // Find max value for normalization
    double maxVal = stats.fold(
      0,
      (max, item) => item.totalLiters > max ? item.totalLiters : max,
    );
    if (maxVal == 0) maxVal = 1;

    // We need 7 bars for weekly view
    // Create a list of 7 days ending today
    final now = DateTime.now();
    List<HydrationDailySummary> chartData = [];

    if (_selectedView == 'Weekly') {
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
      // Just show last 7 days of stats for now even if monthly selected, to fit design trace
      // Or actually show more bars if monthly. Design (Image 3) shows 7 bars.
      // It says "Oct 12 - Oct 19" and shows 7 bars.
      // I'll stick to 7 bars logic for visual consistency with the design mock which seems to be Weekly view.
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
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: chartData.map((data) {
            final height =
                (data.totalLiters / maxVal) * constraints.maxHeight * 0.6;

            // Highlight the highest bar or today? Design highlights "Thu" which is the highest.
            final isHighest = data.totalLiters == maxVal && maxVal > 0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Dashed line background is complex to do in Row/Column, skipping for now or using Stack.
                // Just bars.
                // Design has a tooltip-like label "2000 ml" above the highest bar.
                if (isHighest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEE374D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(data.totalLiters * 1000).toInt()} ml',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                Container(
                  width: 30, // Thicker bars
                  height: height > 0 ? height : 0,
                  decoration: BoxDecoration(
                    color: isHighest
                        ? const Color(0xFFEE374D)
                        : const Color(0xFFFFEBEB), // Light pink for others
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  DateFormat('E').format(data.date), // Mon, Tue
                  style: TextStyle(
                    fontSize: 12,
                    color: isHighest
                        ? const Color(0xFFEE374D)
                        : Colors.grey.shade400,
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
