// lib/features/bench_profile/data/datasources/health_data_source.dart
import '../models/health_metrics_model.dart';

abstract class HealthDataSource {
  Future<HealthMetricsModel> fetchHealthData();
}
