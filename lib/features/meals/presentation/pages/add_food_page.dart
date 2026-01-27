import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import '../bloc/meal_event.dart';
import 'macro_input_row.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  // Input Controllers
  final _nameController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '1 serving');
  final _quantityController = TextEditingController(text: '1');

  // Macros
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _saturatedFatController = TextEditingController();
  final _transFatController = TextEditingController();
  final _cholesterolController = TextEditingController();

  // Micro-nutrients
  final _sodiumController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _dietaryFibreController = TextEditingController();
  final _sugarsController = TextEditingController();
  final _vitaminAController = TextEditingController();
  final _vitaminCController = TextEditingController();
  final _calciumController = TextEditingController();
  final _ironController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carbsController.addListener(_calculateCalories);
    _proteinController.addListener(_calculateCalories);
    _fatController.addListener(_calculateCalories);
  }

  void _calculateCalories() {
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;
    final protein = double.tryParse(_proteinController.text.trim()) ?? 0.0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0.0;

    final calories = (carbs * 4) + (protein * 4) + (fat * 9);

    // Only update if the value is different to avoid cursor jumping or loops
    // (Though simple replacement usually works fine for this one-way dependency)
    final currentCal = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
    if ((calories - currentCal).abs() > 0.1) {
      _caloriesController.text = calories.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _carbsController.removeListener(_calculateCalories);
    _proteinController.removeListener(_calculateCalories);
    _fatController.removeListener(_calculateCalories);

    _nameController.dispose();
    _servingSizeController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _saturatedFatController.dispose();
    _transFatController.dispose();
    _cholesterolController.dispose();
    _sodiumController.dispose();
    _potassiumController.dispose();
    _dietaryFibreController.dispose();
    _sugarsController.dispose();
    _vitaminAController.dispose();
    _vitaminCController.dispose();
    _calciumController.dispose();
    _ironController.dispose();
    super.dispose();
  }

  void _saveFood() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a food name')));
      return;
    }

    double parse(TextEditingController c) =>
        double.tryParse(c.text.trim()) ?? 0.0;
    // int parseInt(TextEditingController c) => int.tryParse(c.text.trim()) ?? 1; // Removed as no longer needed

    final foodItem = FoodItem(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      calories: parse(_caloriesController),
      carbs: parse(_carbsController),
      protein: parse(_proteinController),
      fat: parse(_fatController),
      servingSize: _servingSizeController.text.trim(),
      quantity: parse(_quantityController) == 0.0
          ? 1.0
          : parse(_quantityController), // Use double parse, default to 1.0
      // Micros
      sodium: parse(_sodiumController),
      potassium: parse(_potassiumController),
      dietaryFibre: parse(_dietaryFibreController),
      sugars: parse(_sugarsController),
      vitaminA: parse(_vitaminAController),
      vitaminC: parse(_vitaminCController),
      calcium: parse(_calciumController),
      iron: parse(_ironController),
    );

    // Dispatch to Bloc to save to User Library
    context.read<MealBloc>().add(AddUserFood(foodItem));

    // Return the created FoodItem (optional, but good for immediate use if needed)
    Navigator.pop(context, foodItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match design white bg
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Add New Food',
          style: TextStyle(
            color: Color(0xFFE93448),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFFE93448)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Food name',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'eg. Rice',
                    hasBorder: true,
                  ),

                  const SizedBox(height: 24),

                  MacroInputRow(
                    label: 'Calories per serving',
                    unit: 'kcal',
                    controller: _caloriesController,
                  ),
                  const SizedBox(height: 16),

                  MacroInputRow(
                    label: 'Total carbohydrate',
                    unit: 'g',
                    controller: _carbsController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Total fat',
                    unit: 'g',
                    controller: _fatController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Protein',
                    unit: 'g',
                    controller: _proteinController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Saturated Fat',
                    unit: 'g',
                    controller: _saturatedFatController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Trans Fat',
                    unit: 'mg',
                    controller: _transFatController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Cholesterol',
                    unit: 'mg',
                    controller: _cholesterolController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Sodium',
                    unit: 'mg',
                    controller: _sodiumController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Potassium',
                    unit: 'g',
                    controller: _potassiumController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Dietary Fibre',
                    unit: 'g',
                    controller: _dietaryFibreController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Sugars',
                    unit: 'g',
                    controller: _sugarsController,
                  ),
                  const SizedBox(height: 16),

                  // Vitamins / % DV
                  MacroInputRow(
                    label: 'Vitamin A (100% = 5000 IU)*',
                    unit: '%',
                    controller: _vitaminAController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Vitamin C (100% = 60 mg)*',
                    unit: '%',
                    controller: _vitaminCController,
                  ),
                  const SizedBox(height: 16),
                  MacroInputRow(
                    label: 'Calcium (100% = 1,000 mg)*',
                    unit: '%',
                    controller: _calciumController,
                  ),
                  const SizedBox(height: 16),
                  // Highlight Iron with blue border as per spec/image example?
                  Container(
                    // decoration: BoxDecoration(
                    //   border: Border.all(color: Colors.blueAccent, width: 2),
                    //   borderRadius: BorderRadius.circular(4),
                    // ),
                    child: MacroInputRow(
                      label: 'Iron (100% = 18 mg)*',
                      unit: '%',
                      controller: _ironController,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    '*Percent Daily Values are based on a 2000 kcal diet. Your daily values may be higher or lower depending on your calorie needs.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 100), // Space for buttons
                ],
              ),
            ),
          ),

          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveFood,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE93448),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool hasBorder,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: hasBorder
            ? Border.all(color: Colors.grey.shade300)
            : Border.all(color: Colors.transparent),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
