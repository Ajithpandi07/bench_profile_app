import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/sleep_remote_data_source.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/repositories/sleep_repository.dart';

import 'package:health/health.dart';
import '../../../../features/health_metrics/data/datasources/health_metrics_data_source.dart';
import '../../../../features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import '../../../../features/health_metrics/data/datasources/local/health_preferences_service.dart';
import 'dart:developer' as dev;

class SleepRepositoryImpl implements SleepRepository {
  final SleepRemoteDataSource remoteDataSource;
  final HealthPreferencesService preferencesService;
  final HealthMetricsDataSource healthMetricsDataSource;
  final HealthMetricsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  SleepRepositoryImpl({
    required this.remoteDataSource,
    required this.healthMetricsDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.preferencesService,
  });

  @override
  Future<Either<Failure, void>> ignoreSleepDraft(String uuid) async {
    try {
      await preferencesService.ignoreSleepUuid(uuid);
      return const Right(null);
    } catch (e) {
      return const Right(null); // Fail silently
    }
  }

  @override
  Future<Either<Failure, List<SleepLog>>> checkLocalHealthConnectData(
    DateTime date,
  ) async {
    try {
      // Logic: Query ISAR local cache directly.
      // Do NOT use healthMetricsDataSource (Platform).
      // Use localDataSource.

      final normalizedDate = DateTime(date.year, date.month, date.day);
      final startWindow = normalizedDate.subtract(const Duration(hours: 6));
      final endWindow = DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day,
        23,
        59,
        59,
      ); // End: Today 11:59 PM

      // Fetch all metrics in range from local cache
      final metrics = await localDataSource.getMetricsForDateRange(
        startWindow,
        endWindow,
      );

      final sleepSessionMetrics = metrics.where((m) {
        return m.type == HealthDataType.SLEEP_SESSION.name &&
            m.dateTo.year == date.year &&
            m.dateTo.month == date.month &&
            m.dateTo.day == date.day;
      }).toList();

      if (sleepSessionMetrics.isEmpty) {
        return const Right([]);
      }

      sleepSessionMetrics.sort((a, b) {
        final durA = a.dateTo.difference(a.dateFrom);
        final durB = b.dateTo.difference(b.dateFrom);
        return durB.compareTo(durA); // Descending duration
      });

      final List<SleepLog> drafts = [];
      for (final session in sleepSessionMetrics) {
        // Filter ignored UUIDs
        if (await preferencesService.isSleepUuidIgnored(session.uuid)) {
          continue;
        }

        drafts.add(
          SleepLog(
            id: session.uuid, // Use actual UUID
            startTime: session.dateFrom,
            endTime: session.dateTo,
            quality: 0,
            notes: 'Health Connect (Local)',
          ),
        );
      }

      return Right(drafts);
    } catch (e) {
      // Local database error?
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, void>> logSleep(
    SleepLog log, {
    SleepLog? previousLog,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // If ID is the draft ID, treat as new log (clear ID so RemoteDS generates one)
        final logToSave = (log.id == 'health_connect_draft')
            ? SleepLog(
                id: '',
                startTime: log.startTime,
                endTime: log.endTime,
                quality: log.quality,
                notes: log.notes,
              )
            : log;

        await remoteDataSource.logSleep(logToSave, previousLog: previousLog);
        return const Right(null);
      } on ServerException {
        return const Left(ServerFailure('Server Failure'));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, List<SleepLog>>> getSleepLogs(DateTime date) async {
    if (await networkInfo.isConnected) {
      try {
        // Strategy: "Wake Up Day" Attribution.
        // We want to show sleep sessions that *ended* on [date].
        // Since logs are stored by `startTime`, a session ending on Jan 12 (started Jan 11)
        // is stored in the Jan 11 collection.
        // So we fetch logs for [date - 1 day] and [date].

        final startQuery = date.subtract(const Duration(days: 1));
        final endQuery = date;

        final rawLogs = await remoteDataSource.getSleepLogsInRange(
          startQuery,
          endQuery,
        );

        // Filter: Keep logs where the End Time falls on the requested [date]
        // We use year/month/day check to ignore time.
        final filteredLogs = rawLogs.where((log) {
          return log.endTime.year == date.year &&
              log.endTime.month == date.month &&
              log.endTime.day == date.day;
        }).toList();

        return Right(filteredLogs);
      } on ServerException {
        return const Left(ServerFailure('Server Failure'));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, List<SleepLog>>> getSleepStats(
    DateTime start,
    DateTime end,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final logs = await remoteDataSource.getSleepLogsInRange(start, end);
        return Right(logs);
      } on ServerException {
        return const Left(ServerFailure('Server Failure'));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSleepLog(String id, DateTime date) async {
    // Add to ignore list immediately
    try {
      await preferencesService.ignoreSleepUuid(id);
    } catch (_) {
      // ignore
    }

    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteSleepLog(id, date);
        return const Right(null);
      } on ServerException {
        return const Left(ServerFailure('Server Failure'));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, SleepLog?>> fetchSleepFromHealthConnect(
    DateTime date,
  ) async {
    try {
      // Query window: 6 PM previous day to 11:59 PM current day
      // This ensures we catch sleep sessions starting the night before (e.g. 10 PM)
      // and ending on the query date.
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final startWindow = normalizedDate.subtract(const Duration(hours: 6));
      final endWindow = DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day,
        23,
        59,
        59,
      ); // End: Today 11:59 PM
      // Actually date is 00:00. date + 24h is next day 00:00. Correct.

      final metrics = await healthMetricsDataSource
          .getHealthMetricsRange(startWindow, endWindow, [
            HealthDataType.SLEEP_SESSION,
            HealthDataType.SLEEP_ASLEEP,
            HealthDataType.SLEEP_AWAKE,
            HealthDataType.SLEEP_REM,
            HealthDataType.SLEEP_DEEP,
            HealthDataType.SLEEP_LIGHT,
          ]);

      dev.log(
        '[SleepRepo] Fetched ${metrics.length} metrics for $date',
        name: 'SleepRepository',
      );
      if (metrics.isNotEmpty) {
        dev.log(
          '[SleepRepo] Types: ${metrics.map((e) => e.type).toSet()}',
          name: 'SleepRepository',
        );
      }

      // Filter for sleep-related metrics
      final sleepMetrics = metrics
          .where((m) {
            final isSleep =
                m.type == HealthDataType.SLEEP_ASLEEP.name ||
                m.type == HealthDataType.SLEEP_AWAKE.name ||
                m.type == HealthDataType.SLEEP_REM.name ||
                m.type == HealthDataType.SLEEP_DEEP.name ||
                m.type == HealthDataType.SLEEP_LIGHT.name ||
                m.type == HealthDataType.SLEEP_SESSION.name;
            if (isSleep) {
              dev.log(
                '[SleepRepo] Found sleep metric: ${m.type} | Value: ${m.value} | Start: ${m.dateFrom} | End: ${m.dateTo}',
                name: 'SleepRepository',
              );
            }
            return isSleep;
          })
          .where((m) {
            // FILTER: Only include sleep that ENDED on the requested date (Wake Up Day strategy).
            // This ensures consistency with getSleepLogs.
            final isSameDay =
                m.dateTo.year == date.year &&
                m.dateTo.month == date.month &&
                m.dateTo.day == date.day;

            if (!isSameDay) {
              dev.log(
                '[SleepRepo] Skipping HC metric ending on different day: ${m.dateTo} (Request: $date)',
                name: 'SleepRepository',
              );
            }
            return isSameDay;
          })
          .toList();

      dev.log(
        '[SleepRepo] After filtering by date: ${sleepMetrics.length} metrics remain',
        name: 'SleepRepository',
      );

      if (sleepMetrics.isEmpty) {
        dev.log(
          '[SleepRepo] No metrics after date filter. Returning null.',
          name: 'SleepRepository',
        );
        return const Right(null);
      }

      // Find the range
      // Just double check min start and max end
      DateTime start = sleepMetrics.first.dateFrom;
      DateTime end = sleepMetrics.first.dateTo;

      for (final m in sleepMetrics) {
        if (m.dateFrom.isBefore(start)) start = m.dateFrom;
        if (m.dateTo.isAfter(end)) end = m.dateTo;
      }

      // Basic validation: Sleep should be at least 15 mins to matter?
      // User can confirm.

      dev.log(
        '[SleepRepo] Creating HC draft: Start=$start, End=$end',
        name: 'SleepRepository',
      );

      // Calculate stages
      Duration rem = Duration.zero;
      Duration deep = Duration.zero;
      Duration light = Duration.zero;
      Duration awake = Duration.zero;

      for (final m in sleepMetrics) {
        final duration = m.dateTo.difference(m.dateFrom);
        if (m.type == HealthDataType.SLEEP_REM.name) {
          rem += duration;
        } else if (m.type == HealthDataType.SLEEP_DEEP.name) {
          deep += duration;
        } else if (m.type == HealthDataType.SLEEP_LIGHT.name) {
          light += duration;
        } else if (m.type == HealthDataType.SLEEP_AWAKE.name) {
          awake += duration;
        }
      }

      return Right(
        SleepLog(
          id: 'health_connect_draft',
          startTime: start,
          endTime: end,
          quality: 0,
          remSleep: rem > Duration.zero ? rem : null,
          deepSleep: deep > Duration.zero ? deep : null,
          lightSleep: light > Duration.zero ? light : null,
          awakeSleep: awake > Duration.zero ? awake : null,
          notes: 'Imported from Health Connect',
        ),
      );
    } catch (e) {
      // Return null or failure?
      // Failing to fetch from Health Connect shouldn't block the app.
      // We can return Right(null) effectively saying "no data found / error".
      // Or return a Failure if we want to show an error message.
      // Let's return Right(null) for now to be safe, or print error.
      return const Right(null);
    }
  }
}
