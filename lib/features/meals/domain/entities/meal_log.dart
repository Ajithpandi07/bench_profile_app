import 'package:equatable/equatable.dart';
import 'food_item.dart';
import 'user_meal.dart';

class MealLog extends Equatable {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String mealType; // Breakfast, Lunch, Dinner, Snack
  final List<FoodItem> items;
  final double totalCalories;
  final List<UserMeal> userMeals;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MealLog({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.mealType,
    required this.items,
    this.userMeals = const [],
    required this.totalCalories,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    timestamp,
    mealType,
    items,
    userMeals,
    totalCalories,
    createdAt,
    updatedAt,
  ];
}
