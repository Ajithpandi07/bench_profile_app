import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_item.dart';

class UserMeal extends Equatable {
  final String id;
  final String name;
  final List<FoodItem> foods; // Changed from foodIds
  final double totalCalories;
  final String creatorId;
  final int quantity;
  final DateTime? createdAt;

  const UserMeal({
    required this.id,
    required this.name,
    required this.foods,
    required this.totalCalories,
    required this.creatorId,
    this.quantity = 1,
    this.createdAt,
  });

  @override
  List<Object> get props => [
    id,
    name,
    foods,
    totalCalories,
    creatorId,
    quantity,
  ];

  UserMeal copyWith({
    String? id,
    String? name,
    List<FoodItem>? foods,
    double? totalCalories,
    String? creatorId,
    int? quantity,
    DateTime? createdAt,
  }) {
    return UserMeal(
      id: id ?? this.id,
      name: name ?? this.name,
      foods: foods ?? this.foods,
      totalCalories: totalCalories ?? this.totalCalories,
      creatorId: creatorId ?? this.creatorId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({bool isSnapshot = false}) {
    return {
      'id': id,
      'name': name,
      'foods': foods.map((f) => f.toMap()).toList(),
      'totalCalories': totalCalories,
      'creatorId': creatorId,
      'quantity': quantity,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (isSnapshot ? Timestamp.now() : FieldValue.serverTimestamp()),
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
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
