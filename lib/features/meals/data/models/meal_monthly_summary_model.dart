import 'package:cloud_firestore/cloud_firestore.dart';

class MealMonthlySummaryModel {
  final String id;
  final String userId;
  final int year;
  final int month;
  final double totalCalories;
  final Map<int, double> dailyBreakdown;

  MealMonthlySummaryModel({
    required this.id,
    required this.userId,
    required this.year,
    required this.month,
    required this.totalCalories,
    required this.dailyBreakdown,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'year': year,
      'month': month,
      'totalCalories': totalCalories,
      'dailyBreakdown': dailyBreakdown,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MealMonthlySummaryModel.fromMap(Map<String, dynamic> map) {
    return MealMonthlySummaryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      year: map['year'] ?? 0,
      month: map['month'] ?? 0,
      totalCalories: (map['totalCalories'] as num?)?.toDouble() ?? 0.0,
      dailyBreakdown:
          (map['dailyBreakdown'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(int.parse(key), (value as num).toDouble()),
          ) ??
          {},
    );
  }
}
