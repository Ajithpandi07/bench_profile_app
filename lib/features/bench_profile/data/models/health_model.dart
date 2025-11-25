import '../../domain/entities/health_metrics.dart';

class HealthModel extends HealthMetrics {
  HealthModel({
    required super.source,
    super.steps = 0,
    super.heartRate,
    required super.timestamp,
  });

  factory HealthModel.fromMap(Map<String, dynamic> map) {
    return HealthModel(
      source: map['source'] as String,
      steps: (map['steps'] as int?) ?? 0,
      heartRate: (map['heartRate'] as num?)?.toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'source': source,
        'steps': steps,
        'heartRate': heartRate,
        'timestamp': timestamp.toIso8601String(),
      };
}
