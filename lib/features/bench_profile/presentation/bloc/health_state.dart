import 'package:equatable/equatable.dart';
import '../../domain/entities/health_metrics.dart';

abstract class HealthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HealthInitial extends HealthState {}

class HealthLoading extends HealthState {}

class HealthLoaded extends HealthState {
  final HealthMetrics metrics;
  HealthLoaded(this.metrics);
  @override
  List<Object?> get props => [metrics.source, metrics.steps, metrics.heartRate];
}

class HealthFailure extends HealthState {
  final String message;
  HealthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class HealthUploadInProgress extends HealthState {}

class HealthUploadSuccess extends HealthState {
  final String message;
  HealthUploadSuccess([this.message = 'Upload successful']);
  @override
  List<Object?> get props => [message];
}

class HealthUploadFailure extends HealthState {
  final String message;
  HealthUploadFailure(this.message);
  @override
  List<Object?> get props => [message];
}
