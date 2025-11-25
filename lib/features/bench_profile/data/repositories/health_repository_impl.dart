import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/health_metrics.dart';
import '../../domain/repositories/health_repository.dart';
import '../../../../health_service.dart';
import '../datasources/health_uploader.dart' as ds;
import '../models/health_model.dart';

class HealthRepositoryImpl implements HealthRepository {
  final HealthService healthService;
  final ds.FirestoreHealthSource uploader;
  HealthRepositoryImpl({required this.healthService, required this.uploader});

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetrics() async {
    try {
      final m = await healthService.fetchHealthData();
      return Right(m);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetricsRange(DateTime start, DateTime end, List<dynamic> types) async {
    try {
      // Note: HealthService's fetchHealthData is hardcoded for the last 24 hours.
      // For a true range, HealthService would need to be updated.
      final m = await healthService.fetchHealthData();
      return Right(m);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(String uid, HealthMetrics model) async {
    try {
      // Ensure uploader receives a HealthModel instance (data layer). If
      // the domain model is already a HealthModel, use it; otherwise convert.
      HealthModel toUpload;
      if (model is HealthModel) {
        toUpload = model;
      } else {
        toUpload = HealthModel(
          source: model.source,
          steps: model.steps,
          heartRate: model.heartRate,
          timestamp: model.timestamp,
        );
      }

      await uploader.upload(uid, toUpload);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HealthMetrics?>> getStoredHealthMetrics(String uid) async {
    try {
      final metrics = await uploader.fetchLatest(uid);
      return Right(metrics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
