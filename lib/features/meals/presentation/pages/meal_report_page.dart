import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/app_date_selector.dart';
import '../../../../core/services/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';

import '../../../reminder/presentation/widgets/primary_button.dart';
import '../../../reminder/presentation/widgets/reminder_item_card.dart';
import '../bloc/bloc.dart';
import '../widgets/meal_type_selector.dart';
import '../widgets/meal_report_shimmer.dart';
import 'meal_listing_page.dart';
import 'quick_log_page.dart';

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
      ),
      body: BlocListener<MealBloc, MealState>(
        listener: (context, state) {
          if (state is MealOperationFailure) {
            showModernSnackbar(context, state.message, isError: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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

              // List
              Expanded(
                child: BlocBuilder<MealBloc, MealState>(
                  builder: (context, state) {
                    if (state is MealLoading) {
                      return const MealReportShimmer();
                    } else if (state is MealsLoaded) {
                      if (state.meals.isEmpty) {
                        return const Center(
                          child: Text(
                            'No meals for this day',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      // Sort latest first
                      final meals = List.from(state.meals);
                      meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                      return ListView.builder(
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];
                          // Subtitle: Total Cals and Items count?
                          final subtitle =
                              '${meal.totalCalories.toStringAsFixed(0)} Kcal • ${meal.items.length} Items';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: ReminderItemCard(
                              title: meal.mealType,
                              subtitle: subtitle,
                              scheduleType: 'Meal',
                              time: DateFormat(
                                'hh:mm a',
                              ).format(meal.timestamp),
                              icon: Icons.restaurant,
                              color: Colors.green, // Differentiate from Water
                            ),
                          );
                        },
                      );
                    } else if (state is MealOperationFailure) {
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

              // Add Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: PrimaryButton(
                  text: 'Add Meal',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (ctx) => const MealTypeSelector(),
                    ).then((result) async {
                      if (result != null && result is Map) {
                        final type = result['type'];
                        if (type == 'ManualCalories') {
                          // Navigate to Quick Log
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<MealBloc>(),
                                child: const QuickLogPage(
                                  mealType: 'Snack',
                                ), // Default or specific?
                              ),
                            ),
                          );
                          _loadLogs(); // Reload after return
                        } else {
                          // Navigate to Meal Listing
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<MealBloc>(),
                                child: MealListingPage(mealType: type),
                              ),
                            ),
                          );
                          _loadLogs(); // Reload after return. Note: ReviewMealPage might pop to root though.
                        }
                      }
                    });
                  },
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
