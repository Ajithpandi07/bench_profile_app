import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/app_date_selector.dart';
import '../../../../core/services/app_theme.dart';
import '../bloc/bloc.dart';
import 'sleep_log_page.dart';
import 'sleep_stats_page.dart';
import 'package:bench_profile_app/features/sleep/presentation/widgets/sleep_shimmer_loading.dart';
import '../../domain/entities/sleep_log.dart';
import '../widgets/sleep_summary_card.dart';
import '../widgets/sleep_log_item.dart';
import '../../../../core/presentation/widgets/swipe_confirmation_dialog.dart';

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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<SleepBloc>(),
                    child: const SleepStatsPage(),
                  ),
                ),
              );
              if (mounted) _loadLogs();
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
      body: BlocListener<SleepBloc, SleepState>(
        listener: (context, state) {
          if (state is SleepLoaded &&
              state.healthConnectDraft != null &&
              state.logs.isEmpty) {
            _showHealthConnectDialog(context, state.healthConnectDraft!);
          }
        },
        child: BlocBuilder<SleepBloc, SleepState>(
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
      ),
    );
  }

  void _showHealthConnectDialog(BuildContext context, SleepLog log) {
    // Capture the Bloc instance from the current context
    final sleepBloc = context.read<SleepBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        // Return a helper wrapped in BlocProvider.value
        // We use sheetContext for the builder, but use sleepBloc from parent
        return BlocProvider.value(
          value: sleepBloc,
          child: Builder(
            builder: (context) {
              final duration = log.duration;
              final h = duration.inHours;
              final m = duration.inMinutes.remainder(60);
              final startFormat = DateFormat('h:mm a');
              final endFormat = DateFormat('h:mm a');

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: "Sleep time" and Moon Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sleep time',
                          style: TextStyle(
                            color: Color(0xFF6B7280), // Colors.grey[500]
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2), // Light red bg
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bedtime_outlined, // Moon outline style
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Big Duration Text (e.g. "9 h" or "9 h 30 m")
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$h',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'h',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (m > 0) ...[
                          const SizedBox(width: 16),
                          Text(
                            '$m',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'm',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Bedtime -> Wake Up Visual Row
                    Row(
                      children: [
                        // BEDTIME
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFEF4444),
                                        Color(0xFFFF8A8A),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'BEDTIME',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              startFormat.format(log.startTime),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),

                        // Arrow
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),

                        // WAKE UP
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WAKE UP',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              endFormat.format(log.endTime),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          final newLog = SleepLog(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            startTime: log.startTime,
                            endTime: log.endTime,
                            quality: log.quality,
                            notes: log.notes,
                          );
                          context.read<SleepBloc>().add(LogSleep(newLog));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFEF4444,
                          ), // Primary Red
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Record this time',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(SleepState state) {
    if (state is SleepLoading ||
        state is SleepOperationSuccess ||
        state is SleepStatsLoaded) {
      return const SleepShimmerLoading();
    } else if (state is SleepLoaded) {
      final logs = state.logs;
      if (logs.isEmpty) {
        return _buildEmptyState();
      }
      // Assuming one main sleep per night for now, or summing them?
      // Design implies single "Sleep time" block. Let's take the longest one or sum them.
      // For now, take the first one or calculate total.
      return _buildLoggedState(logs); // Pass all logs
    } else if (state is SleepError) {
      return Center(child: Text(state.message));
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const SleepSummaryCard(), // Empty card state
          const SizedBox(height: 40),

          // Action Button (Enter Manually)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _navigateToLogPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF111827),
                elevation: 0,
                side: BorderSide(color: Colors.grey.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit, size: 20, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text(
                    'Enter manually',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedState(List<SleepLog> logs) {
    // Find the "main" sleep (longest duration) for the top summary
    final mainLog = logs.fold(
      logs.first,
      (prev, curr) => curr.duration > prev.duration ? curr : prev,
    );

    // Calculate quality percentage for insight
    final qualityScore = mainLog.quality;

    String statusTitle;
    Color statusColor;

    if (qualityScore < 50) {
      statusTitle = 'Needs Attention';
      statusColor = Colors.red;
    } else if (qualityScore < 80) {
      statusTitle = 'Good';
      statusColor = Colors.orange;
    } else {
      statusTitle = 'Excellent';
      statusColor = Colors.green;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        children: [
          // Summary Card (Main Sleep)
          SleepSummaryCard(
            log: mainLog,
            // onTap: () => _navigateToLogPage(log: mainLog),
          ),
          const SizedBox(height: 24),

          // List of Logs (Separate Cards)
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Dismissible(
                key: Key(log.id),
                direction: DismissDirection.endToStart,
                background: buildSwipeBackground(),
                confirmDismiss: (direction) =>
                    showDeleteConfirmationDialog(context),
                onDismissed: (direction) {
                  context.read<SleepBloc>().add(DeleteSleepLog(log));
                },
                child: SleepLogItem(
                  log: log,
                  onTap: () => _navigateToLogPage(log: log),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Insight Card
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Dark blue/navy bg
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Stars/Background decorations (simplified)
                Positioned(
                  top: 20,
                  left: 20,
                  child: Icon(
                    Icons.star,
                    color: Colors.yellow.withOpacity(0.5),
                    size: 12,
                  ),
                ),
                Positioned(
                  bottom: 40,
                  right: 30,
                  child: Icon(
                    Icons.star,
                    color: Colors.yellow.withOpacity(0.5),
                    size: 8,
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 80,
                  child: Icon(
                    Icons.star,
                    color: Colors.yellow.withOpacity(0.5),
                    size: 10,
                  ),
                ),

                // Moon Icon (Large)
                Positioned(
                  top: 20,
                  left: 80,
                  child: Transform.rotate(
                    angle: -0.5,
                    child: const Icon(
                      Icons.nightlight_round,
                      color: Colors.white,
                      size: 80, // Large moon
                    ),
                  ),
                ),

                Column(
                  children: [
                    // Top Pill
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
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

                    const SizedBox(height: 60), // Space for moon/graphic
                    // Bottom White Area
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$qualityScore',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const TextSpan(
                                  text: ' /100',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            qualityScore < 70
                                ? 'Your sleep quality was low.'
                                : 'Your sleep quality was great.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
    }
  }
}
