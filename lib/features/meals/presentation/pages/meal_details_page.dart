import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/entities.dart';
import '../../../../core/core.dart';
import '../widgets/primary_button.dart';

class MealDetailsPage extends StatelessWidget {
  final String mealType;
  final double totalCalories;
  final List<MealLog> mealLogs;
  final void Function(MealLog) onEdit;

  const MealDetailsPage({
    super.key,
    required this.mealType,
    required this.totalCalories,
    required this.mealLogs,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Group items by time.
    // We can use the MealLog timestamp directly since each log has a timestamp.
    // If multiple logs have same time (to the minute), they can be grouped visually if desired,
    // or just list them as separate blocks.
    // Given the user wants "grouped t time food items list", let's assume valid logging structure.
    // We will sort logs by time.
    final sortedLogs = List<MealLog>.from(mealLogs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Scaffold(
      backgroundColor: AppTheme.mealDetailsBackground,
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
                        mealType.toUpperCase(),
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
                  if (sortedLogs.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        // Show range or first/last time?
                        // Or just remove time from here too if detailed list has times?
                        // User said "remove time, meal report page".
                        // Keep simple "Logged today" or similar?
                        // Or show range: "8:00 AM - 9:00 AM" if multiple?
                        // Let's stick to simple "X items logged" or similar if time removed from report page to match.
                        // Actually let's just show date or count.
                        Text(
                          '${sortedLogs.length} entries',
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
                    bottom: 90.0,
                  ),
                  child: Column(
                    children: [
                      if (sortedLogs.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No entries found'),
                          ),
                        )
                      else
                        ...sortedLogs.map((log) {
                          // Prepare items for this log
                          final displayFoods = <FoodItem>[];
                          displayFoods.addAll(log.items);
                          for (var um in log.userMeals) {
                            for (var f in um.foods) {
                              displayFoods.add(
                                f.copyWith(quantity: f.quantity * um.quantity),
                              );
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Time Header
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    bottom: 8.0,
                                    right: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'hh:mm a',
                                        ).format(log.timestamp),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => onEdit(log),
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Foods List Container
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
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
                                      if (displayFoods.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Text('No food items'),
                                        )
                                      else
                                        ...displayFoods.asMap().entries.map((
                                          entry,
                                        ) {
                                          final index = entry.key;
                                          final food = entry.value;
                                          return Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            food.name,
                                                            style:
                                                                const TextStyle(
                                                                  color: AppTheme
                                                                      .textDark,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 16,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
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
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Text(
                                                          (food.calories *
                                                                  food.quantity)
                                                              .toStringAsFixed(
                                                                0,
                                                              ),
                                                          style:
                                                              const TextStyle(
                                                                color: AppTheme
                                                                    .textDark,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 20,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 2,
                                                        ),
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                bottom: 2.0,
                                                              ),
                                                          child: Text(
                                                            'Kcal',
                                                            style: TextStyle(
                                                              color: AppTheme
                                                                  .mealDetailsMetaText,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (index <
                                                  displayFoods.length - 1)
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
                          );
                        }),
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
