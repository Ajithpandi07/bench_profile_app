import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import '../bloc/meal_event.dart'; // Import events

class CreateMealPage extends StatefulWidget {
  const CreateMealPage({super.key});

  @override
  State<CreateMealPage> createState() => _CreateMealPageState();
}

class _CreateMealPageState extends State<CreateMealPage> {
  final _nameController = TextEditingController();
  final List<FoodItem> _addedFoods = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  double get _totalCalories =>
      _addedFoods.fold(0, (sum, item) => sum + item.calories);
  double get _totalCarbs =>
      _addedFoods.fold(0, (sum, item) => sum + item.carbs);
  double get _totalFat => _addedFoods.fold(0, (sum, item) => sum + item.fat);
  double get _totalProtein =>
      _addedFoods.fold(0, (sum, item) => sum + item.protein);

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
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          if (state is UserLibraryLoaded) {
                            foods = state.foods;
                          }

                          if (foods.isEmpty) {
                            return const Center(
                              child: Text('No saved foods found.'),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: foods.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final food = foods[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${food.calories.toStringAsFixed(0)} kcal',
                                  style: const TextStyle(color: Colors.grey),
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
      });
    }
  }

  void _saveMeal() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a meal name')));
      return;
    }

    if (_addedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one food')),
      );
      return;
    }

    final meal = UserMeal(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      foodIds: _addedFoods.map((f) => f.id).toList(),
      totalCalories: _totalCalories,
      creatorId: '', // Set by backend/repo based on auth
    );

    context.read<MealBloc>().add(AddUserMeal(meal));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Add New Meal',
          style: TextStyle(
            color: Color(0xFFE93448),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info, color: Color(0xFFE93448)),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Meal name',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'eg. Rice',
                    hintStyle: TextStyle(color: Colors.grey),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Total calories: ${_totalCalories.toStringAsFixed(0)} Kcal',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Carb ${_totalCarbs.toStringAsFixed(1)}g, Fat ${_totalFat.toStringAsFixed(1)}g, Protein ${_totalProtein.toStringAsFixed(1)}g',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // List of Added Foods
            if (_addedFoods.isNotEmpty) ...[
              Expanded(
                child: ListView.separated(
                  itemCount: _addedFoods.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final food = _addedFoods[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${food.calories.toStringAsFixed(0)} kcal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _addedFoods.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const Spacer(),

            GestureDetector(
              onTap: _addFood,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE93448).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Add Food +',
                    style: TextStyle(
                      color: Color(0xFFE93448),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('Cancel')),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _saveMeal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE93448),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
