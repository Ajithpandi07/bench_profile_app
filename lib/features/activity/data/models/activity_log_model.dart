import '../../domain/entities/activity_log.dart';

class ActivityLogModel extends ActivityLog {
  const ActivityLogModel({
    required super.id,
    required super.userId,
    required super.activityType,
    required super.startTime,
    required super.durationMinutes,
    required super.caloriesBurned,
    super.createdAt,
    super.updatedAt,
    super.notes,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      activityType: json['activityType'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      durationMinutes: json['durationMinutes'] as int,
      caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityType': activityType,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory ActivityLogModel.fromEntity(ActivityLog entity) {
    return ActivityLogModel(
      id: entity.id,
      userId: entity.userId,
      activityType: entity.activityType,
      startTime: entity.startTime,
      durationMinutes: entity.durationMinutes,
      caloriesBurned: entity.caloriesBurned,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      notes: entity.notes,
    );
  }
}
