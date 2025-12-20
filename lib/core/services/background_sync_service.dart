import 'dart:io';

import 'package:bench_profile_app/core/injection_container.dart' as di;
import 'package:bench_profile_app/core/services/sync_manager.dart';
import 'package:bench_profile_app/features/health_metrics/domain/repositories/health_repository.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:async';

const String healthDataSyncTask =
    "com.example.bench_profile_app.syncPastHealthData";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Ensure Flutter bindings are available in the background isolate.
    WidgetsFlutterBinding.ensureInitialized();
    // Add inputData to the log for more context
    await _bgLog('callbackDispatcher START task=$taskName, input=$inputData');

    try {
      await _bgLog('Initializing Firebase...');
      // Initialize Firebase inside the background isolate.
      await Firebase.initializeApp();
      await _bgLog('Firebase initialized.');

      await _bgLog('Initializing dependencies for background...');
      // Use the lightweight DI setup for background tasks.
      await di.initForBackground();
      await _bgLog('Dependencies initialized.');

      // In a background isolate, currentUser is initially null. We must wait for
      // the auth state to be restored from persistent storage.
      await _bgLog('Waiting for Firebase Auth to restore user session...');
      final user = await di
          .sl<FirebaseAuth>()
          .authStateChanges()
          .first // Get the first event, which is the restored user or null.
          .timeout(const Duration(seconds: 10), onTimeout: () {
        // This is a clearer way to handle a timeout than a generic catch.
        throw TimeoutException(
            'Firebase Auth session restoration timed out after 10 seconds.');
      });

      if (user == null) {
        await _bgLog(
            'callbackDispatcher: No authenticated user found after waiting. Aborting sync.');
        return Future.value(false);
      }
      await _bgLog('User session restored for UID: ${user.uid}');

      // Locate the HealthRepository to perform the historical data sync.
      await _bgLog('Locating HealthRepository...');
      final healthRepo = di.sl<HealthRepository>();
      await _bgLog('HealthRepository found. Starting syncPastHealthData().');

      // Execute the sync for the past 45 days as requested.
      final result = await healthRepo.syncPastHealthData(days: 1);
      final success = result.isRight(); // `isRight()` means it was successful.

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'last_sync_timestamp', DateTime.now().toIso8601String());
      }

      await _bgLog(
          'callbackDispatcher COMPLETE for task=$taskName. Success: $success');

      return Future.value(true);
    } on TimeoutException catch (e, st) {
      // Specifically catch the timeout from the auth check.
      await _bgLog('callbackDispatcher TIMEOUT ERROR: $e\n$st');
      return Future.value(false); // Return false on timeout.
    } catch (e, st) {
      await _bgLog('callbackDispatcher ERROR: $e\n$st');
      return Future.value(false);
    }
  });
}

Future<void> _bgLog(String message) async {
  final msg = '${DateTime.now().toIso8601String()} $message';
  // Print — also appears in logcat.
  print(msg);

  // Append to a file in application document directory for later inspection.
  try {
    // Use a more reliable directory for logs
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bench_bg.log');
    await file.writeAsString('$msg\n', mode: FileMode.append);
  } catch (e) {
    print('Failed to write to background log file: $e');
  }
}
