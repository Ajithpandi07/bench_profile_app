// lib/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:bench_profile_app/core/network/network_info.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_data_source_impl.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source_isar_impl.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source_impl.dart';
import 'package:bench_profile_app/features/health_metrics/data/repositories/health_metrics_repository_impl.dart';
import 'package:bench_profile_app/features/health_metrics/domain/repositories/health_repository.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/core/network/network_info_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Externals
  sl.registerLazySingleton<Health>(() => Health());
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Initialize Isar (must finish before registering datasources that need it)
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [HealthMetricsSchema],
    directory: dir.path,
    // optional: name: 'health_metrics_db',
  );
  // register the opened Isar as a singleton
  sl.registerSingleton<Isar>(isar);

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl<Connectivity>()));
  sl.registerLazySingleton<MetricAggregator>(() => MetricAggregator());

  // Data sources
  sl.registerLazySingleton<HealthMetricsDataSource>(
    () => HealthMetricsDataSourceImpl(health: sl<Health>(), aggregator: sl<MetricAggregator>()),
  );

  // IMPORTANT: pass the Isar instance into the Isar-based local datasource
  sl.registerLazySingleton<HealthMetricsLocalDataSource>(
    () => HealthMetricsLocalDataSourceIsarImpl(sl<Isar>()),
  );

  sl.registerLazySingleton<HealthMetricsRemoteDataSource>(
    () => HealthMetricsRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );

  // Repository
  sl.registerLazySingleton<HealthRepository>(
    () => HealthMetricsRepositoryImpl(
      dataSource: sl<HealthMetricsDataSource>(),
      localDataSource: sl<HealthMetricsLocalDataSource>(),
      remoteDataSource: sl<HealthMetricsRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Usecases
  sl.registerLazySingleton<GetHealthMetrics>(() => GetHealthMetrics(sl<HealthRepository>()));
  sl.registerLazySingleton<GetHealthMetricsForDate>(
    () => GetHealthMetricsForDate(sl<HealthRepository>()),
  );

  // Bloc
  sl.registerFactory<HealthMetricsBloc>(() => HealthMetricsBloc(
        getHealthMetrics: sl<GetHealthMetrics>(),
        getHealthMetricsForDate: sl<GetHealthMetricsForDate>(),
      ));

  // Optional debug: uncomment to assert registration at startup (helpful while debugging)
  // assert(sl.isRegistered<HealthMetricsBloc>(), 'HealthMetricsBloc not registered in DI');
  // print('DI init complete: HealthMetricsBloc registered=${sl.isRegistered<HealthMetricsBloc>()}');
}
