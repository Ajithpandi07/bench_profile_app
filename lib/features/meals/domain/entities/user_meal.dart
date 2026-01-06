import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_item.dart';

class UserMeal extends Equatable {
  final String id;
  final String name;
  final List<FoodItem> foods; // Changed from foodIds
  final double totalCalories;
  final String creatorId;
  final DateTime? createdAt;

  const UserMeal({
    required this.id,
    required this.name,
    required this.foods,
    required this.totalCalories,
    required this.creatorId,
    this.createdAt,
  });

  @override
  List<Object> get props => [id, name, foods, totalCalories, creatorId];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'foods': foods.map((f) => f.toMap()).toList(), // Serialize full objects
      'totalCalories': totalCalories,
      'creatorId': creatorId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory UserMeal.fromMap(Map<String, dynamic> map) {
    return UserMeal(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      foods:
          (map['foods'] as List<dynamic>?)?.map((e) {
            return FoodItem.fromMap(Map<String, dynamic>.from(e));
          }).toList() ??
          [],
      totalCalories: (map['totalCalories'] as num?)?.toDouble() ?? 0.0,
      creatorId: map['creatorId'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
