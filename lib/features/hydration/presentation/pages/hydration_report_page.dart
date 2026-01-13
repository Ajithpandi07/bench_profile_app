import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/app_date_selector.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../bloc/bloc.dart';
import '../../domain/entities/hydration_log.dart';
import '../widgets/water_list_shimmer.dart';
import 'hydration_tracker_page.dart';
import 'hydration_dashboard_page.dart';
import '../widgets/hydration_summary_card.dart';

class HydrationReportPage extends StatefulWidget {
  const HydrationReportPage({super.key});

  @override
  State<HydrationReportPage> createState() => _HydrationReportPageState();
}

class _HydrationReportPageState extends State<HydrationReportPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    context.read<HydrationBloc>().add(LoadHydrationLogs(_selectedDate));
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
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, color: Colors.black54),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<HydrationBloc>(),
                    child: const HydrationDashboardPage(),
                  ),
                ),
              );
              if (mounted) {
                _loadLogs();
              }
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: BlocBuilder<HydrationBloc, HydrationState>(
        builder: (context, state) {
          if (state is HydrationLogsLoaded && state.logs.isNotEmpty) {
            return FloatingActionButton(
              onPressed: _navigateToTracker,
              backgroundColor: const Color(0xFFEE374D),
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: BlocListener<HydrationBloc, HydrationState>(
        listener: (context, state) {
          if (state is HydrationFailure) {
            showModernSnackbar(context, state.message, isError: true);
          }
        },
        child: Column(
          children: [
            const SizedBox(height: 2),
            // Date Selector
            AppDateSelector(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
                _loadLogs();
              },
            ),
            const SizedBox(height: 16),

            // Main Content
            Expanded(
              child: BlocBuilder<HydrationBloc, HydrationState>(
                builder: (context, state) {
                  if (state is HydrationLoading) {
                    return const WaterListShimmer();
                  } else if (state is HydrationLogsLoaded) {
                    final logs = state.logs;
                    if (logs.isEmpty) {
                      return _buildEmptyState();
                    } else {
                      return _buildLoggedState(logs);
                    }
                  } else if (state is HydrationFailure) {
                    return Center(child: Text(state.message));
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

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            HydrationSummaryCard(currentLiters: 0, targetLiters: 3.0),
            const SizedBox(height: 40),

            // Manual Entry Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToTracker,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.edit,
                        color: Color(0xFFEE374D),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Enter water manually',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF131313),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedState(List<HydrationLog> logs) {
    final totalLiters = logs.fold(0.0, (sum, log) => sum + log.amountLiters);
    final targetLiters = 3.0;

    // Get last added time
    String? lastAddedTime;
    if (logs.isNotEmpty) {
      // Assuming logs are sorted or we find the latest
      // logs are usually sorted by date descending in Bloc or Repository
      // Let's sort just in case or take the one with max date
      final latestLog = logs.reduce(
        (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
      );
      lastAddedTime = DateFormat('hh:mm a').format(latestLog.timestamp);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        HydrationSummaryCard(
          currentLiters: totalLiters,
          targetLiters: targetLiters,
          lastAddedTime: lastAddedTime,
        ),
        const SizedBox(height: 24),
        ...logs.map((log) => _buildLogItem(log)),
        const SizedBox(height: 24),
        _buildInsightCard(totalLiters, targetLiters),
        const SizedBox(height: 100), // Spacing for bottom
      ],
    );
  }

  Widget _buildInsightCard(double totalLiters, double targetLiters) {
    // Calculate percentage and prevent overflow/infinity
    double percentage = 0;
    if (targetLiters > 0) {
      percentage = ((totalLiters / targetLiters) * 100);
    }

    String statusTitle;
    String statusMessage;
    Color statusColor;

    if (percentage < 40) {
      statusTitle = 'Needs Attention';
      statusMessage = 'Your water intake is low.';
      statusColor = Colors.red;
    } else if (percentage < 80) {
      statusTitle = 'Average';
      statusMessage = 'Your water intake is average.';
      statusColor = Colors.orange;
    } else {
      statusTitle = 'Perfect';
      statusMessage = 'Your water intake is perfect.';
      statusColor = Colors.green;
    }

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image with Status Chip
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/water_card_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusTitle,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${percentage.toInt()} / 100',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131313),
                  ),
                ),
                const SizedBox(height: 4),
                Text(statusMessage, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(HydrationLog log) {
    return Container(
      height: 140, // Fixed height as per request
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.06),
            offset: const Offset(0, 19),
            blurRadius: 32.6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Row: Icon + "WATER"
                Row(
                  children: [
                    Container(
                      width: 32, // Reduced from 40
                      height: 32, // Reduced from 40
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Color(0xFF3B9BFF),
                        size: 16, // Reduced from 20
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'WATER',
                      style: TextStyle(
                        fontSize: 12, // Reduced from 14
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${(log.amountLiters * 1000).toInt()}',
                      style: const TextStyle(
                        fontSize: 28, // Reduced from 32
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF131313),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ml',
                      style: TextStyle(
                        fontSize: 16, // Reduced from 18
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2), // Reduced from 4
                // Time
                Text(
                  DateFormat('hh:mm a').format(log.timestamp),
                  style: TextStyle(
                    fontSize: 13, // Reduced from 14
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4), // Reduced from 8
              ],
            ),
          ),
          // Right Button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA), // Light grey background
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.black87),
              onPressed: () => _navigateToTracker(logToEdit: log),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToTracker({HydrationLog? logToEdit}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<HydrationBloc>(),
          child: HydrationTrackerPage(
            initialDate: _selectedDate,
            logToEdit: logToEdit,
          ),
        ),
      ),
    );

    if (result == true) {
      _loadLogs();
    }
  }
}
