// lib/main.dart
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:bench_profile_app/core/services/background_sync_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bench_profile_app/features/auth/presentation/pages/auth_wrapper.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart'
    hide SyncManager;
import 'package:bench_profile_app/core/injection_container.dart' as di;
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics.dart';
import 'package:bench_profile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bench_profile_app/core/services/sync_manager.dart';
import 'package:bench_profile_app/core/services/app_theme.dart';
import 'package:bench_profile_app/core/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for main isolate
  await Firebase.initializeApp();

  // init theme service before runApp
  await ThemeService().init();

  // Initialize dependency injection for main isolate
  try {
    await di.init(); // existing full DI for app
    print('DI init completed successfully (main isolate)');
  } catch (e, st) {
    print('DI init failed with exception (main isolate): $e\n$st');
    rethrow;
  }

  // Initialize Workmanager AFTER di.init() and Firebase.
  await Workmanager().initialize(callbackDispatcher);

  // // Register a one-off task to test background execution quickly (debug only).
  // await Workmanager().registerOneOffTask(
  //   'debug-sync-once',
  //   healthDataSyncTask,
  //   initialDelay: const Duration(seconds: 10), // runs ~10s after app start
  //   inputData: {'debug': '1'},
  // );

  // Register periodic task
  await Workmanager().registerPeriodicTask(
    "periodic-sync-id",
    healthDataSyncTask,
    // initialDelay: const Duration(seconds: 10),
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // // DEBUG: run one-shot sync immediately on startup (only in debug)
  // if (kDebugMode) {
  //   Future.delayed(const Duration(seconds: 2), () async {
  //     try {
  //       debugPrint('DEBUG: Triggering startup sync...');
  //       final ok = await di.sl<SyncManager>().performSyncOnce();
  //       debugPrint('DEBUG: Startup sync result: $ok');
  //     } catch (e, st) {
  //       debugPrint('DEBUG: Startup sync FAILED: $e\n$st');
  //     }
  //   });
  // }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide blocs once and keep MaterialApp reactive to ThemeService.mode
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<HealthMetricsBloc>()),
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
      ],
      // Listen to ThemeService.mode and rebuild MaterialApp when it changes
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService().mode,
        builder: (context, themeMode, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Bench Profile',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
