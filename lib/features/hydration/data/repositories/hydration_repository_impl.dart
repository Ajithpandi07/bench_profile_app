import 'package:dartz/dartz.dart';
import 'package:bench_profile_app/core/core.dart';
import 'package:bench_profile_app/features/hydration/domain/domain.dart';
import 'package:bench_profile_app/features/hydration/data/datasources/hydration_remote_data_source.dart';

class HydrationRepositoryImpl implements HydrationRepository {
  final HydrationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  HydrationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> logWaterIntake(HydrationLog log) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.logWaterIntake(log);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to log hydration: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection.'));
    }
  }
}
