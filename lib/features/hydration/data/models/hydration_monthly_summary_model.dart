import 'package:cloud_firestore/cloud_firestore.dart';

class HydrationMonthlySummaryModel {
  final String id;
  final String userId;
  final int year;
  final int month;
  final double totalLiters;
  final Map<int, double> dailyBreakdown;

  HydrationMonthlySummaryModel({
    required this.id,
    required this.userId,
    required this.year,
    required this.month,
    required this.totalLiters,
    required this.dailyBreakdown,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'year': year,
      'month': month,
      'totalLiters': totalLiters,
      'dailyBreakdown': dailyBreakdown.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory HydrationMonthlySummaryModel.fromMap(Map<String, dynamic> map) {
    return HydrationMonthlySummaryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      year: map['year'] ?? 0,
      month: map['month'] ?? 0,
      totalLiters: (map['totalLiters'] as num?)?.toDouble() ?? 0.0,
      dailyBreakdown:
          (map['dailyBreakdown'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(int.parse(key), (value as num).toDouble()),
          ) ??
          {},
    );
  }
}
