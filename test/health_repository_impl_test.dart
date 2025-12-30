import 'package:flutter_test/flutter_test.dart';
import 'package:bench_profile_app/features/health_metrics/data/repositories/health_metrics_repository_impl.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/core/core.dart';
import 'package:bench_profile_app/core/error/failures.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'helpers/test_mocks.mocks.dart';

void main() {
  late HealthMetricsRepositoryImpl repository;
  late MockHealthMetricsDataSource mockDataSource;
  late MockHealthMetricsLocalDataSource mockLocalDataSource;
  late MockHealthMetricsRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockDataSource = MockHealthMetricsDataSource();
    mockLocalDataSource = MockHealthMetricsLocalDataSource();
    mockRemoteDataSource = MockHealthMetricsRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = HealthMetricsRepositoryImpl(
      dataSource: mockDataSource,
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('saveHealthMetrics', () {
    final List<HealthMetrics> tHealthMetricsList = [
      HealthMetrics(
        uuid: 'test-uuid',
        dateFrom: DateTime.now(),
        dateTo: DateTime.now(),
        type: 'STEPS',
        value: 100,
        unit: 'COUNT',
        sourceId: 'test-source',
        sourceName: 'test-device',
      )
    ];
    const tUid = 'test-uid';

    test('should check if device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.uploadHealthMetrics(any))
          .thenAnswer((_) async => Future.value());
      when(mockLocalDataSource.cacheHealthMetricsBatch(any))
          .thenAnswer((_) async => Future.value());

      // act
      await repository.saveHealthMetrics(tUid, tHealthMetricsList);

      // assert
      verify(mockNetworkInfo.isConnected);
    });

    group('device is online', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });

      test('should return Right(null) when remote upload is successful',
          () async {
        // arrange
        when(mockRemoteDataSource.uploadHealthMetrics(any))
            .thenAnswer((_) async => Future.value());
        when(mockLocalDataSource.cacheHealthMetricsBatch(any))
            .thenAnswer((_) async => Future.value());

        // act
        final result =
            await repository.saveHealthMetrics(tUid, tHealthMetricsList);

        // assert
        verify(mockRemoteDataSource.uploadHealthMetrics(tHealthMetricsList));
        expect(result, const Right(null));
      });

      test('should return Left(ServerFailure) when remote upload fails',
          () async {
        // arrange
        when(mockRemoteDataSource.uploadHealthMetrics(any))
            .thenThrow(ServerException('Server Error'));

        // act
        final result =
            await repository.saveHealthMetrics(tUid, tHealthMetricsList);

        // assert
        verify(mockRemoteDataSource.uploadHealthMetrics(tHealthMetricsList));
        expect(
            result,
            const Left(ServerFailure(
                'Failed to save metrics to remote: ServerException: Server Error')));
      });
    });

    group('device is offline', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });

      test('should return Left(NetworkFailure)', () async {
        // act
        final result =
            await repository.saveHealthMetrics(tUid, tHealthMetricsList);

        // assert
        expect(
            result,
            const Left(NetworkFailure(
                'No internet connection. Could not save metrics.')));
      });
    });
  });
}
