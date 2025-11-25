import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_model.dart';

/// Remote datasource that uses platform sensors (via MethodChannel) to read
/// step counts and optional heart-rate without requiring external companion apps.
class HealthRemote {
  static const MethodChannel _channel = MethodChannel('bench_profile/health');

  /// Fetches aggregated metrics for the last 24 hours (delegates to platform).
  Future<HealthModel> fetchHealthMetrics() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));
    return fetchHealthMetricsRange(start, now, []);
  }

  /// Fetches and aggregates metrics for a custom range. On Android this
  /// returns the latest sensor values (step counter is cumulative since boot).
  Future<HealthModel> fetchHealthMetricsRange(DateTime start, DateTime end, List types) async {
    // Request runtime permissions on Android where needed.
    if (Platform.isAndroid) {
      final needed = [Permission.activityRecognition, Permission.sensors];
      final statuses = await needed.request();
      for (final p in needed) {
        if (statuses[p] != PermissionStatus.granted) {
          if (statuses[p] == PermissionStatus.permanentlyDenied) {
            throw Exception('Permission ${p.toString()} permanently denied. Open app settings to grant the permission.');
          } else {
            throw Exception('Permission ${p.toString()} not granted. Please allow the permission and retry.');
          }
        }
      }
    }

    final res = await _channel.invokeMethod('getCurrentMetrics', {'since': start.millisecondsSinceEpoch});
    if (res == null) throw Exception('No data from platform sensors');

    final Map<dynamic, dynamic> map = res as Map<dynamic, dynamic>;
    final source = (map['source'] as String?) ?? 'sensors';
    final cumulative = map['steps'] != null ? (map['steps'] as int) : null;
    final hr = map['heartRate'] != null ? (map['heartRate'] as num).toDouble() : null;
    final timestamp = map['timestamp'] != null ? DateTime.fromMillisecondsSinceEpoch((map['timestamp'] as int)) : end;

    int? steps;
    // On Android we receive a cumulative step counter (since boot). Convert
    // it to a per-day value using a stored baseline in SharedPreferences.
    if (Platform.isAndroid && cumulative != null) {
      final prefs = await SharedPreferences.getInstance();
      final key = _baselineKeyForDate(DateTime.now());
      final baseline = prefs.getInt(key);
      if (baseline == null) {
        // First run today: store baseline as current cumulative and treat
        // today's steps as zero (we'll count from now).
        await prefs.setInt(key, cumulative);
        steps = 0;
      } else {
        if (cumulative >= baseline) {
          steps = cumulative - baseline;
        } else {
          // Counter reset (device reboot); reset baseline to current value
          await prefs.setInt(key, cumulative);
          steps = 0;
        }
      }
    } else {
      // For iOS (pedometer) or when cumulative not available, trust the
      // platform value directly.
      steps = cumulative;
    }

    return HealthModel(
      source: source,
      steps: steps ?? 0,
      heartRate: hr,
      timestamp: timestamp,
    );
  }

  String _baselineKeyForDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'steps_baseline_${y}_${m}_${d}';
  }
}
