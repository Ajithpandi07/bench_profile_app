import 'package:dartz/dartz.dart';
import '../../../../core/core.dart';
import '../entities/hydration_log.dart';

abstract class HydrationRepository {
  /// Uploads a single hydration log to the remote server.
  /// Does not cache locally.
  Future<Either<Failure, void>> logWaterIntake(HydrationLog log);
}
