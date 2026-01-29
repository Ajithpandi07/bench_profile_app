import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/entities.dart';
import '../../../../core/core.dart';
import '../widgets/primary_button.dart';

class MealDetailsPage extends StatelessWidget {
  final String mealType;
  final double totalCalories;
  final DateTime timestamp;
  final List<FoodItem> foodItems; // Assumed flattened list
  final VoidCallback onEdit;

  const MealDetailsPage({
    super.key,
    required this.mealType,
    required this.totalCalories,
    required this.timestamp,
    required this.foodItems,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mealDetailsBackground, // Light grey background
      appBar: AppBar(
        backgroundColor: AppTheme.mealDetailsBackground,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Meal',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Option menu placeholder
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Summary Card - Static
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 0,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.mealDetailsBackground,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mealType.toUpperCase(), // e.g. BREAKFAST
                        style: const TextStyle(
                          color: AppTheme.mealDetailsMetaText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppTheme.mealDetailsIconBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        totalCalories.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Kcal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.mealDetailsLabelText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Logged at ${DateFormat('hh:mm a').format(timestamp)}',
                        style: const TextStyle(
                          color: AppTheme.mealDetailsMetaText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 24.0,
                    bottom: 180.0, // Extra padding for fixed bottom buttons
                  ),
                  child: Column(
                    children: [
                      // Foods List
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                            if (foodItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('No food items listed'),
                              )
                            else
                              ...foodItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final food = entry.value;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 20,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  food.name,
                                                  style: const TextStyle(
                                                    color: AppTheme.textDark,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${food.quantity} serving',
                                                  style: const TextStyle(
                                                    color: AppTheme
                                                        .mealDetailsMetaText,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                (food.calories * food.quantity)
                                                    .toStringAsFixed(0),
                                                style: const TextStyle(
                                                  color: AppTheme.textDark,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 2.0,
                                                ),
                                                child: Text(
                                                  'Kcal',
                                                  style: TextStyle(
                                                    color: AppTheme
                                                        .mealDetailsMetaText,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index < foodItems.length - 1)
                                      Divider(
                                        height: 1,
                                        color: Colors.grey.shade100,
                                        indent: 24,
                                        endIndent: 24,
                                      ),
                                  ],
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Fixed Bottom Buttons
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.mealDetailsBackground.withOpacity(0.0),
                          AppTheme.mealDetailsBackground.withOpacity(0.8),
                          AppTheme.mealDetailsBackground,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit, size: 20),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(
                                  color: AppTheme.mealDetailsBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            text: 'Done',
                            onPressed: () => Navigator.pop(context),
                            width: double.infinity,
                            height: 56,
                            borderRadius: 30, // Consistent rounded pill shape
                            fontSize: 16,
                          ),
                        ],
                      ),
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
}
