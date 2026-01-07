// lib/core/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core.dart';
import '../features/health_metrics/health_metrics.dart' hide SyncManager;
import 'services/notification_service.dart';

// Auth imports
import '../features/auth/auth.dart';

// Reminder imports
import '../features/reminder/reminder.dart';
import 'package:bench_profile_app/features/hydration/domain/domain.dart';
import 'package:bench_profile_app/features/hydration/data/data.dart';
import 'package:bench_profile_app/features/hydration/presentation/presentation.dart';
import 'package:bench_profile_app/features/meals/data/data.dart';
import 'package:bench_profile_app/features/meals/domain/repositories/meal_repository.dart';
import 'package:bench_profile_app/features/meals/presentation/bloc/bloc.dart';

final sl = GetIt.instance;

/// Full application init — used by the main isolate (UI).
Future<void> init() async {
  // Externals
  if (!sl.isRegistered<Health>())
    sl.registerLazySingleton<Health>(() => Health());
  if (!sl.isRegistered<FirebaseFirestore>())
    sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  if (!sl.isRegistered<FirebaseAuth>())
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  if (!sl.isRegistered<Connectivity>())
    sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Initialize Isar (must finish before registering datasources that need it)
  if (!sl.isRegistered<Isar>()) {
    // Check if an instance is already open (e.g., from a previous hot restart)
    // This prevents "IsarError: Cannot open Environment: MdbxError (11): Try again"
    Isar? isar = Isar.getInstance();

    if (isar == null) {
      final dir = await getApplicationDocumentsDirectory();
      try {
        isar = await Isar.open(
          [HealthMetricsSchema],
          directory: dir.path,
          // optional: name: 'health_metrics_db',
        );
      } catch (e) {
        // MdbxError (11) means the database is locked by another process/isolate.
        // This often happens during hot restart if a background task is running.
        if (e.toString().contains('MdbxError (11)')) {
          print(
            'CRITICAL: Isar Database is locked. This usually happens during hot restart if a background task is active.',
          );
          print(
            'ACTION REQUIRED: Please completely STOP the app and RUN it again (Cold Restart).',
          );
        }
        rethrow;
      }
    }
    // register the opened Isar as a singleton
    sl.registerSingleton<Isar>(isar);
  }

  // Core
  if (!sl.isRegistered<NetworkInfo>())
    sl.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(sl<Connectivity>()),
    );
  if (!sl.isRegistered<MetricAggregator>())
    sl.registerLazySingleton<MetricAggregator>(() => MetricAggregator());

  // Data sources
  if (!sl.isRegistered<HealthMetricsDataSource>()) {
    sl.registerLazySingleton<HealthMetricsDataSource>(
      () => HealthMetricsDataSourceImpl(
        health: sl<Health>(),
        aggregator: sl<MetricAggregator>(),
      ),
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
      () => HealthMetricsRepositoryImpl(
        dataSource: sl<HealthMetricsDataSource>(),
        localDataSource: sl<HealthMetricsLocalDataSource>(),
        remoteDataSource: sl<HealthMetricsRemoteDataSource>(),
        networkInfo: sl<NetworkInfo>(),
      ),
    );
  }

  // Usecases
  if (!sl.isRegistered<GetCachedMetrics>()) {
    sl.registerLazySingleton<GetCachedMetrics>(
      () => GetCachedMetrics(sl<HealthRepository>()),
    );
  }
  if (!sl.isRegistered<GetCachedMetricsForDate>()) {
    sl.registerLazySingleton<GetCachedMetricsForDate>(
      () => GetCachedMetricsForDate(sl<HealthRepository>()),
    );
  }

  // Bloc
  if (!sl.isRegistered<HealthMetricsBloc>()) {
    sl.registerFactory<HealthMetricsBloc>(
      () => HealthMetricsBloc(
        getCachedMetrics: sl<GetCachedMetrics>(),
        getCachedMetricsForDate: sl<GetCachedMetricsForDate>(),
        aggregator: sl<MetricAggregator>(),
        repository: sl<HealthRepository>(),
        mealRepository: sl<MealRepository>(),
        reminderRepository: sl<ReminderRepository>(),
        hydrationRepository: sl<HydrationRepository>(),
      ),
    );
  }

  //================
  // Features - Auth
  //================

  // Data source, repo, bloc for auth
  if (!sl.isRegistered<FirebaseAuthRemote>()) {
    sl.registerLazySingleton<FirebaseAuthRemote>(
      () => FirebaseAuthRemote(firebaseAuth: sl<FirebaseAuth>()),
    );
  }
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remote: sl<FirebaseAuthRemote>()),
    );
  }
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(() => AuthBloc(repository: sl<AuthRepository>()));
  }

  // SyncManager (foreground/background coordinator)
  if (!sl.isRegistered<SyncManager>()) {
    sl.registerLazySingleton<SyncManager>(
      () => SyncManager(
        local: sl<HealthMetricsLocalDataSource>(),
        remote: sl<HealthMetricsRemoteDataSource>(),
        connectivity: sl<Connectivity>(),
        batchSize: 200,
        interval: const Duration(minutes: 15),
      ),
    );
  }

  //================
  // Features - Reminder
  //================
  if (!sl.isRegistered<ReminderRemoteDataSource>()) {
    sl.registerLazySingleton<ReminderRemoteDataSource>(
      () => ReminderRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<FirebaseAuth>(),
      ),
    );
  }

  if (!sl.isRegistered<NotificationService>()) {
    sl.registerLazySingleton<NotificationService>(() => NotificationService());
  }

  if (!sl.isRegistered<ReminderRepository>()) {
    sl.registerLazySingleton<ReminderRepository>(
      () => ReminderRepositoryImpl(
        remoteDataSource: sl<ReminderRemoteDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<ReminderBloc>()) {
    sl.registerFactory(
      () => ReminderBloc(
        repository: sl<ReminderRepository>(),
        notificationService: sl<NotificationService>(),
      ),
    );
  }

  //================
  // Features - Hydration
  //================
  if (!sl.isRegistered<HydrationRemoteDataSource>()) {
    sl.registerLazySingleton<HydrationRemoteDataSource>(
      () => HydrationRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<FirebaseAuth>(),
      ),
    );
  }

  if (!sl.isRegistered<HydrationRepository>()) {
    sl.registerLazySingleton<HydrationRepository>(
      () => HydrationRepositoryImpl(
        remoteDataSource: sl<HydrationRemoteDataSource>(),
        networkInfo: sl<NetworkInfo>(),
      ),
    );
  }

  if (!sl.isRegistered<HydrationBloc>()) {
    sl.registerFactory(
      () => HydrationBloc(repository: sl<HydrationRepository>()),
    );
  }

  //================
  // Features - Meals
  //================
  if (!sl.isRegistered<MealRemoteDataSource>()) {
    sl.registerLazySingleton<MealRemoteDataSource>(
      () => MealRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<FirebaseAuth>(),
      ),
    );
  }

  if (!sl.isRegistered<MealRepository>()) {
    sl.registerLazySingleton<MealRepository>(
      () => MealRepositoryImpl(
        remoteDataSource: sl<MealRemoteDataSource>(),
        networkInfo: sl<NetworkInfo>(),
      ),
    );
  }

  if (!sl.isRegistered<MealBloc>()) {
    sl.registerFactory(() => MealBloc(repository: sl<MealRepository>()));
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
  if (!sl.isRegistered<Health>())
    sl.registerLazySingleton<Health>(() => Health());
  if (!sl.isRegistered<FirebaseFirestore>())
    sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  if (!sl.isRegistered<FirebaseAuth>())
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  if (!sl.isRegistered<Connectivity>())
    sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Initialize Isar for background isolate if not already done here.
  if (!sl.isRegistered<Isar>()) {
    Isar? isar = Isar.getInstance();
    if (isar == null) {
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open([HealthMetricsSchema], directory: dir.path);
    }
    sl.registerSingleton<Isar>(isar);
  }

  // Core helpers (guarded)
  if (!sl.isRegistered<NetworkInfo>())
    sl.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(sl<Connectivity>()),
    );
  if (!sl.isRegistered<MetricAggregator>())
    sl.registerLazySingleton<MetricAggregator>(() => MetricAggregator());

  // Local and remote datasources (background)
  if (!sl.isRegistered<HealthMetricsLocalDataSource>()) {
    sl.registerLazySingleton<HealthMetricsLocalDataSource>(
      () => HealthMetricsLocalDataSourceIsarImpl(sl<Isar>()),
    );
  }

  if (!sl.isRegistered<HealthMetricsRemoteDataSource>()) {
    sl.registerLazySingleton<HealthMetricsRemoteDataSource>(
      () => HealthMetricsRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<FirebaseAuth>(),
        aggregator: sl<MetricAggregator>(),
      ),
    );
  }

  // If your background sync needs the device data source (Health), register it
  if (!sl.isRegistered<HealthMetricsDataSource>()) {
    sl.registerLazySingleton<HealthMetricsDataSource>(
      () => HealthMetricsDataSourceImpl(
        health: sl<Health>(),
        aggregator: sl<MetricAggregator>(),
      ),
    );
  }

  // Repository
  if (!sl.isRegistered<HealthRepository>()) {
    sl.registerLazySingleton<HealthRepository>(
      () => HealthMetricsRepositoryImpl(
        dataSource: sl<HealthMetricsDataSource>(),
        localDataSource: sl<HealthMetricsLocalDataSource>(),
        remoteDataSource: sl<HealthMetricsRemoteDataSource>(),
        networkInfo: sl<NetworkInfo>(),
      ),
    );
  }

  // SyncManager used by background dispatcher
  if (!sl.isRegistered<SyncManager>()) {
    sl.registerLazySingleton<SyncManager>(
      () => SyncManager(
        local: sl<HealthMetricsLocalDataSource>(),
        remote: sl<HealthMetricsRemoteDataSource>(),
        connectivity: sl<Connectivity>(),
        batchSize: 200,
        interval: const Duration(minutes: 15),
      ),
    );
  }
}
