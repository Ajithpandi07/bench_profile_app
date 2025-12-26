import 'dart:async';
import 'package:bench_profile_app/core/network/network_info.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/repositories/health_metrics_repository_impl.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

// --- Fakes ---

class FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class FakeHealthMetricsDataSource implements HealthMetricsDataSource {
  final List<HealthMetrics> deviceMetrics;

  FakeHealthMetricsDataSource(this.deviceMetrics);

  @override
  Future<List<HealthMetrics>> fetchFromDeviceForDate(DateTime date) async {
    return deviceMetrics;
  }

  @override
  Future<List<HealthMetrics>> getHealthMetricsRange(
      DateTime start, DateTime end, List<HealthDataType> types) async {
    return [];
  }

  @override
  Future<bool> requestPermissions(List<HealthDataType> types) async {
    return true;
  }
}

class FakeHealthMetricsLocalDataSource implements HealthMetricsLocalDataSource {
  final List<HealthMetrics> localMetrics;
  List<HealthMetrics> savedMetrics = [];
  List<String> explicitlySyncedIds = [];

  FakeHealthMetricsLocalDataSource(this.localMetrics);

  @override
  Future<void> cacheHealthMetrics(HealthMetrics metrics) async {
    savedMetrics.add(metrics);
  }

  @override
  Future<void> cacheHealthMetricsBatch(List<HealthMetrics> metrics) async {
    savedMetrics.addAll(metrics);
  }

  @override
  Future<List<HealthMetrics>> readFromCacheForDate(DateTime date) async {
    return localMetrics;
  }

  @override
  Future<void> markAsSynced(List<String> uuids) async {
    explicitlySyncedIds.addAll(uuids);
  }

  @override
  Future<void> clearAllLocalMetrics() async {
    // no-op
  }

  @override
  Future<List<HealthMetrics>> getMetricsForDateRange(
      DateTime start, DateTime end) async {
    return [];
  }

  @override
  Future<List<HealthMetrics>> getUnsyncedMetrics({int limit = 50}) async {
    return [];
  }
}

class FakeHealthMetricsRemoteDataSource
    implements HealthMetricsRemoteDataSource {
  List<HealthMetrics> uploadedMetrics = [];

  @override
  Future<void> uploadHealthMetrics(List<HealthMetrics> metrics) async {
    uploadedMetrics.addAll(metrics);
  }

  @override
  Future<List<HealthMetrics>> getHealthMetricsForDate(DateTime date) async {
    return [];
  }

  @override
  Future<List<HealthMetrics>> getAllHealthMetricsForUser() async {
    return [];
  }
}

// --- Tests ---

void main() {
  group('HealthMetricsRepositoryImpl - Upload Logic', () {
    test(
        'should UPLOAD device metrics even if they are already present locally and marked as synced',
        () async {
      // Arrange
      final date = DateTime(2025, 12, 25);
      final metricA = HealthMetrics(
        uuid: 'uuid-1',
        dateFrom: date,
        dateTo: date.add(const Duration(minutes: 1)),
        type: 'STEPS',
        value: 100.0, // Fixed type
        unit: 'COUNT',
        sourceId: 'device-id',
        sourceName: 'device-name',
        synced: false, // Device returns unsynced by default
      );

      // Verify copies: Local version matches Device version but isSynced=true
      final localMetricA = metricA.copyWith(synced: true);

      final fakeNetwork = FakeNetworkInfo();
      final fakeDevice = FakeHealthMetricsDataSource([metricA]);
      final fakeLocal = FakeHealthMetricsLocalDataSource([localMetricA]);
      final fakeRemote = FakeHealthMetricsRemoteDataSource();

      final repository = HealthMetricsRepositoryImpl(
        networkInfo: fakeNetwork,
        dataSource: fakeDevice,
        localDataSource: fakeLocal,
        remoteDataSource: fakeRemote,
      );

      // Act
      await repository.syncMetricsForDate(date);

      // Assert
      // 1. Should have attempted to upload metricA
      expect(fakeRemote.uploadedMetrics.length, 1,
          reason: 'Should upload 1 metric');
      expect(fakeRemote.uploadedMetrics.first.uuid, 'uuid-1');

      // 2. Should have marked as synced again (logic calls markAsSynced)
      expect(fakeLocal.explicitlySyncedIds.contains('uuid-1'), true,
          reason: 'Should mark UUID as synced after upload');
    });
  });
}
