import 'package:bench_profile_app/core/error/exceptions.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source_isar_impl.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  late HealthMetricsLocalDataSourceIsarImpl dataSource;
  late Isar isar;

  // A sample HealthMetrics object for testing
  final tHealthMetrics = HealthMetrics(
    source: 'test',
    timestamp: DateTime(2025, 10, 20, 10, 0, 0),
    steps: 100,
  );

  setUpAll(() async {
    // 1. Initialize Isar for tests
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    // 2. Open a new Isar instance for each test
    // Using a unique name ensures tests don't interfere with each other.
    final isarName = DateTime.now().microsecondsSinceEpoch.toString();
    isar = await Isar.open(
      [HealthMetricsSchema],
      directory: '', // Use in-memory database
      name: isarName,
    );

    // Override the internal _db future to point to our test instance
    dataSource = HealthMetricsLocalDataSourceIsarImpl.test(isar);
  });

  tearDown(() async {
    // 3. Close and clear the database after each test
    await isar.close(deleteFromDisk: true);
  });

  group('cacheHealthMetrics', () {
    test('should cache HealthMetrics to Isar database', () async {
      // act
      await dataSource.cacheHealthMetrics(tHealthMetrics);

      // assert
      final result = await isar.healthMetrics.get(tHealthMetrics.id);
      expect(result, equals(tHealthMetrics));
    });
  });

  group('getHealthMetricsForDate', () {
    test(
        'should return HealthMetrics from Isar when there is one in the cache for that date',
        () async {
      // arrange
      // First, cache the data
      await isar.writeTxn(() async => await isar.healthMetrics.put(tHealthMetrics));

      // act
      final result = await dataSource.getHealthMetricsForDate(tHealthMetrics.timestamp);

      // assert
      expect(result, equals(tHealthMetrics));
    });

    test('should throw a CacheException when there is no data for that date',
        () async {
      // arrange
      final otherDate = DateTime(2024, 1, 1);

      // act
      final call = dataSource.getHealthMetricsForDate;

      // assert
      // We expect the call to throw a CacheException
      expect(() => call(otherDate), throwsA(isA<CacheException>()));
    });
  });
}