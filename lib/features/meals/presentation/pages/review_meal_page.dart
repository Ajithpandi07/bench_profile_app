import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import '../../../../core/utils/snackbar_utils.dart';

class ReviewMealPage extends StatefulWidget {
  final String mealType;
  final List<FoodItem> selectedFoods;
  final List<UserMeal> selectedMeals;
  final List<FoodItem> allFoods;
  final DateTime? logDate;
  final List<String> existingLogIds; // To handle edits

  const ReviewMealPage({
    super.key,
    required this.mealType,
    required this.selectedFoods,
    required this.selectedMeals,
    required this.allFoods,
    this.logDate,
    this.existingLogIds = const [],
  });

  @override
  State<ReviewMealPage> createState() => _ReviewMealPageState();
}

class _ReviewMealPageState extends State<ReviewMealPage> {
  late String _selectedMealType;
  late double _calories;
  late List<FoodItem> _currentFoods;
  late List<UserMeal> _currentMeals;

  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Morning Snack',
    'Afternoon Snack',
    'Evening Snack',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.mealType;
    _currentFoods = List.from(widget.selectedFoods);
    _currentMeals = List.from(widget.selectedMeals);
    _calculateTotalCalories();
  }

  void _calculateTotalCalories() {
    double total = 0;
    for (var f in _currentFoods) {
      total += f.calories * f.quantity;
    }
    for (var m in _currentMeals) {
      total += m.totalCalories * m.quantity;
    }
    setState(() {
      _calories = total;
    });
  }

  void _removeFood(FoodItem food) {
    setState(() {
      _currentFoods.remove(food);
      _calculateTotalCalories();
    });
  }

  void _updateFoodQuantity(int index, int delta) {
    setState(() {
      final item = _currentFoods[index];
      final newQuantity = item.quantity + delta;
      if (newQuantity > 0) {
        _currentFoods[index] = item.copyWith(quantity: newQuantity);
        _calculateTotalCalories();
      }
    });
  }

  void _removeMeal(UserMeal meal) {
    setState(() {
      _currentMeals.remove(meal);
      _calculateTotalCalories();
    });
  }

  void _updateFoodInMeal(int mealIndex, int foodIndex, int delta) {
    setState(() {
      final meal = _currentMeals[mealIndex];
      // Create a modifiable copy of the foods list
      final updatedFoods = List<FoodItem>.from(meal.foods);
      final food = updatedFoods[foodIndex];
      final newQuantity = food.quantity + delta;

      if (newQuantity > 0) {
        updatedFoods[foodIndex] = food.copyWith(quantity: newQuantity);
      } else {
        // Allow removing food from the meal set
        updatedFoods.removeAt(foodIndex);
      }

      // Recalculate meal total
      double newTotal = 0;
      for (var f in updatedFoods) {
        newTotal += f.calories * f.quantity;
      }

      _currentMeals[mealIndex] = meal.copyWith(
        foods: updatedFoods,
        totalCalories: newTotal,
      );
      _calculateTotalCalories();
    });
  }

  Widget _buildStepperIcon(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(icon, size: 16, color: Colors.grey),
    );
  }

  void _logMeal() {
    if (_currentFoods.isEmpty && _currentMeals.isEmpty) {
      showModernSnackbar(
        context,
        'No items to save. Please select a meal or food.',
        isError: true,
      );
      return;
    }

    // Capture the final list of foods with updated quantities
    final log = MealLog(
      id: const Uuid().v4(),
      userId: '', // Bloc/Repo handles current user
      timestamp: widget.logDate ?? DateTime.now(),
      mealType: _selectedMealType,
      items: _currentFoods,
      userMeals: _currentMeals,
      totalCalories: _calories, // User can override with slider
      createdAt: DateTime.now(),
    );

    if (widget.existingLogIds.isNotEmpty) {
      context.read<MealBloc>().add(
        ReplaceMealLogEvent(
          newLog: log,
          oldLogIds: widget.existingLogIds,
          oldDate: widget.logDate ?? DateTime.now(),
        ),
      );
    } else {
      context.read<MealBloc>().add(LogMealEvent(log));
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat(
      'h:mm a',
    ).format(widget.logDate ?? DateTime.now());

    return BlocListener<MealBloc, MealState>(
      listener: (context, state) {
        if (state is MealConsumptionLogged) {
          showModernSnackbar(context, '${widget.mealType} logged successfully');
          // Return to MealListingPage, not Dashboard
          // Assuming navigation stack: Dashboard -> MealListing -> ReviewMeal
          // Pop once (ReviewMeal) -> MealListing
          // Or pop twice if we want dashboard? User asked for "return meal listing page only".
          // So pop() goes back to MealListingPage.
          // Return to MealReportPage (pop ListingPage too)
          Navigator.of(context)
            ..pop()
            ..pop();
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Meal Type Dropdown
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE93448),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE93448).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _mealTypes.contains(_selectedMealType)
                        ? _selectedMealType
                        : null,
                    hint: Text(
                      _selectedMealType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    dropdownColor: const Color(0xFFE93448),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 18,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedMealType = newValue;
                        });
                      }
                    },
                    items: _mealTypes.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Time Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeString,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Calorie Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Total calories: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_calories.toInt()} kcal',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Macro Summary
                    Builder(
                      builder: (context) {
                        double carbs = 0, fat = 0, protein = 0;
                        for (var f in _currentFoods) {
                          carbs += f.carbs * f.quantity;
                          fat += f.fat * f.quantity;
                          protein += f.protein * f.quantity;
                        }

                        return Text(
                          'Carb ${carbs.toStringAsFixed(0)} g  •  Fat ${fat.toStringAsFixed(0)} g  •  Protein ${protein.toStringAsFixed(0)} g',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Slider
                    Builder(
                      builder: (context) {
                        double minCalories = 0;
                        for (var f in _currentFoods) {
                          minCalories += f.calories * f.quantity;
                        }
                        for (var m in _currentMeals) {
                          minCalories += m.totalCalories;
                        }

                        // Ensure UI obeys minimum visually
                        double displayValue = _calories;
                        if (displayValue < minCalories) {
                          displayValue = minCalories;
                        }

                        double maxCalories =
                            (minCalories > 2000 || displayValue > 2000)
                            ? (displayValue > minCalories
                                  ? displayValue + 500
                                  : minCalories + 1000)
                            : 2000;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: const Color(0xFFE93448),
                                      inactiveTrackColor: Colors.grey.shade200,
                                      thumbColor: Colors.white,
                                      trackHeight: 6,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 10,
                                        elevation: 2,
                                      ),
                                    ),
                                    child: Slider(
                                      value: displayValue.clamp(
                                        minCalories,
                                        maxCalories,
                                      ),
                                      min: minCalories,
                                      max: maxCalories,
                                      onChanged: (val) {
                                        setState(() => _calories = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  minCalories.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  ((maxCalories + minCalories) / 2)
                                      .toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  maxCalories.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Items List Container
              if (_currentFoods.isNotEmpty || _currentMeals.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foods Section
                      if (_currentFoods.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Foods',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE93448),
                            ),
                          ),
                        ),
                        ..._currentFoods.asMap().entries.map((entry) {
                          final index = entry.key;
                          final food = entry.value;
                          return Column(
                            children: [
                              _buildFoodItemRow(
                                food.name,
                                '${food.quantity} x ${food.servingSize} • ${(food.calories * food.quantity).toStringAsFixed(0)} kcal',
                                index,
                                food.quantity,
                              ),
                              if (index < _currentFoods.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }),
                      ],

                      // Divider between sections if both exist
                      if (_currentFoods.isNotEmpty && _currentMeals.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, thickness: 1),
                        ),

                      // Meals Section
                      if (_currentMeals.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Meals',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE93448),
                            ),
                          ),
                        ),
                        ..._currentMeals.asMap().entries.map((entry) {
                          final index = entry.key;
                          final meal = entry.value;
                          return Column(
                            children: [
                              _buildMealItemRow(meal, index),
                              if (index < _currentMeals.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Done Button
              Center(
                child: SizedBox(
                  width: 306,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: _logMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE93448),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItemRow(
    String name,
    String subtitle,
    int index,
    int quantity,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          // Stepper for Food
          GestureDetector(
            onTap: () => _updateFoodQuantity(index, -1),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.remove, size: 16, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => _updateFoodQuantity(index, 1),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.add, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _removeFood(_currentFoods[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItemRow(UserMeal meal, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${meal.quantity} x Set • ${meal.totalCalories.toStringAsFixed(0)} kcal (Meal)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (meal.foods.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...meal.foods.asMap().entries.map((entry) {
                    final foodIndex = entry.key;
                    final food = entry.value;
                    final foodCals = food.calories * food.quantity;

                    return Padding(
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        bottom: 8.0,
                        right: 8.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${foodCals.toStringAsFixed(0)} kcal',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Inline Food Stepper
                          GestureDetector(
                            onTap: () =>
                                _updateFoodInMeal(index, foodIndex, -1),
                            child: _buildStepperIcon(Icons.remove),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${food.quantity}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _updateFoodInMeal(index, foodIndex, 1),
                            child: _buildStepperIcon(Icons.add),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(width: 16),

          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _removeMeal(meal),
          ),
        ],
      ),
    );
  }
}
