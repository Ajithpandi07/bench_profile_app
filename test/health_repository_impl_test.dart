import 'package:flutter_test/flutter_test.dart';
import 'package:bench_profile_app/features/bench_profile/data/repositories/health_repository_impl.dart';
import 'package:bench_profile_app/features/bench_profile/data/datasources/health_uploader.dart';
import 'package:bench_profile_app/health_service.dart';
import 'package:bench_profile_app/features/bench_profile/data/models/health_model.dart';
import 'package:bench_profile_app/core/error/failures.dart';

void main() {
  group('HealthRepositoryImpl.saveHealthMetrics', () {
    test('returns Right when uploader succeeds', () async {
      final healthService = HealthService();
      final uploader = _FakeUploaderSuccess();
      final repo = HealthRepositoryImpl(healthService: healthService, uploader: uploader);

      final model = HealthModel(source: 'test', steps: 123, heartRate: 60.0, timestamp: DateTime.now());
      final res = await repo.saveHealthMetrics('uid123', model);
      expect(res.isRight(), true);
    });

    test('returns Left(ServerFailure) when uploader throws', () async {
      final healthService = HealthService();
      final uploader = _FakeUploaderFail();
      final repo = HealthRepositoryImpl(healthService: healthService, uploader: uploader);

      final model = HealthModel(source: 'test', steps: 123, heartRate: 60.0, timestamp: DateTime.now());
      final res = await repo.saveHealthMetrics('uid123', model);
      expect(res.isLeft(), true);
      res.fold((l) => expect(l, isA<ServerFailure>()), (r) => fail('expected left'));
    });
  });
}

class _FakeUploaderSuccess implements FirestoreHealthSource {
  @override
  Future<void> upload(String uid, HealthModel model) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return;
  }

  @override
  Future<HealthModel?> fetchLatest(String uid) async {
    return null;
  }
}

class _FakeUploaderFail implements FirestoreHealthSource {
  @override
  Future<void> upload(String uid, HealthModel model) async {
    throw Exception('upload failed');
  }

  @override
  Future<HealthModel?> fetchLatest(String uid) async {
    return null;
  }
}
