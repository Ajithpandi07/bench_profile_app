import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/app_date_selector.dart';
import '../../../../core/services/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/activity_log.dart';
import '../bloc/activity_bloc.dart';
import '../bloc/activity_event.dart';
import '../bloc/activity_state.dart';
import '../widgets/activity_summary_card.dart';
import '../widgets/activity_type_selector.dart';
import 'add_activity_page.dart';
import 'activity_stats_page.dart';
import '../widgets/activity_report_shimmer.dart';
import '../../../health_metrics/presentation/bloc/health_metrics_bloc.dart';
import '../../../health_metrics/presentation/bloc/health_metrics_event.dart';
import '../../../health_metrics/presentation/bloc/health_metrics_state.dart';

class ActivityReportPage extends StatefulWidget {
  const ActivityReportPage({super.key});

  @override
  State<ActivityReportPage> createState() => _ActivityReportPageState();
}

class _ActivityReportPageState extends State<ActivityReportPage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    context.read<ActivityBloc>().add(LoadActivitiesForDate(_selectedDate));
    context.read<HealthMetricsBloc>().add(GetMetricsForDate(_selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} selected' : 'Activity',
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
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.black),
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete selected activities?'),
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
                                    context.read<ActivityBloc>().add(
                                      DeleteMultipleActivities(
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
                  icon: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.black,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<ActivityBloc>(),
                          child: const ActivityStatsPage(),
                        ),
                      ),
                    );
                    if (mounted) {
                      _loadActivities();
                    }
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onSelected: (value) {
                    if (value == 'add') {
                      _showActivityTypeSelector();
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
                const SizedBox(width: 8),
              ],
      ),
      body: Column(
        children: [
          // Date Selector remains static
          BlocBuilder<ActivityBloc, ActivityState>(
            buildWhen: (previous, current) =>
                current is! ActivityLoading && // Should not rebuild on loading
                current
                    is! ActivityOperationSuccess && // Should not rebuild on toast events
                current is! ActivityOperationFailure,
            builder: (context, state) {
              return AppDateSelector(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadActivities();
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Content Area
          Expanded(
            child: BlocConsumer<ActivityBloc, ActivityState>(
              listener: (context, state) {
                if (state is ActivityOperationSuccess) {
                  showModernSnackbar(context, state.message);
                } else if (state is ActivityOperationFailure) {
                  showModernSnackbar(context, state.message, isError: true);
                }
              },
              builder: (context, state) {
                // Determine content to show
                if (state is ActivityLoading) {
                  return const ActivityReportShimmer();
                }

                List<ActivityLog> activities = [];
                if (state is ActivitiesLoaded) {
                  activities = state.activities;
                } else {
                  // Fallback to current state if operation success/failure
                  final currentState = context.read<ActivityBloc>().state;
                  if (currentState is ActivitiesLoaded) {
                    activities = currentState.activities;
                  }
                }

                // If we are strictly loading but not ActivitiesLoaded yet?
                // The check `state is ActivityLoading` above handles the primary loading state.
                // If we are in `ActivityInitial`, we might want to return shimmer too or empty.
                if (state is ActivityInitial) {
                  return const ActivityReportShimmer();
                }

                // Calculate totals
                double totalDuration = 0;
                double totalCalories = 0;
                for (var a in activities) {
                  totalDuration += a.durationMinutes;
                  totalCalories += a.caloriesBurned;
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  children: [
                    BlocBuilder<HealthMetricsBloc, HealthMetricsState>(
                      builder: (context, healthState) {
                        double steps = 0;
                        if (healthState is HealthMetricsLoaded &&
                            healthState.summary != null) {
                          steps = healthState.summary!.steps?.value ?? 0;
                        } else if (healthState is HealthMetricsCachedLoaded) {
                          // Handle cached state if needed, but summary might be null or simplified
                          // Usually aggregated summary is preferred.
                          // Assuming CachedLoaded might retrieve raw list, logic needs summary.
                          // HealthMetricsBloc emits Loaded with summary usually.
                          // Let's rely on Loaded state for summary.
                          if (healthState.metrics.isNotEmpty) {
                            // Fallback if summary missing but unlikely with current bloc logic
                          }
                        }

                        return ActivitySummaryCard(
                          activeTimeMinutes: totalDuration,
                          caloriesBurned: totalCalories,
                          stepCount: steps.toInt(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Workout Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'WORKOUT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B7280),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFEBEB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_run,
                                  color: Color(0xFFE93448),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            activities.length.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              height: 1,
                              color: Color(0xFF131313),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Exercise 20',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(20 - activities.length).clamp(0, 20)} Remaining',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (activities.length / 20).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: const Color(0xFFF3F4F6),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFE93448),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (activities.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No activities logged',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Activity List
                    ...activities.map(
                      (activity) => _buildActivityItem(activity),
                    ),

                    const SizedBox(height: 40),

                    Center(
                      child: GestureDetector(
                        onTap: _showActivityTypeSelector,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.edit,
                                color: Color(0xFFE93448),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Enter manually',
                                style: TextStyle(
                                  color: Color(0xFF131313),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityLog activity) {
    final isSelected = _selectedIds.contains(activity.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(activity.id);
            } else {
              _selectedIds.add(activity.id);
            }
          });
        }
      },
      child: Stack(
        children: [
          Dismissible(
            key: Key(activity.id),
            direction: _isSelectionMode
                ? DismissDirection.none
                : DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              context.read<ActivityBloc>().add(
                DeleteActivityEvent(activity.id, _selectedDate),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Checkbox(
                        value: isSelected,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(activity.id);
                            } else {
                              _selectedIds.remove(activity.id);
                            }
                          });
                        },
                      ),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5), // Light grey
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_run,
                      color: Color(0xFFE93448),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.activityType.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF556073),
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(activity.startTime),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${activity.caloriesBurned.toInt()} Kcal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${activity.durationMinutes}:00',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityTypeSelector() {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const ActivityTypeSelector(),
    ).then((result) async {
      if (result != null && result is Map) {
        final type = result['type'];
        // Navigate to add activity
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<ActivityBloc>(),
              child: AddActivityPage(
                activityType: type,
                initialDate: _selectedDate,
              ),
            ),
          ),
        );
      }
    });
  }
}
