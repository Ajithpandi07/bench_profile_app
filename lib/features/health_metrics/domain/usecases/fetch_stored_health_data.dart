// import 'package:dartz/dartz.dart';
// import 'package:equatable/equatable.dart';
// import '../../../../core/error/failures.dart';
// import '../../../../core/usecase/usecase.dart';
// import '../entities/health_metrics.dart';
// import '../repositories/health_repository.dart';

// class FetchStoredHealthData implements UseCase<HealthMetrics, FetchStoredHealthDataParams> {
//   final HealthRepository repository;

//   FetchStoredHealthData(this.repository);

//   // @override
//   // Future<Either<Failure, HealthMetrics>> call(FetchStoredHealthDataParams params) async {
//   //   final result = await repository.getStoredHealthMetrics(params.uid);

//   //   // Handle the Either<Failure, HealthMetrics?> response
//   //   return result.fold(
//   //     (failure) => Left(failure),
//   //     (metrics) => metrics != null
//   //         ? Right(metrics)
//   //         : Left(Failure('No stored health data found for this user.')),
//   //   );
//   // }
// }

// class FetchStoredHealthDataParams extends Equatable {
//   final String uid;

//   const FetchStoredHealthDataParams({required this.uid});

//   @override
//   List<Object?> get props => [uid];
// }