// import 'package:bench_profile_app/core/error/failures.dart';
// import 'package:bench_profile_app/features/health_metrics/domain/repositories/health_repository.dart';
// import 'package:bench_profile_app/injection_container.dart';
// import 'package:flutter/foundation.dart';
// import 'package:workmanager/workmanager.dart';

// const healthSyncTask = "com.yourapp.healthSync";

// /// Top-level function to handle background execution.
// ///
// /// This function is the entry point for the background task. It must be a
// /// top-level or static function.
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     if (task == healthSyncTask) {
//       debugPrint("Background health sync task started.");

//       try {
//         // Since this runs in a separate isolate, we need to re-initialize dependencies.
//         await configureDependencies();

//         // Use a service locator to get the repository instance.
//         final healthRepo = sl<HealthRepository>();

//         // Fetch today's metrics. This will get from cache or Health Connect,
//         // then cache and upload. This ensures recent data is synced.
//         final result = await healthRepo.getHealthMetricsForDate(DateTime.now());

//         result.fold(
//           (failure) => debugPrint("Background sync failed: ${failure.message}"),
//           (metrics) => debugPrint("Background sync successful: ${metrics.length} metrics processed."),
//         );

//         return Future.value(true);
//       } catch (e) {
//         debugPrint("Error during background sync: $e");
//         return Future.value(false);
//       }
//     }
//     return Future.value(false);
//   });
// }