import 'package:flutter/material.dart';

class MealTypeSelector extends StatefulWidget {
  const MealTypeSelector({super.key});

  @override
  State<MealTypeSelector> createState() => _MealTypeSelectorState();
}

class _MealTypeSelectorState extends State<MealTypeSelector> {
  String? _selectedMeal;

  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Morning Snack',
    'Afternoon Snack',
    'Evening Snack',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 19,
        vertical: 16,
      ), // Reduced vertical padding
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16), // Reduced from 24
          const Text(
            'Meal type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE93448), // Primary Red
            ),
          ),
          const SizedBox(height: 16), // Reduced from 24
          // List of Radio options (Custom Styled)
          ..._mealTypes.map((type) => _buildOption(type)),

          const SizedBox(height: 8), // Reduced from 16
          // Add Calories Button (Special)
          GestureDetector(
            onTap: () {
              Navigator.pop(context, {'type': 'ManualCalories'});
            },
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Color(0xFFE93448)),
                  SizedBox(width: 12),
                  Text(
                    'Add Calories',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16), // Reduced from 24

          Center(
            child: Container(
              width: 306,
              height: 32,
              decoration: BoxDecoration(
                color: _selectedMeal == null
                    ? Colors.grey.shade300
                    : const Color(0xFFEE374D), // #EE374D
                borderRadius: BorderRadius.circular(5),
                boxShadow: _selectedMeal == null
                    ? []
                    : [
                        const BoxShadow(
                          color: Color.fromRGBO(238, 55, 77, 0.3),
                          offset: Offset(0, 4),
                          blurRadius: 9.2,
                          spreadRadius: 0,
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _selectedMeal == null
                    ? null
                    : () {
                        Navigator.pop(context, {'type': _selectedMeal});
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(306, 32),
                  fixedSize: const Size(306, 32),
                  backgroundColor: const Color(0xFFEE374D),
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Typically smaller for 32px height
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12), // Reduced from 20
        ],
      ),
    );
  }

  Widget _buildOption(String type) {
    bool isSelected = _selectedMeal == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedMeal = type),
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? const Color(0xFFE93448) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
          // Add shadow if selected
        ),
        child: Row(
          children: [
            // Radio Circle
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE93448)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE93448),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              type,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
