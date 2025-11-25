import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bench_profile_app/features/bench_profile/presentation/pages/dashboard_page.dart';
import 'package:bench_profile_app/features/bench_profile/presentation/bloc/health_bloc.dart';
// state/event/model types are referenced via the real HealthBloc and repo
import 'package:dartz/dartz.dart';
import 'package:bench_profile_app/features/bench_profile/domain/repositories/health_repository.dart';
import 'package:bench_profile_app/features/bench_profile/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/features/bench_profile/domain/usecases/fetch_health_data.dart';
import 'package:bench_profile_app/features/bench_profile/domain/usecases/upload_health_data.dart';
import 'package:bench_profile_app/core/error/failures.dart';
import 'package:bench_profile_app/features/bench_profile/data/models/health_model.dart';

// A minimal fake HealthBloc for tests. It responds to FetchHealthRequested
// by emitting a HealthLoaded with deterministic data.
class _FakeRepo implements HealthRepository {
  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetrics() async {
    // Return deterministic metrics for the test
    final m = HealthModel(source: 'test', steps: 1000, heartRate: 70.0, timestamp: DateTime.now());
    return Right(m);
  }

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetricsRange(DateTime start, DateTime end, List types) async {
    final m = HealthModel(source: 'test', steps: 1000, heartRate: 70.0, timestamp: DateTime.now());
    return Right(m);
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(String uid, HealthMetrics model) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, HealthMetrics?>> getStoredHealthMetrics(String uid) async {
    return const Right(null);
  }
}

// For deterministic behavior in tests we provide a fake usecase instances.
void main() {
  testWidgets('DashboardPage shows loaded metrics when HealthBloc provides them', (WidgetTester tester) async {
    final fakeRepo = _FakeRepo();
    final fetchHealthData = FetchHealthData(fakeRepo);
    final uploadHealthData = UploadHealthData(fakeRepo);
    final fakeBloc = HealthBloc(fetchHealthData: fetchHealthData, uploadHealthData: uploadHealthData, getCurrentUid: () => null);

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<HealthBloc>.value(
        value: fakeBloc,
        child: const DashboardPage(),
      ),
    ));

    // Trigger the FetchHealthRequested that DashboardPage dispatches on first frame
    await tester.pump();
    // Allow async emits to propagate
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.textContaining('Steps:'), findsOneWidget);
    expect(find.textContaining('1000'), findsOneWidget);
  });
}
