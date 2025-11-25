// lib/features/bench_profile/data/models/health_metrics_model.dart
import '../../domain/entities/health_metrics.dart';

class HealthMetricsModel extends HealthMetrics {
  const HealthMetricsModel({
    required super.source,
    required super.timestamp,
    super.steps,
    super.heartRate,
    super.weight,
    super.height,
    super.activeEnergyBurned,
    super.sleepAsleep,
    super.sleepAwake,
    super.water,
  });

  factory HealthMetricsModel.fromEntity(HealthMetrics entity) {
    return HealthMetricsModel(
      source: entity.source,
      timestamp: entity.timestamp,
      steps: entity.steps,
      heartRate: entity.heartRate,
      weight: entity.weight,
      height: entity.height,
      activeEnergyBurned: entity.activeEnergyBurned,
      sleepAsleep: entity.sleepAsleep,
      sleepAwake: entity.sleepAwake,
      water: entity.water,
    );
  }

  // Add fromJson and toJson for network/database operations if needed
}
