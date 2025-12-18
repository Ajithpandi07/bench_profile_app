import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bench_profile_app/features/health_metrics/presentation/pages/dashboard_page.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
// state/event/model types are referenced via the real HealthBloc and repo
import 'package:dartz/dartz.dart';
import 'package:bench_profile_app/features/health_metrics/domain/repositories/health_repository.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart';
import 'package:bench_profile_app/core/error/failures.dart';
import 'package:bench_profile_app/features/health_metrics/data/models/health_model.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'package:health/health.dart';

// A minimal fake HealthBloc for tests. It responds to FetchHealthRequested
// by emitting a HealthLoaded with deterministic data.
class _FakeRepo implements HealthRepository {
  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetrics() async {
    // Return deterministic metrics for the test
    final m = HealthModel(
      uuid: 'test-uuid',
      type: HealthDataType.STEPS.name,
      value: 1000.0,
      unit: 'COUNT',
      dateFrom: DateTime.now(),
      dateTo: DateTime.now(),
      sourceName: 'test',
      sourceId: 'test-id',
    );
    return Right([m]);
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsRange(
      DateTime start, DateTime end, List<HealthDataType> types) async {
    final m = HealthModel(
      uuid: 'test-uuid',
      type: HealthDataType.STEPS.name,
      value: 1000.0,
      unit: 'COUNT',
      dateFrom: DateTime.now(),
      dateTo: DateTime.now(),
      sourceName: 'test',
      sourceId: 'test-id',
    );
    return Right([m]);
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(
      String uid, List<HealthMetrics> model) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<HealthMetrics>?>> getStoredHealthMetrics(
      String uid) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsForDate(
      DateTime date) async {
    final m = HealthModel(
      uuid: 'test-uuid',
      type: HealthDataType.STEPS.name,
      value: 1000.0,
      unit: 'COUNT',
      dateFrom: DateTime.now(),
      dateTo: DateTime.now(),
      sourceName: 'test',
      sourceId: 'test-id',
    );
    return Right([m]);
  }

  @override
  Future<Either<Failure, void>> syncPastHealthData({int days = 30}) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> syncMetricsForDate(DateTime date) async {
    return const Right(null);
  }
}

// For deterministic behavior in tests we provide a fake usecase instances.
void main() {
  testWidgets(
      'DashboardPage shows loaded metrics when HealthBloc provides them',
      (WidgetTester tester) async {
    final fakeRepo = _FakeRepo();
    final getHealthMetrics = GetHealthMetrics(fakeRepo);
    final getHealthMetricsForDate = GetHealthMetricsForDate(fakeRepo);
    final aggregator = MetricAggregator();

    final fakeBloc = HealthMetricsBloc(
      getHealthMetrics: getHealthMetrics,
      getHealthMetricsForDate: getHealthMetricsForDate,
      aggregator: aggregator,
      repository: fakeRepo,
    );

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<HealthMetricsBloc>.value(
        value: fakeBloc,
        child: const DashboardPage(),
      ),
    ));

    // Trigger the FetchHealthRequested that DashboardPage dispatches on first frame
    await tester.pump();
    // Allow async emits to propagate
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.textContaining('Steps'), findsOneWidget);
    expect(find.textContaining('1000'), findsOneWidget);
  });
}
