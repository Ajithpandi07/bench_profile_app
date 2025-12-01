// lib/features/health_metrics/data/datasources/health_service.dart
import '../../domain/entities/health_metrics.dart';

abstract class HealthService {
  /// Should never return null; return empty list if no datapoints
  Future<List<HealthMetrics>> fetchMetrics(DateTime start, DateTime end);
}
