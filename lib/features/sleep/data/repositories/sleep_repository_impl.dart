import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/sleep_remote_data_source.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/repositories/sleep_repository.dart';

import 'package:health/health.dart';
import '../../../../features/health_metrics/data/datasources/health_metrics_data_source.dart';
import 'dart:developer' as dev;

class SleepRepositoryImpl implements SleepRepository {
  final SleepRemoteDataSource remoteDataSource;
  final HealthMetricsDataSource healthMetricsDataSource;
  final NetworkInfo networkInfo;

  SleepRepositoryImpl({
    required this.remoteDataSource,
    required this.healthMetricsDataSource,
    required this.networkInfo,
  });

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
      final startWindow = date.subtract(const Duration(hours: 6));
      final endWindow = date.add(
        const Duration(hours: 24),
      ); // Until next day 00:00?
      // Actually date is 00:00. date + 24h is next day 00:00. Correct.

      final metrics = await healthMetricsDataSource
          .getHealthMetricsRange(startWindow, endWindow, [
            HealthDataType.SLEEP_SESSION,
            HealthDataType.SLEEP_ASLEEP,
            HealthDataType.SLEEP_AWAKE,
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
                // m.type == HealthDataType.SLEEP_IN_BED.name || // Removed
                m.type == HealthDataType.SLEEP_AWAKE.name ||
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

      if (sleepMetrics.isEmpty) return const Right(null);

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

      return Right(
        SleepLog(
          id: 'health_connect_draft',
          startTime: start,
          endTime: end,
          quality: 0,
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
