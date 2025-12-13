// lib/core/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bench_profile_app/core/network/network_info.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_data_source_impl.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source_isar_impl.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source_impl.dart';
import 'package:bench_profile_app/features/health_metrics/domain/repositories/isar_health_metrics_repository.dart';
import 'package:bench_profile_app/features/health_metrics/domain/repositories/health_repository.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart' hide SyncManager;
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/core/network/network_info_impl.dart';

// SyncManager import (adjust path if different)
import 'package:bench_profile_app/core/services/background_sync_service.dart';
import 'package:bench_profile_app/core/services/sync_manager.dart';
// /home/support/bench_profile_app/lib/core/services/sync_manager

// Auth imports
import 'package:bench_profile_app/features/auth/data/datasources/firebase_auth_remote.dart';
import 'package:bench_profile_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bench_profile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:bench_profile_app/features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

/// Full application init — used by the main isolate (UI).
Future<void> init() async {
  // Externals
  if (!sl.isRegistered<Health>()) sl.registerLazySingleton<Health>(() => Health());
  if (!sl.isRegistered<FirebaseFirestore>()) sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  if (!sl.isRegistered<FirebaseAuth>()) sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  if (!sl.isRegistered<Connectivity>()) sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Initialize Isar (must finish before registering datasources that need it)
  if (!sl.isRegistered<Isar>()) {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [HealthMetricsSchema],
      directory: dir.path,
      // optional: name: 'health_metrics_db',
    );
    // register the opened Isar as a singleton
    sl.registerSingleton<Isar>(isar);
  }

  // Core
  if (!sl.isRegistered<NetworkInfo>()) sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl<Connectivity>()));
  if (!sl.isRegistered<MetricAggregator>()) sl.registerLazySingleton<MetricAggregator>(() => MetricAggregator());

  // Data sources
  if (!sl.isRegistered<HealthMetricsDataSource>()) {
    sl.registerLazySingleton<HealthMetricsDataSource>(
      () => HealthMetricsDataSourceImpl(health: sl<Health>(), aggregator: sl<MetricAggregator>()),
    );
  }

  // Local Isar datasource (pass Isar instance)
  if (!sl.isRegistered<HealthMetricsLocalDataSource>()) {
    sl.registerLazySingleton<HealthMetricsLocalDataSource>(
      () => HealthMetricsLocalDataSourceIsarImpl(sl<Isar>()),
    );
  }

  // Remote datasource
  if (!sl.isRegistered<HealthMetricsRemoteDataSource>()) {
    sl.registerLazySingleton<HealthMetricsRemoteDataSource>(
      () => HealthMetricsRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<FirebaseAuth>(),
        aggregator: sl<MetricAggregator>(),
      ),
    );
  }

  // Repository
  if (!sl.isRegistered<HealthRepository>()) {
    sl.registerLazySingleton<HealthRepository>(
      () => IsarHealthMetricsRepository(
        isar: sl<Isar>(),
        healthDataSource: sl<HealthMetricsDataSource>(),
        remoteDataSource: sl<HealthMetricsRemoteDataSource>(),
      ),
    );
  }

  // Usecases
  if (!sl.isRegistered<GetHealthMetrics>()) {
    sl.registerLazySingleton<GetHealthMetrics>(() => GetHealthMetrics(sl<HealthRepository>()));
  }
  if (!sl.isRegistered<GetHealthMetricsForDate>()) {
    sl.registerLazySingleton<GetHealthMetricsForDate>(() => GetHealthMetricsForDate(sl<HealthRepository>()));
  }

  // Bloc
  if (!sl.isRegistered<HealthMetricsBloc>()) {
    sl.registerFactory<HealthMetricsBloc>(() => HealthMetricsBloc(
          getHealthMetrics: sl<GetHealthMetrics>(),
          getHealthMetricsForDate: sl<GetHealthMetricsForDate>(),
          aggregator: sl<MetricAggregator>(),
          repository: sl<HealthRepository>(),
        ));
  }

  //================
  // Features - Auth
  //================

  // Data source, repo, bloc for auth
  if (!sl.isRegistered<FirebaseAuthRemote>()) {
    sl.registerLazySingleton<FirebaseAuthRemote>(() => FirebaseAuthRemote(firebaseAuth: sl<FirebaseAuth>()));
  }
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(remote: sl<FirebaseAuthRemote>()));
  }
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(() => AuthBloc(repository: sl<AuthRepository>()));
  }

  // SyncManager (foreground/background coordinator)
  if (!sl.isRegistered<SyncManager>()) {
    sl.registerLazySingleton<SyncManager>(() => SyncManager(
          local: sl<HealthMetricsLocalDataSource>(),
          remote: sl<HealthMetricsRemoteDataSource>(),
          connectivity: sl<Connectivity>(),
          batchSize: 200,
          interval: const Duration(minutes: 15),
        ));
  }

  // Optional debug logs
  // print('DI init complete: HealthMetricsBloc registered=${sl.isRegistered<HealthMetricsBloc>()}');
}

