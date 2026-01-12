import 'package:cloud_firestore/cloud_firestore.dart';

class SleepMonthlySummaryModel {
  final String id;
  final int year;
  final int month;
  final int totalDurationMinutes;
  final int daysWithData;
  final double avgQuality;
  final Map<String, int> dailyBreakdown; // "day": minutes

  const SleepMonthlySummaryModel({
    required this.id,
    required this.year,
    required this.month,
    required this.totalDurationMinutes,
    required this.daysWithData,
    required this.avgQuality,
    required this.dailyBreakdown,
  });

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'month': month,
      'totalDurationMinutes': totalDurationMinutes,
      'daysWithData': daysWithData,
      'avgQuality': avgQuality,
      'dailyBreakdown': dailyBreakdown,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SleepMonthlySummaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SleepMonthlySummaryModel(
      id: doc.id,
      year: data['year'] ?? 0,
      month: data['month'] ?? 0,
      totalDurationMinutes: data['totalDurationMinutes'] ?? 0,
      daysWithData: data['daysWithData'] ?? 0,
      avgQuality: (data['avgQuality'] ?? 0).toDouble(),
      dailyBreakdown: Map<String, int>.from(data['dailyBreakdown'] ?? {}),
    );
  }
}
