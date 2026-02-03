import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../../../core/core.dart';
import '../bloc/bloc.dart';
import '../../domain/entities/hydration_log.dart';
import '../widgets/water_list_shimmer.dart';
import 'hydration_tracker_page.dart';
import 'hydration_dashboard_page.dart';
import '../widgets/hydration_summary_card.dart';
import '../../../../core/presentation/widgets/swipe_confirmation_dialog.dart';

class HydrationReportPage extends StatefulWidget {
  static const String routeName = '/hydration-report';
  const HydrationReportPage({super.key});

  @override
  State<HydrationReportPage> createState() => _HydrationReportPageState();
}

class _HydrationReportPageState extends State<HydrationReportPage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

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
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} selected' : 'Water',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.black),
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          final bloc = context.read<HydrationBloc>();
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
                                    final idsToDelete = _selectedIds.toList();
                                    debugPrint(
                                      'UI: DELETE PRESSED for IDs: $idsToDelete',
                                    );
                                    Navigator.pop(context);
                                    bloc.add(
                                      DeleteMultipleHydrationLogs(
                                        logIds: idsToDelete,
                                        date: _selectedDate,
                                      ),
                                    );
                                    setState(() {
                                      _isSelectionMode = false;
                                      _selectedIds.clear();
                                    });
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
                  icon: const Icon(
                    Icons.bar_chart_outlined,
                    color: Colors.black54,
                  ),
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                  onSelected: (value) {
                    if (value == 'add') {
                      _navigateToTracker();
                    } else if (value == 'delete') {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedIds.clear();
                      });
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final isFuture = _selectedDate.isAfter(
                      DateUtils.dateOnly(DateTime.now()),
                    );
                    return <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'add',
                        enabled: !isFuture,
                        child: Text(
                          'Add new',
                          style: TextStyle(
                            color: isFuture ? Colors.grey : null,
                          ),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Bulk delete'),
                      ),
                    ];
                  },
                ),
              ],
      ),
      body: BlocListener<HydrationBloc, HydrationState>(
        listener: (context, state) {
          debugPrint('UI: Listener received state: $state');
          if (state is HydrationFailure) {
            showModernSnackbar(context, state.message, isError: true);
          } else if (state is HydrationLogsLoaded &&
              state.snackbarMessage != null) {
            debugPrint('UI: Showing Snackbar from Loaded state');
            showModernSnackbar(context, state.snackbarMessage!);
          } else if (state is HydrationDeletedSuccess) {
            debugPrint('UI: Showing Success Snackbar (Legacy)');
            // Keep strictly for single delete if that still uses it,
            // otherwise this branch might be dead code for bulk delete now.
            showModernSnackbar(context, 'Water log deleted successfully');
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
                  debugPrint(
                    'UI: BlocBuilder Rebuild with state: $state. Bloc Hash: ${context.read<HydrationBloc>().hashCode}',
                  );
                  if (state is HydrationLoading ||
                      state is HydrationDeletedSuccess) {
                    return const WaterListShimmer();
                  } else if (state is HydrationLogsLoaded) {
                    final logs = state.logs;
                    final target = state.targetWater;
                    if (logs.isEmpty) {
                      return _buildEmptyState(targetLiters: target);
                    } else {
                      return _buildLoggedState(logs, targetLiters: target);
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

  Widget _buildManualEntryButton() {
    final isFuture = _selectedDate.isAfter(DateUtils.dateOnly(DateTime.now()));
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isFuture ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isFuture) {
                showModernSnackbar(
                  context,
                  'Cannot log water for future dates',
                  isError: true,
                );
                return;
              }
              _navigateToTracker();
            },
            borderRadius: BorderRadius.circular(30),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit,
                  color: isFuture ? Colors.grey : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Enter water manually',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isFuture ? Colors.grey : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({double? targetLiters}) {
    final effectiveTarget = targetLiters ?? 3.0;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            HydrationSummaryCard(
              currentLiters: 0,
              targetLiters: effectiveTarget,
            ),
            const SizedBox(height: 40),

            // Manual Entry Button
            _buildManualEntryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedState(List<HydrationLog> logs, {double? targetLiters}) {
    final totalLiters = logs.fold(0.0, (sum, log) => sum + log.amountLiters);
    final effectiveTarget = targetLiters ?? 3.0;

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
          targetLiters: effectiveTarget,
          lastAddedTime: lastAddedTime,
        ),
        const SizedBox(height: 24),
        ...logs.map((log) => _buildLogItem(log)),
        const SizedBox(height: 24),
        _buildInsightCard(totalLiters, effectiveTarget),
        const SizedBox(height: 24),
        _buildManualEntryButton(),
        const SizedBox(height: 40), // Spacing for bottom
      ],
    );
  }

  Widget _buildInsightCard(double totalLiters, double targetLiters) {
    // Calculate percentage and prevent overflow/infinity
    double percentage = 0;
    if (targetLiters > 0) {
      percentage = ((totalLiters / targetLiters) * 100).clamp(0, 100);
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
    } else if (percentage < 100) {
      statusTitle = 'Perfect';
      statusMessage = 'Your water intake is perfect.';
      statusColor = Colors.green;
    } else {
      statusTitle = 'Goal Met!';
      statusMessage = 'You hit your daily target!';
      statusColor = const Color(0xFF00C853);
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
                image: AssetImage('assets/images/water_card_bg.png'),
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
                    color: AppTheme.textDark,
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
      child: Slidable(
        key: Key(log.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.5,
          children: [
            SlidableAction(
              onPressed: (context) {
                _navigateToTracker(logToEdit: log);
              },
              backgroundColor: AppTheme.lightGray,
              foregroundColor: const Color(0xFF0064F6), // Match water color
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) async {
                final bloc = context.read<HydrationBloc>();
                debugPrint(
                  'DEBUG: Slidable Delete Pressed for Hydration: ${log.id}',
                );
                final confirm = await showDeleteConfirmationDialog(context);
                if (confirm == true && mounted) {
                  debugPrint('DEBUG: Adding DeleteHydrationLog to Bloc');
                  bloc.add(DeleteHydrationLog(log.id, _selectedDate));
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
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedIds.add(log.id);
              });
            }
          },
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (_selectedIds.contains(log.id)) {
                  _selectedIds.remove(log.id);
                  if (_selectedIds.isEmpty) {
                    _isSelectionMode = false;
                  }
                } else {
                  _selectedIds.add(log.id);
                }
              });
            } else {
              _navigateToTracker(logToEdit: log);
            }
          },
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Checkbox(
                    value: _selectedIds.contains(log.id),
                    activeColor: AppTheme.primaryColor, // Match theme
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
                child: Container(
                  width: double.infinity,
                  height: 81,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
                                    color: AppTheme.textDark,
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToTracker({HydrationLog? logToEdit}) async {
    // Calculate current stats
    double currentDailyTotal = 0;
    double dailyTarget = 3.0;

    final state = context.read<HydrationBloc>().state;
    if (state is HydrationLogsLoaded) {
      currentDailyTotal = state.logs.fold(
        0.0,
        (sum, log) => sum + log.amountLiters,
      );
      if (state.targetWater != null) {
        dailyTarget = state.targetWater!;
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<HydrationBloc>(),
          child: HydrationTrackerPage(
            initialDate: _selectedDate,
            logToEdit: logToEdit,
            currentDailyTotal: currentDailyTotal,
            dailyTarget: dailyTarget,
          ),
        ),
      ),
    );

    if (result == true) {
      _loadLogs();
    }
  }
}