/// Lightweight background init — used in the background isolate.
/// Registers only the minimal services required for background sync.
///
/// IMPORTANT:
/// - This runs in the background isolate (separate memory) and must *not* assume
///   the main isolate's singletons are available.
/// - Guard against duplicate registrations using sl.isRegistered<...>().
@pragma('vm:entry-point')
Future<void> initForBackground() async {
  // Externals (register only if missing)
  if (!sl.isRegistered<Health>()) sl.registerLazySingleton<Health>(() => Health());
  if (!sl.isRegistered<FirebaseFirestore>()) sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  if (!sl.isRegistered<FirebaseAuth>()) sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  if (!sl.isRegistered<Connectivity>()) sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Initialize Isar for background isolate if not already done here.
  if (!sl.isRegistered<Isar>()) {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [HealthMetricsSchema],
      directory: dir.path,
    );
    sl.registerSingleton<Isar>(isar);
  }

  // Core helpers (guarded)
  if (!sl.isRegistered<NetworkInfo>()) sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl<Connectivity>()));
  if (!sl.isRegistered<MetricAggregator>()) sl.registerLazySingleton<MetricAggregator>(() => MetricAggregator());

  // Local and remote datasources (background)
  if (!sl.isRegistered<HealthMetricsLocalDataSource>()) {
    sl.registerLazySingleton<HealthMetricsLocalDataSource>(() => HealthMetricsLocalDataSourceIsarImpl(sl<Isar>()));
  }

  if (!sl.isRegistered<HealthMetricsRemoteDataSource>()) {
    sl.registerLazySingleton<HealthMetricsRemoteDataSource>(() => HealthMetricsRemoteDataSourceImpl(
          firestore: sl<FirebaseFirestore>(),
          auth: sl<FirebaseAuth>(),
          aggregator: sl<MetricAggregator>(),
        ));
  }

  // If your background sync needs the device data source (Health), register it
  if (!sl.isRegistered<HealthMetricsDataSource>()) {
    sl.registerLazySingleton<HealthMetricsDataSource>(() => HealthMetricsDataSourceImpl(
          health: sl<Health>(),
          aggregator: sl<MetricAggregator>(),
        ));
  }

  // Repository
  if (!sl.isRegistered<HealthRepository>()) {
    sl.registerLazySingleton<HealthRepository>(() => IsarHealthMetricsRepository(
          isar: sl<Isar>(),
          healthDataSource: sl<HealthMetricsDataSource>(),
          remoteDataSource: sl<HealthMetricsRemoteDataSource>(),
        ));
  }

  // SyncManager used by background dispatcher
  if (!sl.isRegistered<SyncManager>()) {
    sl.registerLazySingleton<SyncManager>(() => SyncManager(
          local: sl<HealthMetricsLocalDataSource>(),
          remote: sl<HealthMetricsRemoteDataSource>(),
          connectivity: sl<Connectivity>(),
          batchSize: 200,
          interval: const Duration(minutes: 15),
        ));
  }
}
