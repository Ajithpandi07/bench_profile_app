import '../widgets/dashboard_shimmer.dart';
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
  String _selectedView = 'Weekly'; // 'Weekly', 'Monthly', 'Yearly'
  DateTime? _selectedTooltipDate; // Selected date for tooltip

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
      startDate = now.subtract(Duration(days: daysToSubtract));
      endDate = startDate.add(const Duration(days: 6));
      // Ensure we strip time or handle it. Repo uses start/end.
      // If today is Wed, we want Mon-Sun. End date is future? That's fine, data will be 0.
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

    // Reset tooltip selection when view changes
    setState(() {
      _selectedTooltipDate = null;
    });

    context.read<HydrationBloc>().add(
      LoadHydrationStats(startDate: startDate, endDate: endDate),
    );
  }

  List<HydrationDailySummary> _processChartData(
    List<HydrationDailySummary> rawStats,
  ) {
    // We must generate ALL slots even if empty, to maintain static axis
    final now = DateTime.now();
    List<HydrationDailySummary> processed = [];

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
    return processed;
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTab('7 days', 'Weekly'),
                    _buildTab('31 days', 'Monthly'),
                    _buildTab('12 months', 'Yearly'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                _getDateRangeText(),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Average Display
              BlocBuilder<HydrationBloc, HydrationState>(
                builder: (context, state) {
                  double average = 0;

                  if (state is HydrationStatsLoaded && state.stats.isNotEmpty) {
                    final processed = _processChartData(state.stats);
                    // Filter out future dates if any, though our process limits it.
                    // For average, we might want average of non-zero days or all days in range?
                    // Typically average daily intake over the period.
                    double total = processed.fold(
                      0.0,
                      (sum, item) => sum + item.totalLiters,
                    );
                    average = (total * 1000) / processed.length;
                  }

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            average > 0 ? average.toStringAsFixed(0) : '0',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF131313),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'ml',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Average Hydration',
                        style: TextStyle(
                          color: Color(0xFF5A6B87),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Goals Row
              BlocBuilder<HydrationBloc, HydrationState>(
                builder: (context, state) {
                  String waterGoal = '0/7';
                  String timeGoal = '0/7'; // Assuming similar logic or mockup

                  if (state is HydrationStatsLoaded) {
                    final processed = _processChartData(state.stats);
                    int achieved = processed
                        .where((e) => e.totalLiters >= 3.0)
                        .length;
                    int totalDays = processed.length;
                    waterGoal = '$achieved/$totalDays';
                    timeGoal =
                        '$achieved/$totalDays'; // Placeholder logic for time
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildGoalCard(
                          Icons.schedule,
                          'TIME GOAL',
                          timeGoal,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGoalCard(
                          Icons.water_drop,
                          'WATER GOAL',
                          waterGoal,
                          Colors.blue,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Chart Area
              SizedBox(
                height: 300, // Increased height for grid labels
                child: BlocBuilder<HydrationBloc, HydrationState>(
                  builder: (context, state) {
                    if (state is HydrationLoading) {
                      return const DashboardShimmer();
                    } else if (state is HydrationStatsLoaded) {
                      final data = _processChartData(state.stats);
                      return _buildCustomBarChart(data);
                    }
                    return const Center(child: Text('No data'));
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Insight Card (Static for now as per previous)
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
                      child: const Icon(Icons.auto_awesome, color: Colors.blue),
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
                            'Your hydration consistency has increased. Keep maintaining this schedule.',
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

  Widget _buildTab(String text, String viewKey) {
    final isSelected = _selectedView == viewKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = viewKey;
        });
        _loadStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  Widget _buildCustomBarChart(List<HydrationDailySummary> data) {
    if (data.isEmpty) return const SizedBox();

    double maxVal = data.fold(
      0.0,
      (prev, e) => e.totalLiters > prev ? e.totalLiters : prev,
    );
    if (maxVal < 1.0) maxVal = 1.0;
    maxVal = maxVal * 1.2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = constraints.maxHeight;

        const double yAxisWidth = 30.0;

        const double xAxisHeight = 30.0;
        final double chartHeight = height - xAxisHeight - 20;

        return Stack(
          children: [
            // Y-Axis Labels and Grid Lines
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              height: chartHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final value = maxVal * (1 - (index / 4));
                  String labelText = '';
                  if (value % 1 == 0) {
                    labelText = '${value.toInt()}L';
                  } else {
                    labelText = '${value.toStringAsFixed(1)}L';
                  }

                  return Row(
                    children: [
                      SizedBox(
                        width: yAxisWidth,
                        child: Text(
                          labelText,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.transparent,
                          child: CustomPaint(
                            painter: DashedLinePainter(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            // Bars (Static Row + Flexible)
            Padding(
              padding: const EdgeInsets.only(
                left: yAxisWidth,
                bottom: xAxisHeight,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  final double barHeight =
                      (item.totalLiters / maxVal) * chartHeight;

                  final isSelected =
                      _selectedTooltipDate != null &&
                      _selectedTooltipDate!.year == item.date.year &&
                      _selectedTooltipDate!.month == item.date.month &&
                      _selectedTooltipDate!.day == item.date.day;

                  // Highlight today
                  final isToday =
                      item.date.year == DateTime.now().year &&
                      item.date.month == DateTime.now().month &&
                      item.date.day == DateTime.now().day;

                  String label;
                  if (_selectedView == 'Weekly') {
                    label = DateFormat('E').format(item.date); // Mon
                  } else if (_selectedView == 'Yearly') {
                    label = DateFormat('MMM').format(item.date);
                  } else {
                    // Monthly: 1, 2, ...
                    // Logic to hide some labels if too dense
                    // Show 1, 5, 10, 15, 20, 25, 30
                    if (item.date.day == 1 || item.date.day % 5 == 0) {
                      label = item.date.day.toString();
                    } else {
                      label = '';
                    }
                  }

                  Color barColor = isToday
                      ? const Color(0xFFEE374D)
                      : const Color(0xFFFFEBEB);
                  if (isSelected) barColor = const Color(0xFFEE374D);

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _selectedTooltipDate = item.date;
                        });
                      },
                      child: Container(
                        color: Colors.transparent, // Touch target
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Tooltip (Only if Selected)
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6, // Slightly more padding
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEE374D),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${(item.totalLiters * 1000).toInt()}',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12, // Increased from 8
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: isSelected
                                    ? 0
                                    : 26, // Adjusted placeholder height
                              ),

                            Expanded(child: Container()), // Push down
                            // Bar
                            Container(
                              width: _selectedView == 'Weekly'
                                  ? 24 // Increased for 7 days
                                  : _selectedView == 'Monthly'
                                  ? 6
                                  : 16, // Slightly wider for Yearly too
                              height: barHeight > 0 ? barHeight : 0,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Label
                            SizedBox(
                              height: 12,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: (isToday || isSelected)
                                      ? const Color(0xFFEE374D)
                                      : Colors.grey.shade400,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4;
    const dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
