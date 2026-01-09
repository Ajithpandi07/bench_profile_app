import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/app_date_selector.dart';
import '../../../../core/services/app_theme.dart';
import '../../../reminder/presentation/widgets/primary_button.dart';
import '../bloc/bloc.dart';
import 'sleep_log_page.dart';
import 'sleep_stats_page.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    context.read<SleepBloc>().add(LoadSleepLogs(_selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Sleep',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<SleepBloc>(),
                    child: const SleepStatsPage(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<SleepBloc, SleepState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AppDateSelector(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                    _loadLogs();
                  },
                ),
              ),
              const SizedBox(height: 24),

              Expanded(child: _buildContent(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(SleepState state) {
    if (state is SleepLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is SleepLoaded) {
      final logs = state.logs;
      if (logs.isEmpty) {
        return _buildEmptyState();
      }
      // Assuming one main sleep per night for now, or summing them?
      // Design implies single "Sleep time" block. Let's take the longest one or sum them.
      // For now, take the first one or calculate total.
      return _buildSleepSummary(logs.first); // Simplification using first log
    } else if (state is SleepError) {
      return Center(child: Text(state.message));
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'No sleep data for this day',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: PrimaryButton(
            text: 'Record Sleep',
            onPressed: () => _navigateToLogPage(),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepSummary(dynamic log) {
    // log is SleepLog
    final duration = log.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(
      60,
    ); // Use 60 instead of standard remainder? No, remainder(60) is correct for Duration? Wait, duration.inMinutes is total minutes. % 60 is remainder.
    // Dart Duration remainder: duration.inMinutes.remainder(60) works.

    final startFormat = DateFormat('h:mm a');
    final endFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sleep time',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bedtime,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$hours',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Text(
                      ' h',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (minutes > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '$minutes',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Text(
                        ' m',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildTimeColumn(
                      'BEDTIME',
                      startFormat.format(log.startTime),
                      true,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                    _buildTimeColumn(
                      'WAKE UP',
                      endFormat.format(log.endTime),
                      false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'Edit Sleep Record',
            onPressed: () => _navigateToLogPage(log: log),
          ),
          const SizedBox(height: 16),
          // Clean text button "Enter data manually" styled
          TextButton.icon(
            onPressed: () => _navigateToLogPage(), // New log manually?
            icon: const Icon(Icons.edit, size: 16, color: Color(0xFF374151)),
            label: const Text(
              'Enter data manually',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: isStart
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF3B82F6), // Red for start, Blue for end?
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  void _navigateToLogPage({dynamic log}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<SleepBloc>(),
          child: SleepLogPage(initialDate: _selectedDate, existingLog: log),
        ),
      ),
    );

    if (result == true) {
      _loadLogs();
      // Also refresh dashboard stats?
      context.read<SleepBloc>().add(
        LoadSleepStats(
          _selectedDate.subtract(const Duration(days: 7)),
          _selectedDate,
        ),
      );
    }
  }
}
