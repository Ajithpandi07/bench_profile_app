import 'package:equatable/equatable.dart';
import 'package:health/health.dart';
import '../../domain/entities/health_metrics.dart';

abstract class HealthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchHealthRequested extends HealthEvent {}
 
class UploadHealthRequested extends HealthEvent {
  final String uid;
  final HealthMetrics metrics;
  UploadHealthRequested({required this.uid, required this.metrics});
}

/// Fetch metrics for custom date range
class FetchHealthMetricsRange extends HealthEvent {
  final DateTime start;
  final DateTime end;
  final List<HealthDataType> types;

  FetchHealthMetricsRange({
    required this.start,
    required this.end,
    required this.types,
  });

  @override
  List<Object?> get props => [start, end, types];
}

/// Fetches the latest metrics from the database (Firestore).
class FetchStoredHealthRequested extends HealthEvent {
  final String uid;
  FetchStoredHealthRequested(this.uid);
  @override
  List<Object?> get props => [uid];
}