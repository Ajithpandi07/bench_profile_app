// lib/features/bench_profile/domain/usecases/upload_health_data.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/health_metrics.dart';
import '../repositories/health_repository.dart';

class UploadHealthData implements UseCase<void, UploadHealthDataParams> {
  final HealthRepository repository;

  UploadHealthData(this.repository);

  @override
  Future<Either<Failure, void>> call(UploadHealthDataParams params) async {
    return await repository.saveHealthMetrics(params.uid, params.metrics);
  }
}

class UploadHealthDataParams extends Equatable {
  final String uid;
  final HealthMetrics metrics;

  const UploadHealthDataParams({required this.uid, required this.metrics});

  @override
  List<Object?> get props => [uid, metrics];
}
