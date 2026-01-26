import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import '../bloc/meal_event.dart';
import 'add_food_page.dart';

class QuickLogPage extends StatefulWidget {
  final String mealType;
  final DateTime? initialDate;

  const QuickLogPage({super.key, required this.mealType, this.initialDate});

  @override
  State<QuickLogPage> createState() => _QuickLogPageState();
}

class _QuickLogPageState extends State<QuickLogPage> {
  late String _selectedMealType;
  late double _calories;

  // List of foods for this scratchpad log
  final List<FoodItem> _addedFoods = [];

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
    _calories = 272; // Default starting value or 0?
    // Design showed 272, let's keep it adjustable.

    // Ensure library is loaded
    context.read<MealBloc>().add(LoadUserLibrary());
  }

  void _addFood() async {
    final mealBloc = context.read<MealBloc>();

    final FoodItem? selectedFood = await showModalBottomSheet<FoodItem>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BlocProvider.value(
          value: mealBloc,
          child: Builder(
            builder: (context) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Select from My Food',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BlocBuilder<MealBloc, MealState>(
                        builder: (context, state) {
                          List<FoodItem> foods = [];
                          // Assuming library is loaded (MealListingPage called LoadUserLibrary)
                          if (state is UserLibraryLoaded) {
                            foods = state.foods;
                          }
                          // If empty/loading, show Add New
                          if (foods.isEmpty) {
                            return Center(
                              child: TextButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  // Navigate to AddFoodPage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: mealBloc,
                                        child: const AddFoodPage(),
                                      ),
                                    ),
                                  ).then((res) {
                                    if (res != null && res is FoodItem) {
                                      if (mounted) {
                                        setState(() {
                                          _addedFoods.add(res);
                                          _calories +=
                                              res.calories * res.quantity;
                                        });
                                      }
                                    }
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Create New Food'),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: foods.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final food = foods[index];
                              return ListTile(
                                title: Text(food.name),
                                subtitle: Text(
                                  '${food.calories.toStringAsFixed(0)} kcal',
                                ),
                                trailing: const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFFE93448),
                                ),
                                onTap: () => Navigator.pop(context, food),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (selectedFood != null) {
      setState(() {
        _addedFoods.add(selectedFood);
        // Let's add food calories to the slider value for convenience.
        _calories += selectedFood.calories * selectedFood.quantity;
      });
    }
  }

  void _updateFoodQuantity(int index, int delta) {
    setState(() {
      final item = _addedFoods[index];
      final newQuantity = item.quantity + delta;
      if (newQuantity > 0) {
        // Adjust slider diff
        final diff = (newQuantity - item.quantity) * item.calories;
        _calories += diff;

        _addedFoods[index] = item.copyWith(quantity: newQuantity);
      }
    });
  }

  void _logMeal() {
    // Check future date
    final date = widget.initialDate ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot log meals for future date or time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Logic: calculate total from foods.
    // For now, let's treat it as: Items are specific, and total calories is the slider value (user can override).

    final log = MealLog(
      id: const Uuid().v4(),
      userId: '',
      timestamp: date,
      mealType: _selectedMealType,
      items: _addedFoods,
      userMeals: const [],
      totalCalories: _calories, // User adjusted total
      createdAt: DateTime.now(),
    );

    context.read<MealBloc>().add(LogMealEvent(log));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    // Current Time formatted
    final timeString = DateFormat('h:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Log Meal',
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
            // Meal Type Dropdown (Custom styled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE93448),
                borderRadius: BorderRadius.circular(20),
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
                  value: _selectedMealType,
                  dropdownColor: const Color(0xFFE93448),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit', // Assuming global font
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    timeString, // Dynamic time
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                  // Showing macro summary of added foods
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      double carbs = 0, fat = 0, protein = 0;
                      for (var f in _addedFoods) {
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
                            value: _calories.clamp(0.0, 3000.0), // Safe clamp
                            min: 0,
                            max: 3000,
                            onChanged: (val) => setState(() => _calories = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        '1500',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        '3000',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Food List Container
            if (_addedFoods.isNotEmpty)
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
                    ..._addedFoods.asMap().entries.map((entry) {
                      final index = entry.key;
                      final food = entry.value;
                      return Column(
                        children: [
                          _buildFoodItemRow(
                            food.name,
                            '${(food.calories * food.quantity).toStringAsFixed(0)} kcal, ${food.servingSize}',
                            index,
                            food.quantity,
                          ),
                          if (index < _addedFoods.length - 1) const Divider(),
                        ],
                      );
                    }),
                  ],
                ),
              ),

            if (_addedFoods.isNotEmpty) const SizedBox(height: 24),

            GestureDetector(
              onTap: _addFood,
              child: Container(
                padding: const EdgeInsets.all(16), // Bigger touch area
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 24),

            // Done Red Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _logMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE93448),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
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
          // Stepper
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
            onPressed: () => _removeFood(index),
          ),
        ],
      ),
    );
  }

  void _removeFood(int index) {
    setState(() {
      final item = _addedFoods[index];
      // Subtract calories
      final diff = item.calories * item.quantity;
      if (_calories >= diff) {
        _calories -= diff;
      }
      _addedFoods.removeAt(index);
    });
  }
}
