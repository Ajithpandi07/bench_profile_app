import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';

import '../../domain/entities/entities.dart';
import '../../domain/entities/meal_log.dart';
import '../bloc/bloc.dart';
import '../widgets/meal_type_selector.dart';
import '../widgets/meal_report_shimmer.dart';
import 'meal_listing_page.dart';
import 'quick_log_page.dart';
import 'meal_dashboard_page.dart';
import 'review_meal_page.dart';
import '../widgets/meal_summary_card.dart';
import '../../../../core/presentation/widgets/swipe_confirmation_dialog.dart';
import 'meal_details_page.dart';

class MealReportPage extends StatefulWidget {
  static const String routeName = '/meal-report';
  const MealReportPage({super.key});

  @override
  State<MealReportPage> createState() => _MealReportPageState();
}

class _MealReportPageState extends State<MealReportPage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _isBlurActive = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    context.read<MealBloc>().add(LoadMealsForDate(_selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              _isSelectionMode
                  ? '${_selectedIds.length} selected'
                  : 'Meal Report',
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
            actions: _isSelectionMode
                ? [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.black,
                      ),
                      onPressed: _selectedIds.isEmpty
                          ? null
                          : () {
                              final bloc = context.read<MealBloc>();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete selected meals?'),
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
                                        final idsToDelete = _selectedIds
                                            .toList();
                                        Navigator.pop(context);
                                        bloc.add(
                                          DeleteMultipleMeals(
                                            idsToDelete,
                                            _selectedDate,
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
                        Icons.bar_chart_rounded,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MealDashboardPage(),
                          ),
                        );
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black),
                      onSelected: (value) {
                        if (value == 'add') {
                          _showMealTypeSelector();
                        } else if (value == 'delete') {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedIds.clear();
                          });
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final isFuture = _selectedDate.isAfter(today);
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
                    const SizedBox(width: 8),
                  ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              _loadLogs();
            },
            child: BlocListener<MealBloc, MealState>(
              listener: (context, state) {
                if (state is MealOperationFailure) {
                  showModernSnackbar(context, state.message, isError: true);
                } else if (state is MealConsumptionLogged) {
                  if (state.wasTargetReached) {
                    showModernSnackbar(context, 'Goal Reached! 🎉');
                  } else {
                    showModernSnackbar(
                      context,
                      state.message ?? 'Meal logged successfully!',
                    );
                  }
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
                  // Content
                  Expanded(
                    child: BlocBuilder<MealBloc, MealState>(
                      builder: (context, state) {
                        if (state is MealLoading ||
                            state is MealDeletedSuccess) {
                          return const MealReportShimmer();
                        } else if (state is MealsLoaded) {
                          final meals = state.meals;
                          final targetCalories = state.targetCalories ?? 2000.0;

                          if (meals.isEmpty) {
                            return _buildEmptyState(targetKcal: targetCalories);
                          } else {
                            return _buildLoggedState(
                              meals,
                              targetKcal: targetCalories,
                            );
                          }
                        } else if (state is MealOperationFailure) {
                          return Center(
                            child: Text(
                              'Failed to load logs',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // floatingActionButton removed
        ),
        if (_isBlurActive)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState({double targetKcal = 2000.0}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = _selectedDate.isAfter(today);

    return Column(
      children: [
        const SizedBox(height: 32),
        MealSummaryCard(currentKcal: 0, targetKcal: targetKcal),
        const Spacer(flex: 2),
        Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: GestureDetector(
            onTap: _showMealTypeSelector,
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
                    'Enter food manually',
                    style: TextStyle(
                      color: isFuture ? Colors.grey : AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedState(List<MealLog> meals, {double targetKcal = 2000.0}) {
    final types = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    // Calculate global properties for Insight Card
    double globalTotalKcal = 0;
    DateTime? lastMealTime;
    for (var m in meals) {
      globalTotalKcal += m.totalCalories;
      if (lastMealTime == null || m.timestamp.isAfter(lastMealTime)) {
        lastMealTime = m.timestamp;
      }
    }

    String? lastAddedTime;
    if (lastMealTime != null) {
      lastAddedTime = DateFormat('hh:mm a').format(lastMealTime);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        MealSummaryCard(
          currentKcal: globalTotalKcal,
          targetKcal: targetKcal,
          lastAddedTime: lastAddedTime,
        ),
        const SizedBox(height: 24),
        ...types.map((type) {
          final typeMeals = meals.where((m) {
            if (type == 'Snack') {
              return m.mealType.contains('Snack');
            }
            return m.mealType == type;
          }).toList();
          double totalCals = 0;
          for (var m in typeMeals) {
            totalCals += m.totalCalories;
          }

          if (typeMeals.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Slidable(
              key: ValueKey('${type}_${_selectedDate.millisecondsSinceEpoch}'),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.5,
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      _navigateToReview(type, typeMeals);
                    },
                    backgroundColor: AppTheme.lightGray,
                    foregroundColor: AppTheme.primaryColor,
                    icon: Icons.edit,
                    label: 'Edit',
                  ),
                  Builder(
                    builder: (ctx) {
                      return SlidableAction(
                        onPressed: (ctx) async {
                          final bloc = context
                              .read<
                                MealBloc
                              >(); // Use parent context for safety
                          final ids = typeMeals.map((m) => m.id).toList();
                          final date = _selectedDate;

                          final confirm = await showDeleteConfirmationDialog(
                            context,
                          );
                          if (confirm == true) {
                            bloc.add(DeleteMultipleMeals(ids, date));
                          }
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(16),
                        ),
                      );
                    },
                  ),
                ],
              ),
              child: GestureDetector(
                onLongPress: () {
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                      for (var m in typeMeals) {
                        _selectedIds.add(m.id);
                      }
                    });
                  }
                },
                onTap: () {
                  if (_isSelectionMode) {
                    setState(() {
                      // Check if all are currently selected
                      final allSelected = typeMeals.every(
                        (m) => _selectedIds.contains(m.id),
                      );
                      if (allSelected) {
                        for (var m in typeMeals) {
                          _selectedIds.remove(m.id);
                        }
                        if (_selectedIds.isEmpty) _isSelectionMode = false;
                      } else {
                        for (var m in typeMeals) {
                          _selectedIds.add(m.id);
                        }
                      }
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context
                              .read<MealBloc>(), // Pass the existing bloc
                          child: MealDetailsPage(
                            mealType: type,
                            totalCalories: totalCals,
                            mealLogs: typeMeals,
                            onEdit: (log) {
                              _navigateToReview(type, [
                                log,
                              ], timestamp: log.timestamp);
                            },
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    if (_isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Checkbox(
                          value: typeMeals.every(
                            (m) => _selectedIds.contains(m.id),
                          ),
                          activeColor: AppTheme.primaryColor,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                for (var m in typeMeals) {
                                  _selectedIds.add(m.id);
                                }
                              } else {
                                for (var m in typeMeals) {
                                  _selectedIds.remove(m.id);
                                }
                              }
                            });
                          },
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 81),
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
                              // Icon + Type
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFEBEB),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.restaurant,
                                          color: AppTheme.primaryColor,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 120,
                                        ),
                                        child: Text(
                                          type.toUpperCase(),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF556073),
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Removed time display
                                ],
                              ),
                              const Spacer(),
                              // Calories
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${totalCals.toStringAsFixed(0)} ',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF131313),
                                        ),
                                      ),
                                      const Text(
                                        'Kcal',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF909DAD),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Time
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 16),
        // Insight Card
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top: Image with Pill
                  Stack(
                    children: [
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/indian_food_platter.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Pill at top right
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getInsightTitle(globalTotalKcal, targetKcal),
                            style: TextStyle(
                              color: _getInsightColor(
                                globalTotalKcal,
                                targetKcal,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom: Stats
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${((globalTotalKcal / targetKcal) * 100).clamp(0.0, 100.0).toInt()}',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF131313),
                                ),
                              ),
                              const TextSpan(
                                text: ' / 100',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getInsightMessage(globalTotalKcal, targetKcal),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 40),
        const SizedBox(height: 40),
        Center(
          child: GestureDetector(
            onTap: _showMealTypeSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color:
                    _selectedDate.isAfter(
                      DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ),
                    )
                    ? Colors.grey.shade100
                    : Colors.white,
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
                children: [
                  Icon(
                    Icons.edit,
                    color:
                        _selectedDate.isAfter(
                          DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                          ),
                        )
                        ? Colors.grey
                        : AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Enter food manually',
                    style: TextStyle(
                      color:
                          _selectedDate.isAfter(
                            DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                            ),
                          )
                          ? Colors.grey
                          : const Color(0xFF131313),
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
  }

  void _showMealTypeSelector() {
    setState(() {
      _isBlurActive = true;
    });

    // Check for future date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // _selectedDate is already dateOnly from the date selector
    if (_selectedDate.isAfter(today)) {
      setState(() {
        _isBlurActive = false;
      });
      showModernSnackbar(
        context,
        'You cannot log meals for a future date.',
        isError: true,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent, // Transparent to show blur
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const MealTypeSelector(),
    ).then((result) async {
      setState(() {
        _isBlurActive = false;
      });

      if (result != null && result is Map) {
        final type = result['type'] as String?;
        if (type == 'ManualCalories') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<MealBloc>(),
                child: QuickLogPage(
                  mealType: 'Morning Snack',
                  initialDate: _selectedDate,
                  currentDailyTotal: _calculateCurrentTotal(),
                  dailyTarget: _calculateDailyTarget(),
                ),
              ),
            ),
          );
          _loadLogs(); // Reload logs to restore state
        } else if (type != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<MealBloc>(),
                child: MealListingPage(
                  mealType: type,
                  initialDate: _selectedDate,
                ),
              ),
            ),
          );
          _loadLogs(); // Reload logs to restore state
        }
      }
    });
  }

  void _navigateToReview(
    String type,
    List<MealLog> typeMeals, {
    DateTime? timestamp,
  }) {
    final allFoods = <FoodItem>[];
    final allUserMeals = <UserMeal>[];
    for (var m in typeMeals) {
      allFoods.addAll(m.items);
      allUserMeals.addAll(m.userMeals);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<MealBloc>(),
          child: ReviewMealPage(
            mealType: type,
            selectedFoods: allFoods,
            selectedMeals: allUserMeals,
            allFoods: const [],
            // Use provided timestamp if editing specific log, otherwise fallback to _selectedDate
            logDate: timestamp ?? _selectedDate,
            existingLogIds: typeMeals.map((e) => e.id).toList(),
            initialCalories: typeMeals.fold<double>(
              0,
              (sum, m) => sum + m.totalCalories,
            ),
          ),
        ),
      ),
    );
  }

  double _calculateCurrentTotal() {
    final state = context.read<MealBloc>().state;
    if (state is MealsLoaded) {
      return state.meals.fold(0.0, (sum, m) => sum + m.totalCalories);
    }
    return 0.0;
  }

  double _calculateDailyTarget() {
    final state = context.read<MealBloc>().state;
    if (state is MealsLoaded) {
      return state.targetCalories ?? 2000.0;
    }
    return 2000.0;
  }

  String _getInsightTitle(double current, double target) {
    if (current >= target) return 'Goal Met!';
    final percentage = (current / target) * 100;
    if (percentage < 50) return 'Needs Attention';
    if (percentage < 90) return 'Good';
    return 'Perfect';
  }

  String _getInsightMessage(double current, double target) {
    if (current >= target) return 'You hit your daily target!';
    final percentage = (current / target) * 100;
    if (percentage < 50) return 'Your food intake is low.';
    if (percentage < 90) return 'You are doing well.';
    return 'You are almost there.';
  }

  Color _getInsightColor(double current, double target) {
    if (current >= target) return const Color(0xFF00C853); // Green
    final percentage = (current / target) * 100;
    if (percentage < 50) return AppTheme.primaryColor; // Redish
    if (percentage < 90) return Colors.orange;
    return Colors.green;
  }
}
