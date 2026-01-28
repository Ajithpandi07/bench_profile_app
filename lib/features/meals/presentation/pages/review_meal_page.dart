import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'meal_listing_page.dart';
import 'meal_report_page.dart';

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
  late TimeOfDay _selectedTime;
  bool _isCustomMealSaved = false;

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
    _selectedTime = TimeOfDay.now();

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
      _isCustomMealSaved = false;
    });
  }

  void _updateFoodQuantity(int index, double delta) {
    setState(() {
      final item = _currentFoods[index];
      final newQuantity = item.quantity + delta;
      if (newQuantity > 0) {
        _currentFoods[index] = item.copyWith(quantity: newQuantity);
        _calculateTotalCalories();
        _isCustomMealSaved = false;
      } else if (newQuantity == 0) {
        _removeFood(item);
      }
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
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
      _selectedTime.hour,
      _selectedTime.minute,
      now.second,
    );

    // Prevent logging for future dates/times
    if (timestamp.isAfter(now)) {
      showModernSnackbar(
        context,
        'You cannot log meals for a future time.',
        isError: true,
      );
      return;
    }

    // New: Check for low calories relative to food items
    double minCalories = 0;
    for (var f in _currentFoods) {
      minCalories += f.calories * f.quantity;
    }

    // If user entered less than 90% of calculated sum (and difference > 50 cal), warn them.
    // Or just check if significantly lower.
    // User request: "calories less than normal (Meal)"
    // Let's compare _calories vs minCalories.
    if (_calories < minCalories && (minCalories - _calories) > 10) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Low Calorie Alert'),
          content: Text(
            'The total calories (${_calories.toInt()}) is lower than the calculated sum from foods (${minCalories.toInt()}). Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _proceedToLog(timestamp);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      return;
    }

    _proceedToLog(timestamp);
  }

  void _proceedToLog(DateTime timestamp) {
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

    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Save as Custom Meal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter a name for this meal to save it to your library.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Meal Name',
                      border: const OutlineInputBorder(),
                      hintText: 'e.g. My Breakfast',
                      errorText: errorText,
                    ),
                    autofocus: true,
                    onChanged: (val) {
                      if (errorText != null) {
                        setState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setState(() => errorText = 'Please enter a name');
                      return;
                    }

                    // Duplicate Check
                    final state = context.read<MealBloc>().state;
                    if (state is UserLibraryLoaded) {
                      final duplicate = state.meals.any(
                        (m) => m.name.toLowerCase() == name.toLowerCase(),
                      );
                      if (duplicate) {
                        setState(
                          () => errorText =
                              'A meal with this name already exists',
                        );
                        return;
                      }
                    }

                    final userMeal = UserMeal(
                      id: const Uuid().v4(),
                      name: name,
                      foods: _currentFoods,
                      totalCalories: _currentFoods.fold(
                        0,
                        (sum, item) => sum + (item.calories * item.quantity),
                      ),
                      createdAt: DateTime.now(),
                      creatorId: '',
                    );

                    context.read<MealBloc>().add(AddUserMeal(userMeal));
                    setState(() => _isCustomMealSaved = true);
                    Navigator.pop(context); // Close dialog
                    showModernSnackbar(context, 'Custom meal saved!');
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the display time.
    // We combine the date from widget.logDate (or now) with _selectedTime.
    final displayDate = widget.logDate ?? DateTime.now();
    final displayTimeDateTime = DateTime(
      displayDate.year,
      displayDate.month,
      displayDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final timeString = DateFormat('h:mm a').format(displayTimeDateTime);

    return BlocListener<MealBloc, MealState>(
      listener: (context, state) {
        if (state is MealConsumptionLogged) {
          Navigator.of(context).popUntil(
            (route) =>
                route.settings.name == MealReportPage.routeName ||
                route.isFirst,
          );
        } else if (state is MealOperationFailure) {
          showModernSnackbar(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: const BackButton(color: Colors.black),
          title: Text(
            'Review Meal',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
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
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                    dropdownColor: Theme.of(context).primaryColor,
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

              // Time Badge - Now Tappable
              GestureDetector(
                onTap: _pickTime,
                child: Container(
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
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                final controller = TextEditingController();
                                String? errorText;

                                return StatefulBuilder(
                                  builder: (context, setDialogState) {
                                    return AlertDialog(
                                      title: const Text('Enter Calories'),
                                      content: TextField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          hintText: 'e.g. 500',
                                          suffixText: 'kcal',
                                          errorText: errorText,
                                        ),
                                        onChanged: (value) {
                                          if (errorText != null) {
                                            setDialogState(
                                              () => errorText = null,
                                            );
                                          }
                                        },
                                        onSubmitted: (value) {
                                          final val = double.tryParse(value);
                                          if (val != null && val > 0) {
                                            setState(() => _calories = val);
                                            Navigator.pop(context);
                                          } else {
                                            setDialogState(
                                              () => errorText =
                                                  'Please enter a valid value',
                                            );
                                          }
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            final val = double.tryParse(
                                              controller.text,
                                            );
                                            if (val != null && val > 0) {
                                              setState(() => _calories = val);
                                              Navigator.pop(context);
                                            } else {
                                              setDialogState(
                                                () => errorText =
                                                    'Please enter a valid value',
                                              );
                                            }
                                          },
                                          child: const Text('Confirm'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '${_calories.toInt()} kcal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
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

                        // DISABLED ENFORCEMENT for user freedom
                        // We enable full range now.
                        // But we still need a reasonable min for slider (e.g. 0).
                        double displayValue = _calories;

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
                                      activeTrackColor: Theme.of(
                                        context,
                                      ).primaryColor,
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
                                        0.0, // Allow down to 0
                                        maxCalories,
                                      ),
                                      min: 0.0,
                                      max: maxCalories,
                                      onChangeStart: (_) {
                                        // Haptic feedback could be added here
                                      },
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
                                  '0',
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
                      // Add Food Button
                      GestureDetector(
                        onTap: () {
                          // Go to selection page to add more
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<MealBloc>(),
                                child: MealListingPage(
                                  mealType: _selectedMealType,
                                  initialDate: widget.logDate,
                                  initialFoods: _currentFoods,
                                  // We pass empty initialMeals because they are flattened in _currentFoods
                                  initialMeals: const [],
                                  existingLogIds: widget.existingLogIds,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                color: Theme.of(context).primaryColor,
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

              if (_currentFoods.isNotEmpty) ...[
                if (!_isCustomMealSaved) ...[
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
                ],

                // Done Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _logMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
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
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go Back to add Food',
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
    double quantity,
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
                onTap: () => _updateFoodQuantity(index, -0.5),
                child: Container(
                  width: 44, // Increased touch target
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // color: Colors.grey.shade100, // Optional background for bigger target perception
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    '${quantity % 1 == 0 ? quantity.toInt() : quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _updateFoodQuantity(index, 0.5),
                child: Container(
                  width: 44, // Increased touch target
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle),
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
