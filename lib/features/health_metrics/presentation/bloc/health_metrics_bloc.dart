import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloc/bloc.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'package:bench_profile_app/core/usecase/usecase.dart' hide DateParams;
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics_summary.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'health_metrics_event.dart';
import 'health_metrics_state.dart';

class HealthMetricsBloc extends Bloc<HealthMetricsEvent, HealthMetricsState> {
  final GetHealthMetrics getHealthMetrics;
  final GetHealthMetricsForDate getHealthMetricsForDate;
  final MetricAggregator aggregator;
  final FirebaseAuth auth;

  HealthMetricsBloc({
    required this.getHealthMetrics,
    required this.getHealthMetricsForDate,
    required this.aggregator,
    required this.auth,
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
      (failure) => emit(
        HealthMetricsError(message: 'Failed to fetch health metrics: ${failure.message}'),
      ),
      (metricsList) {
        try {
          // metricsList is List<HealthMetrics>
          final Map<String, dynamic> aggregatedMap = aggregator.aggregate(metricsList);

          final summary = HealthMetricsSummary.fromMap(aggregatedMap, DateTime.now());

          emit(HealthMetricsLoaded(metrics: summary));
        } catch (e) {
          emit(HealthMetricsError(message: 'Processing error: $e'));
        }
      },
    );
  }

  Future<void> _onGetMetricsForDate(
    GetMetricsForDate event,
    Emitter<HealthMetricsState> emit,
  ) async {
    emit(HealthMetricsLoading());

    // Use DateParams from the feature usecase (we hid the core DateParams import above)
    final params = DateParams(event.date);
    final failureOrMetrics = await getHealthMetricsForDate(params);

    failureOrMetrics.fold(
      (failure) => emit(
        HealthMetricsError(message: 'Failed to load metrics: ${failure.message}'),
      ),
      (metricsList) {
        try {
          // metricsList is List<HealthMetrics>
          final Map<String, dynamic> aggregatedMap = aggregator.aggregate(metricsList);

          final summary = HealthMetricsSummary.fromMap(aggregatedMap, event.date);

          emit(HealthMetricsLoaded(metrics: summary));
        } catch (e) {
          emit(HealthMetricsError(message: 'Processing error: $e'));
        }
      },
    );
  }
}
