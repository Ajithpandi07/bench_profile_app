import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/core.dart';

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
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} selected' : 'Sleep',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: _isSelectionMode
            ? IconButton(
                icon: Icon(
                  Icons.close,
                  color:
                      Theme.of(context).appBarTheme.foregroundColor ??
                      Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : BackButton(
                color:
                    Theme.of(context).appBarTheme.foregroundColor ??
                    Colors.black,
              ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color:
                        Theme.of(context).appBarTheme.foregroundColor ??
                        Colors.black,
                  ),
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete selected logs?'),
                              content: Text(
                                'Are you sure you want to delete ${_selectedIds.length} items?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<SleepBloc>().add(
                                      DeleteMultipleSleepLogs(
                                        _selectedIds.toList(),
                                        _selectedDate,
                                      ),
                                    );
                                    setState(() {
                                      _isSelectionMode = false;
                                      _selectedIds.clear();
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                ),
              ]
            : [
                IconButton(
                  icon: Icon(
                    Icons.bar_chart,
                    color:
                        Theme.of(context).appBarTheme.foregroundColor ??
                        Colors.black,
                  ),
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
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color:
                        Theme.of(context).appBarTheme.foregroundColor ??
                        Colors.black,
                  ),
                  onSelected: (value) {
                    if (value == 'add') {
                      _navigateToLogPage();
                    } else if (value == 'delete') {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedIds.clear();
                      });
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'add',
                          child: Text('Add new'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Bulk delete'),
                        ),
                      ],
                ),
              ],
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: BlocListener<SleepBloc, SleepState>(
        listener: (context, state) {
          if (state is SleepOperationSuccess && state.message != null) {
            showModernSnackbar(context, state.message!);
          } else if (state is SleepError) {
            // SnackbarUtils.showSnackbar(context, state.message);
            // Error is handled by _buildContent usually, or we can handle it here and remove it from _buildContent?
            // For now, let's keep _buildContent handling or add snackbar for error too if desired.
            // But let's stick to the user request "Deleted successfully snackbar".
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

  Widget _buildContent(SleepState state) {
    if (state is SleepLoading ||
        state is SleepOperationSuccess ||
        state is SleepStatsLoaded) {
      return const SleepShimmerLoading();
    } else if (state is SleepLoaded) {
      final logs = state.logs;
      if (logs.isEmpty) {
        if (state.healthConnectDraft != null) {
          return _buildLoggedState([state.healthConnectDraft!]);
        }
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

          Center(
            child: GestureDetector(
              onTap: _navigateToLogPage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Enter manually',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
              return Slidable(
                key: Key(log.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.5,
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        _navigateToLogPage(log: log);
                      },
                      backgroundColor: AppTheme.lightGray,
                      foregroundColor: Theme.of(context).primaryColor,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                    SlidableAction(
                      onPressed: (context) async {
                        final confirm = await showDeleteConfirmationDialog(
                          context,
                        );
                        if (confirm == true && context.mounted) {
                          context.read<SleepBloc>().add(DeleteSleepLog(log));
                        }
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16),
                      ),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    if (_isSelectionMode) {
                      setState(() {
                        if (_selectedIds.contains(log.id)) {
                          _selectedIds.remove(log.id);
                        } else {
                          _selectedIds.add(log.id);
                        }
                      });
                    } else {
                      _navigateToLogPage(log: log);
                    }
                  },
                  child: Row(
                    children: [
                      if (_isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Checkbox(
                            value: _selectedIds.contains(log.id),
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(log.id);
                                } else {
                                  _selectedIds.remove(log.id);
                                }
                              });
                            },
                          ),
                        ),
                      Expanded(
                        child: SleepLogItem(
                          log: log,
                          // Disable internal tap in selection mode if item has one,
                          // but GestureDetector above handles it.
                          // Pass null or handle? SleepLogItem likely has no internal tap
                          // if we passed onTap previously?
                          // Ah, we passed onTap: () => _navigateToLogPage(log: log).
                          // We should disable that callback if selection mode, BUT
                          // our GestureDetector above intercepts taps on the whole row?
                          // Yes, but if SleepLogItem uses InkWell/GestureDetector it might compete.
                          // The safest is to suppress the callback if selection mode.
                          onTap: _isSelectionMode
                              ? null
                              : () => _navigateToLogPage(log: log),
                        ),
                      ),
                    ],
                  ),
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
          const SizedBox(height: 40),

          Center(
            child: GestureDetector(
              onTap: _navigateToLogPage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Enter manually',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
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
