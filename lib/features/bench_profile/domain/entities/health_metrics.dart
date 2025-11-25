// lib/features/bench_profile/domain/entities/health_metrics.dart
import 'package:equatable/equatable.dart';

class HealthMetrics extends Equatable {
  final String source;
  final int steps;
  final double? heartRate;
  final double? weight;
  final double? height;
  final double? activeEnergyBurned;
  final double? sleepAsleep;
  final double? sleepAwake;
  final double? water;
  final DateTime timestamp;

  const HealthMetrics({
    required this.source,
    this.steps = 0,
    this.heartRate,
    this.weight,
    this.height,
    this.activeEnergyBurned,
    this.sleepAsleep,
    this.sleepAwake,
    this.water,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        source,
        steps,
        heartRate,
        weight,
        height,
        activeEnergyBurned,
        sleepAsleep,
        sleepAwake,
        water,
        timestamp
      ];
}
