// lib/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_local_data_source_impl.dart';
import 'package:bench_profile_app/features/health_metrics/data/repositories/health_metrics_repository_impl.dart';
import 'package:bench_profile_app/features/health_metrics/domain/repositories/health_metrics_repository.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
import 'package:health/health.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final sl = GetIt.instance;

void init() {
  // Externals
  sl.registerLazySingleton<Health>(() => Health());
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Data sources
  sl.registerLazySingleton<HealthMetricsLocalDataSource>(
    () => HealthMetricsLocalDataSourceImpl(
      health: sl<Health>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<HealthMetricsRepository>(
    () => HealthMetricsRepositoryImpl(localDataSource: sl<HealthMetricsLocalDataSource>()),
  );

  // Usecases
  sl.registerLazySingleton<GetHealthMetrics>(() => GetHealthMetrics(sl<HealthMetricsRepository>()));
  sl.registerLazySingleton<GetHealthMetricsForDate>(
    () => GetHealthMetricsForDate(sl<HealthMetricsRepository>()),
  );

  // Bloc
  sl.registerFactory<HealthMetricsBloc>(() => HealthMetricsBloc(
        getHealthMetrics: sl<GetHealthMetrics>(),
        getHealthMetricsForDate: sl<GetHealthMetricsForDate>(),
      ));
}
