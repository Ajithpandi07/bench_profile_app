import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/sleep_remote_data_source.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/repositories/sleep_repository.dart';

class SleepRepositoryImpl implements SleepRepository {
  final SleepRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SleepRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> logSleep(SleepLog log) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.logSleep(log);
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
        final logs = await remoteDataSource.getSleepLogs(date);
        return Right(logs);
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
  Future<Either<Failure, void>> deleteSleepLog(SleepLog log) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteSleepLog(log);
        return const Right(null);
      } on ServerException {
        return const Left(ServerFailure('Server Failure'));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }
}
