// health_metrics_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:bench_profile_app/core/usecase/usecase.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'health_metrics_event.dart';
import 'health_metrics_state.dart';

class HealthMetricsBloc extends Bloc<HealthMetricsEvent, HealthMetricsState> {
  final GetHealthMetrics getHealthMetrics;
  final GetHealthMetricsForDate getHealthMetricsForDate; // <-- injected

  HealthMetricsBloc({
    required this.getHealthMetrics,
    required this.getHealthMetricsForDate,
  }) : super(HealthMetricsEmpty()) {
    on<GetMetrics>(_onGetMetrics);
    on<GetMetricsForDate>(_onGetMetricsForDate);
  }

  Future<void> _onGetMetrics(
    GetMetrics event,
    Emitter<HealthMetricsState> emit,
  ) async {
    emit(HealthMetricsLoading());
    final failureOrMetrics = await getHealthMetrics(NoParams());
    failureOrMetrics.fold(
      (failure) => emit(HealthMetricsError(message: 'Failed to fetch health metrics: ${failure.message}')),
      (metrics) => emit(HealthMetricsLoaded(metrics: metrics)),
    );
  }

  Future<void> _onGetMetricsForDate(
    GetMetricsForDate event,
    Emitter<HealthMetricsState> emit,
  ) async {
    emit(HealthMetricsLoading());

    final params = DateParams(event.date);
    final failureOrMetrics = await getHealthMetricsForDate(params);

    failureOrMetrics.fold(
      (failure) => emit(HealthMetricsError(message: 'Failed to load metrics: ${failure.message}')),
      (HealthMetrics metrics) => emit(HealthMetricsLoaded(metrics: metrics)),
    );
  }
}
