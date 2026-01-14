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
import '../../../../core/presentation/widgets/swipe_confirmation_dialog.dart';

class HydrationReportPage extends StatefulWidget {
  const HydrationReportPage({super.key});

  @override
  State<HydrationReportPage> createState() => _HydrationReportPageState();
}

class _HydrationReportPageState extends State<HydrationReportPage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

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
                  _selectedDate = DateUtils.dateOnly(date);
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key(log.id),
        direction: DismissDirection.endToStart,
        background: buildSwipeBackground(),
        confirmDismiss: (direction) => showDeleteConfirmationDialog(context),
        onDismissed: (direction) {
          context.read<HydrationBloc>().add(
            DeleteHydrationLog(log.id, _selectedDate),
          );
        },
        child: GestureDetector(
          onTap: () => _navigateToTracker(logToEdit: log),
          child: Container(
            width: 356,
            height: 81,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: Color(0xFF0064F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${log.amountLiters} ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF131313),
                            ),
                          ),
                          const TextSpan(
                            text: 'L',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF909DAD),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(log.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF909DAD),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
