// lib/core/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core.dart';
import '../features/health_metrics/data/datasources/local/health_preferences_service.dart';
import '../features/health_metrics/health_metrics.dart' hide SyncManager;
import '../features/sleep/domain/entities/ignored_sleep_draft.dart';
import 'services/notification_service.dart';

import '../features/sleep/data/datasources/sleep_remote_data_source.dart';
import '../features/sleep/data/repositories/sleep_repository_impl.dart';
import '../features/sleep/domain/repositories/sleep_repository.dart';
import '../features/sleep/presentation/bloc/sleep_bloc.dart';

// Auth imports
import '../features/auth/auth.dart';

// Reminder imports
import '../features/reminder/reminder.dart';
import '../features/hydration/domain/domain.dart';
import '../features/hydration/data/data.dart';
import '../features/hydration/presentation/presentation.dart';
import '../features/meals/data/data.dart';
import '../features/meals/domain/repositories/meal_repository.dart';
import '../features/meals/presentation/bloc/bloc.dart';
import '../features/activity/domain/repositories/activity_repository.dart';
import '../features/activity/data/datasources/activity_remote_data_source.dart';
import '../features/activity/data/repositories/activity_repository_impl.dart';
import '../features/activity/presentation/bloc/activity_bloc.dart';

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

  // Initialize Isar
  if (!sl.isRegistered<Isar>()) {
    Isar? isar = Isar.getInstance();
    if (isar == null) {
      final dir = await getApplicationDocumentsDirectory();
      try {
        isar = await Isar.open([
          HealthMetricsSchema,
          IgnoredSleepDraftSchema,
        ], directory: dir.path);
      } catch (e) {
        if (e.toString().contains('MdbxError (11)')) {
          print(
            'CRITICAL: Isar Database is locked. This usually happens during hot restart.',
          );
        }
        rethrow;
      }
    }
    sl.registerSingleton<Isar>(isar);
  }

  // Core
  if (!sl.isRegistered<NetworkInfo>())
    sl.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(sl<Connectivity>()),
    );
  if (!sl.isRegistered<MetricAggregator>())
    sl.registerLazySingleton<MetricAggregator>(() => MetricAggregator());
  if (!sl.isRegistered<HealthPreferencesService>())
    sl.registerLazySingleton<HealthPreferencesService>(
      () => HealthPreferencesService(isar: sl<Isar>()),
    );

  // Data sources
  if (!sl.isRegistered<HealthMetricsDataSource>()) {
    sl.registerLazySingleton<HealthMetricsDataSource>(
      () => HealthMetricsDataSourceImpl(
        health: sl<Health>(),
        aggregator: sl<MetricAggregator>(),
        preferencesService: sl<HealthPreferencesService>(),
      ),
    );
  }

  // Local Isar datasource
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

  // Features - Auth
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

  // User Profile
  if (!sl.isRegistered<UserProfileRemoteDataSource>()) {
    sl.registerLazySingleton<UserProfileRemoteDataSource>(
      () => UserProfileRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<FirebaseAuth>(),
      ),
    );
  }
  if (!sl.isRegistered<UserProfileRepository>()) {
    sl.registerLazySingleton<UserProfileRepository>(
      () => UserProfileRepositoryImpl(
        remoteDataSource: sl<UserProfileRemoteDataSource>(),
        networkInfo: sl<NetworkInfo>(),
        auth: sl<FirebaseAuth>(),
      ),
    );
  }
  if (!sl.isRegistered<UserProfileBloc>()) {
    sl.registerFactory(
      () => UserProfileBloc(repository: sl<UserProfileRepository>()),
    );
  }

  // SyncManager
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

  // Features - Reminder
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

  // Features - Sleep
  sl.registerFactory(() => SleepBloc(repository: sl()));
  sl.registerLazySingleton<SleepRepository>(
    () => SleepRepositoryImpl(
      remoteDataSource: sl(),
      healthMetricsDataSource: sl(),
      localDataSource: sl(), // Inject Local Source
      networkInfo: sl(),
      preferencesService: sl(),
    ),
  );
  sl.registerLazySingleton<SleepRemoteDataSource>(
    () => SleepRemoteDataSourceImpl(firestore: sl(), auth: sl()),
  );

  // Features - Hydration
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
      () => HydrationBloc(
        repository: sl<HydrationRepository>(),
        userProfileRepository: sl<UserProfileRepository>(),
      ),
    );
  }

  // Features - Meals
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
    sl.registerFactory(
      () => MealBloc(
        repository: sl<MealRepository>(),
        userProfileRepository: sl<UserProfileRepository>(),
      ),
    );
  }

  // Features - Activity
  if (!sl.isRegistered<ActivityRemoteDataSource>()) {
    sl.registerLazySingleton<ActivityRemoteDataSource>(
      () => ActivityRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<FirebaseAuth>(),
      ),
    );
  }
  if (!sl.isRegistered<ActivityRepository>()) {
    sl.registerLazySingleton<ActivityRepository>(
      () => ActivityRepositoryImpl(
        remoteDataSource: sl<ActivityRemoteDataSource>(),
      ),
    );
  }
  if (!sl.isRegistered<ActivityBloc>()) {
    sl.registerFactory(
      () => ActivityBloc(repository: sl<ActivityRepository>()),
    );
  }
}

/// Lightweight background init
@pragma('vm:entry-point')
Future<void> initForBackground() async {
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

  if (!sl.isRegistered<Isar>()) {
    Isar? isar = Isar.getInstance();
    if (isar == null) {
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open([
        HealthMetricsSchema,
        IgnoredSleepDraftSchema,
      ], directory: dir.path);
    }
    sl.registerSingleton<Isar>(isar);
  }

  if (!sl.isRegistered<NetworkInfo>())
    sl.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(sl<Connectivity>()),
    );
  if (!sl.isRegistered<MetricAggregator>())
    sl.registerLazySingleton<MetricAggregator>(() => MetricAggregator());
  if (!sl.isRegistered<HealthPreferencesService>())
    sl.registerLazySingleton<HealthPreferencesService>(
      () => HealthPreferencesService(isar: sl<Isar>()),
    );

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

  if (!sl.isRegistered<HealthMetricsDataSource>()) {
    sl.registerLazySingleton<HealthMetricsDataSource>(
      () => HealthMetricsDataSourceImpl(
        health: sl<Health>(),
        aggregator: sl<MetricAggregator>(),
        preferencesService: sl<HealthPreferencesService>(),
      ),
    );
  }

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
