import 'package:equatable/equatable.dart';

class UserMeal extends Equatable {
  final String id;
  final String name;
  final List<String> foodIds;
  final double totalCalories; // Cached for quick display
  final String creatorId;

  const UserMeal({
    required this.id,
    required this.name,
    required this.foodIds,
    required this.totalCalories,
    required this.creatorId,
  });

  @override
  List<Object> get props => [id, name, foodIds, totalCalories, creatorId];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'foodIds': foodIds,
      'totalCalories': totalCalories,
      'creatorId': creatorId,
    };
  }

  factory UserMeal.fromMap(Map<String, dynamic> map) {
    return UserMeal(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      foodIds: List<String>.from(map['foodIds'] ?? []),
      totalCalories: (map['totalCalories'] as num?)?.toDouble() ?? 0.0,
      creatorId: map['creatorId'] ?? '',
    );
  }
}
