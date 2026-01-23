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

    // Flatten selected meals into individual food items
    for (var meal in widget.selectedMeals) {
      for (var food in meal.foods) {
        // We need to account for the meal quantity as well
        final totalQuantity = food.quantity * meal.quantity;

        // Check if this food is already in _currentFoods to merge or just add
        // For simplicity and to show distinct items from distinct sources, we just add.
        // Or better, we can check if we want to merge duplicates?
        // Let's just add them as distinct items for now to avoid merging issues with different serving sizes.
        // Ideally, we should clone the food with the new total quantity.
        _currentFoods.add(food.copyWith(quantity: totalQuantity));
      }
    }

    _calculateTotalCalories();
  }

  void _calculateTotalCalories() {
    double total = 0;
    for (var f in _currentFoods) {
      total += f.calories * f.quantity;
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
      } else if (newQuantity == 0) {
        _removeFood(item);
      }
    });
  }

  void _logMeal() {
    if (_currentFoods.isEmpty) {
      showModernSnackbar(
        context,
        'No items to save. Please select a meal or food.',
        isError: true,
      );
      return;
    }

    // Use selected date but current time
    final now = DateTime.now();
    final date = widget.logDate ?? now;
    final timestamp = DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
      now.second,
    );

    // Capture the final list of foods with updated quantities
    final log = MealLog(
      id: const Uuid().v4(),
      userId: '', // Bloc/Repo handles current user
      timestamp: timestamp,
      mealType: _selectedMealType,
      items: _currentFoods,
      userMeals: const [], // We flattened everything into items
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

  void _saveCustomMeal() {
    if (_currentFoods.isEmpty) return;

    final userMeal = UserMeal(
      id: const Uuid().v4(),
      name: 'Custom Meal',
      foods: _currentFoods,
      totalCalories: _currentFoods.fold(
        0,
        (sum, item) => sum + (item.calories * item.quantity),
      ),
      createdAt: DateTime.now(),
      creatorId: '', // Handled by repository/bloc
    );

    context.read<MealBloc>().add(AddUserMeal(userMeal));
    showModernSnackbar(context, 'Custom meal saved!');
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
          // If we were editing, we pop once (Review -> Report)
          // If we were adding new, we pop twice (Review -> Listing -> Report)
          if (widget.existingLogIds.isNotEmpty) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context)
              ..pop()
              ..pop();
          }
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
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: () {},
            ),
          ],
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

              const SizedBox(height: 16),

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

              const SizedBox(height: 24),

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

                        // Ensure UI obeys minimum visually
                        double displayValue = _calories;
                        if (displayValue < minCalories) {
                          displayValue = minCalories;
                        }

                        // We update _calories to match min if it fell below
                        if (_calories < minCalories) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted)
                              setState(() => _calories = minCalories);
                          });
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
              if (_currentFoods.isNotEmpty)
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
                    children: [
                      ..._currentFoods.asMap().entries.map((entry) {
                        final index = entry.key;
                        final food = entry.value;
                        return Column(
                          children: [
                            _buildFoodItemRow(
                              food.name,
                              '${food.calories.toStringAsFixed(0)} kcal, ${food.quantity} serving',
                              index,
                              food.quantity,
                            ),
                            if (index < _currentFoods.length - 1)
                              const Divider(height: 1),
                          ],
                        );
                      }),

                      const SizedBox(height: 16),
                      // Add Food Button (Placeholder for now, just text/icon button as per design?
                      // The user request screenshot shows "+ Add food".
                      // Since we don't have a direct "add food" flow here easily without navigation,
                      // I'll add the button UI but maybe it just pops or shows a message for now?
                      // Or I can possibly try to open the search?
                      // For now, let's make it look right.
                      GestureDetector(
                        onTap: () {
                          // Ideally open search. For now, we go back? Or show snackbar?
                          // Let's pop with a result saying "add_more"?
                          // Or just navigate to MealListingPage?
                          // Current flow: MealListing -> Review.
                          // If we pop, we lose state unless we return data.
                          Navigator.pop(context);
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFFE93448),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Add food',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Save as Custom Meal Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _saveCustomMeal,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.grey,
                    ), // Light grey border
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save as Custom Meal',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _logMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE93448),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
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
          Row(
            children: [
              GestureDetector(
                onTap: () => _updateFoodQuantity(index, -1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, size: 16, color: Colors.grey),
                ),
              ),
              SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    '$quantity',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _updateFoodQuantity(index, 1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
