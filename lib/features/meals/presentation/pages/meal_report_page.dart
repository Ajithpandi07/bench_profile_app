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

class MealReportPage extends StatefulWidget {
  const MealReportPage({super.key});

  @override
  State<MealReportPage> createState() => _MealReportPageState();
}

class _MealReportPageState extends State<MealReportPage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _isBlurActive = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  List<MealLog>? _lastLoadedMeals;

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
                                        context.read<MealBloc>().add(
                                          DeleteMultipleMeals(
                                            idsToDelete,
                                            _selectedDate,
                                          ),
                                        );
                                        setState(() {
                                          _isSelectionMode = false;
                                          _selectedIds.clear();
                                          _lastLoadedMeals =
                                              null; // Force shimmer
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
          body: RefreshIndicator(
            onRefresh: () async {
              _loadLogs();
            },
            child: BlocListener<MealBloc, MealState>(
              listener: (context, state) {
                if (state is MealConsumptionLogged) {
                  showModernSnackbar(context, 'Meal logged successfully!');
                } else if (state is MealDeletedSuccess) {
                  // Final success message
                  showModernSnackbar(context, 'Meal deleted successfully');
                } else if (state is MealOperationFailure) {
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
                  // Content
                  Expanded(
                    child: BlocBuilder<MealBloc, MealState>(
                      builder: (context, state) {
                        List<MealLog>? mealsToShow;

                        if (state is MealsLoaded) {
                          mealsToShow = state.meals;
                          _lastLoadedMeals = state.meals; // Cache meals
                        } else if (_lastLoadedMeals != null) {
                          // Retain previous state while other operations happen (loading, deleting, etc.)
                          mealsToShow = _lastLoadedMeals;
                        }

                        if (state is MealLoading && mealsToShow == null) {
                          return const MealReportShimmer();
                        } else if (mealsToShow != null) {
                          if (mealsToShow.isEmpty) {
                            return _buildEmptyState();
                          } else {
                            return _buildLoggedState(mealsToShow);
                          }
                        } else if (state is MealOperationFailure) {
                          // Allow retry or show empty to prevent stuck state?
                          // For now center text is fine.
                          return const Center(
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

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 32),
        const MealSummaryCard(currentKcal: 0, targetKcal: 450),
        const Spacer(flex: 2),
        Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: GestureDetector(
            onTap: _showMealTypeSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Enter food manually',
                    style: TextStyle(
                      color: AppTheme.textDark,
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

  Widget _buildLoggedState(List<MealLog> meals) {
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
    const double maxGoal = 2000;
    const double targetKcal = 2000; // Updated to match global goal

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
                  SlidableAction(
                    onPressed: (ctx) async {
                      debugPrint('DEBUG: Slidable Delete Pressed for $type');
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Swiped & Clicked Delete for $type'),
                        ),
                      );

                      final bloc = ctx.read<MealBloc>();
                      final ids = typeMeals.map((m) => m.id).toList();
                      final date = _selectedDate;

                      debugPrint('DEBUG: IDs to delete: $ids');

                      final confirm = await showDeleteConfirmationDialog(ctx);
                      debugPrint('DEBUG: Confirmation result: $confirm');

                      if (confirm == true) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Confirmed! Sending to DB...'),
                          ),
                        );
                        debugPrint(
                          'DEBUG: Adding DeleteMultipleMeals event to Bloc',
                        );
                        bloc.add(DeleteMultipleMeals(ids, date));
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Deletion Cancelled')),
                        );
                        debugPrint('DEBUG: Deletion cancelled');
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
                      // Check if all are currently selected
                      final allSelected = typeMeals.every(
                        (m) => _selectedIds.contains(m.id),
                      );
                      if (allSelected) {
                        for (var m in typeMeals) {
                          _selectedIds.remove(m.id);
                        }
                      } else {
                        for (var m in typeMeals) {
                          _selectedIds.add(m.id);
                        }
                      }
                    });
                  } else {
                    final allFoods = <FoodItem>[];
                    final allUserMeals = <UserMeal>[];
                    for (var m in typeMeals) {
                      allFoods.addAll(m.items);
                      allUserMeals.addAll(m.userMeals);
                    }
                    _navigateToReview(type, typeMeals);
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
                                  if (typeMeals.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 4.0,
                                        left: 32.0,
                                      ),
                                      child: Text(
                                        DateFormat(
                                          'hh:mm a',
                                        ).format(typeMeals.first.timestamp),
                                        style: const TextStyle(
                                          color: Color(0xFF909DAD),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
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
                          child: const Text(
                            'Needs Attention',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
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
                                text: '${globalTotalKcal.toInt()}',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF131313),
                                ),
                              ),
                              TextSpan(
                                text: ' / ${maxGoal.toInt()}',
                                style: const TextStyle(
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
                          'Your food quality was low.',
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
        Center(
          child: GestureDetector(
            onTap: _showMealTypeSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Enter food manually',
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
  }

  void _showMealTypeSelector() {
    setState(() {
      _isBlurActive = true;
    });

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
                ),
              ),
            ),
          );
          // Removed manual _loadLogs() to rely on Bloc's internal reload after saving
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
          // Removed manual _loadLogs()
        }
      }
    });
  }

  void _navigateToReview(String type, List<MealLog> typeMeals) {
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
            logDate: _selectedDate,
            existingLogIds: typeMeals.map((e) => e.id).toList(),
          ),
        ),
      ),
    );
  }
}
