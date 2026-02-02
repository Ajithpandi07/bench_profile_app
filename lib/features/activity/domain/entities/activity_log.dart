import 'package:equatable/equatable.dart';

class ActivityLog extends Equatable {
  final String id;
  final String userId;
  final String activityType; // Walking, Running, Cycling, etc.
  final String? customActivityName; // User-entered name for custom activities
  final DateTime
  startTime; // Replaces timestamp in meal log for clarity, or keep timestamp
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? notes;

  const ActivityLog({
    required this.id,
    required this.userId,
    required this.activityType,
    this.customActivityName,
    required this.startTime,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.createdAt,
    this.updatedAt,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    activityType,
    customActivityName,
    startTime,
    durationMinutes,
    caloriesBurned,
    createdAt,
    updatedAt,
    notes,
  ];
}
