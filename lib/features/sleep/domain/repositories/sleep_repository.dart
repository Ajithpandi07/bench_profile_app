import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sleep_log.dart';

abstract class SleepRepository {
  Future<Either<Failure, void>> logSleep(SleepLog log);
  Future<Either<Failure, List<SleepLog>>> getSleepLogs(DateTime date);
  Future<Either<Failure, List<SleepLog>>> getSleepStats(
    DateTime start,
    DateTime end,
  );
  Future<Either<Failure, void>> deleteSleepLog(String id, DateTime date);
  Future<Either<Failure, SleepLog?>> fetchSleepFromHealthConnect(DateTime date);
}
