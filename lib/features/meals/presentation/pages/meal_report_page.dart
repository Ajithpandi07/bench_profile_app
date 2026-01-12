import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/app_date_selector.dart';
import '../../../../core/services/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';

import '../../domain/entities/entities.dart';
import '../../domain/entities/meal_log.dart';
import '../bloc/bloc.dart';
import '../widgets/meal_type_selector.dart';
import '../widgets/meal_report_shimmer.dart';
import 'meal_listing_page.dart';
import 'quick_log_page.dart';
import 'meal_dashboard_page.dart';
import 'review_meal_page.dart';

class MealReportPage extends StatefulWidget {
  const MealReportPage({super.key});

  @override
  State<MealReportPage> createState() => _MealReportPageState();
}

class _MealReportPageState extends State<MealReportPage> {
  DateTime _selectedDate = DateTime.now();

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Meal Report',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MealDashboardPage()),
              );
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
                    if (state is MealLoading) {
                      return const MealReportShimmer();
                    } else if (state is MealsLoaded) {
                      if (state.meals.isEmpty) {
                        return _buildEmptyState();
                      } else {
                        return _buildLoggedState(state.meals);
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
      floatingActionButton: BlocBuilder<MealBloc, MealState>(
        builder: (context, state) {
          if (state is MealsLoaded && state.meals.isNotEmpty) {
            return FloatingActionButton(
              onPressed: _showMealTypeSelector,
              backgroundColor: const Color(0xFFE93448),
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const Spacer(flex: 1),
        const Text('Food', style: TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 8),
        const Text(
          '0 Kcal',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFF131313),
          ),
        ),
        const SizedBox(height: 32),
        // Target Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE93448),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Target Calories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF131313),
                    ),
                  ),
                ],
              ),
              const Text(
                '450 kcal', // Placeholder target, could be dynamic
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
                  Icon(Icons.edit, color: Color(0xFFE93448), size: 20),
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
      ],
    );
  }

  Widget _buildLoggedState(List<MealLog> meals) {
    final types = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    // Calculate global properties for Insight Card
    double globalTotalKcal = 0;
    for (var m in meals) {
      globalTotalKcal += m.totalCalories;
    }
    const double maxGoal = 2000;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        ...types.map((type) {
          final typeMeals = meals.where((m) => m.mealType == type).toList();
          double totalCals = 0;
          for (var m in typeMeals) {
            totalCals += m.totalCalories;
          }

          if (typeMeals.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GestureDetector(
              onTap: () {
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
              },
              child: Container(
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Content Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Icon + Name
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Color(0xFFE93448),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF556073),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Calories
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${totalCals.toStringAsFixed(0)} ',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF131313),
                                ),
                              ),
                              const Text(
                                'Kcal',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF909DAD),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Time
                          if (typeMeals.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                DateFormat(
                                  'hh:mm a',
                                ).format(typeMeals.first.timestamp),
                                style: const TextStyle(
                                  color: Color(0xFF556073),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Action Arrow (Right Side)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF131313),
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
        // Insight Card (Needs Attention)
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
                              color: Color(0xFFE93448),
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
      ],
    );
  }

  void _showMealTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const MealTypeSelector(),
    ).then((result) async {
      if (result != null && result is Map) {
        final type = result['type'] as String?;
        if (type == 'ManualCalories') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<MealBloc>(),
                child: QuickLogPage(
                  mealType: 'Snack',
                  initialDate: _selectedDate,
                ),
              ),
            ),
          );
          _loadLogs();
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
          _loadLogs();
        }
      }
    });
  }
}
