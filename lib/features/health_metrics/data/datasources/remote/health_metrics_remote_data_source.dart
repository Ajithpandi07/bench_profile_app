import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';

abstract class HealthMetricsRemoteDataSource {
  Future<void> uploadHealthMetrics(HealthMetrics metrics);
}