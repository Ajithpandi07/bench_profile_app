import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../widgets/primary_button.dart'; // Ensure this exists or use standard button

class ReviewMealPage extends StatefulWidget {
  final String mealType;
  final List<FoodItem> selectedFoods;
  final List<UserMeal> selectedMeals;
  final List<FoodItem> allFoods;

  const ReviewMealPage({
    super.key,
    required this.mealType,
    required this.selectedFoods,
    required this.selectedMeals,
    required this.allFoods,
  });

  @override
  State<ReviewMealPage> createState() => _ReviewMealPageState();
}

class _ReviewMealPageState extends State<ReviewMealPage> {
  late List<FoodItem> _selectedFoods;
  late List<UserMeal> _selectedMeals;
  @override
  void initState() {
    super.initState();
    _selectedFoods = List.from(widget.selectedFoods);
    _selectedMeals = List.from(widget.selectedMeals);
  }

  void _removeFood(FoodItem food) {
    setState(() {
      _selectedFoods.remove(food);
    });
  }

  void _removeMeal(UserMeal meal) {
    setState(() {
      _selectedMeals.remove(meal);
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalCalories = 0;
    for (var f in _selectedFoods) totalCalories += f.calories;
    for (var m in _selectedMeals) totalCalories += m.totalCalories;

    return BlocListener<MealBloc, MealState>(
      listener: (context, state) {
        if (state is MealSaveSuccess) {
          showModernSnackbar(context, '${widget.mealType} logged successfully');
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (state is MealOperationFailure) {
          showModernSnackbar(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: const BackButton(color: Colors.black),
          title: const Text(
            'Review Meal',
            style: TextStyle(
              color: Color(0xFFE93448),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (_selectedMeals.isNotEmpty) ...[
                      const Text(
                        'Selected Meals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._selectedMeals.map(
                        (m) =>
                            _buildMealTile(m, onRemove: () => _removeMeal(m)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_selectedFoods.isNotEmpty) ...[
                      const Text(
                        'Selected Foods',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._selectedFoods.map(
                        (f) => _buildItemTile(
                          f.name,
                          f.calories,
                          onRemove: () => _removeFood(f),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Calories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${totalCalories.toStringAsFixed(0)} Kcal',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE93448),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Save Log',
                      onPressed: () {
                        if (_selectedFoods.isEmpty && _selectedMeals.isEmpty) {
                          showModernSnackbar(
                            context,
                            'No items to save. Please select a meal or food.',
                            isError: true,
                          );
                          return;
                        }
                        // Construct Log
                        final log = MealLog(
                          id: const Uuid().v4(),
                          userId: '', // Bloc/Repo handles current user
                          timestamp: DateTime.now(),
                          mealType: widget.mealType,
                          items: _selectedFoods,
                          userMealIds: _selectedMeals.map((m) => m.id).toList(),
                          totalCalories: totalCalories,
                          createdAt: DateTime.now(),
                        );
                        context.read<MealBloc>().add(LogMealEvent(log));
                      },
                      width: double.infinity,
                      height: 50,
                      borderRadius: 12,
                      fontSize: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealTile(UserMeal meal, {required VoidCallback onRemove}) {
    List<Widget> foodItems = [];
    for (var food in meal.foods) {
      foodItems.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 6, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                food.name,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${(food.calories * food.quantity).toStringAsFixed(0)} Kcal',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  meal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${meal.totalCalories.toStringAsFixed(0)} Kcal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE93448),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (foodItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            ...foodItems,
          ],
        ],
      ),
    );
  }

  Widget _buildItemTile(
    String name,
    double cal, {
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            children: [
              Text(
                '${cal.toStringAsFixed(0)} Kcal',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
