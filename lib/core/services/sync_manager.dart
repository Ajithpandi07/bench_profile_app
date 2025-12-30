// lib/core/services/sync_manager.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import '../../features/health_metrics/data/datasources/remote/health_metrics_remote_data_source.dart';

/// Coordinates upload (local -> remote) and optional pull (remote -> local).
/// Designed to be safe running in both main isolate and background isolates.
///
/// Important: The local datasource must expose:
///  - Future<List<HealthMetrics>> getUnsyncedMetrics({int limit})
///  - Future<void> markAsSynced(List<String> uuids)
/// If those methods are not present, add them to your Isar implementation
/// (see the companion snippet below).
class SyncManager {
  final HealthMetricsLocalDataSource local;
  final HealthMetricsRemoteDataSource remote;
  final Connectivity connectivity;

  final int batchSize;
  final Duration interval;

  Timer? _timer;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _running = false;
  bool _busy = false;

  SyncManager({
    required this.local,
    required this.remote,
    required this.connectivity,
    this.batchSize = 200,
    this.interval = const Duration(minutes: 15),
  });

  /// Start periodic foreground sync and connectivity listener.
  void start() {
    if (_running) return;
    _running = true;

    // periodic timer only used when app in foreground/isolate running
    _timer = Timer.periodic(interval, (_) => _attemptSync());

    // listen to connectivity to run immediately when device becomes online
    _connectivitySub = connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _attemptSync();
      }
    });

    // fire an immediate try
    _attemptSync();
  }

  /// Stop periodic work and connectivity listening.
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Run a single sync pass (foreground or background). Returns true when
  /// sync completed without error (even if nothing to sync).
  Future<bool> performSyncOnce() async {
    if (_busy) return false;
    _busy = true;
    try {
      final c = await connectivity.checkConnectivity();
      if (c == ConnectivityResult.none) {
        // no connectivity — nothing to do
        return false;
      }

      await _uploadLoop();
      // Optionally implement _pullLoop() to fetch remote → local
      return true;
    } catch (e) {
      // swallow and surface false — caller can inspect logs
      print('SyncManager.performSyncOnce error: $e');
      return false;
    } finally {
      _busy = false;
    }
  }

  Future<void> _attemptSync() async {
    if (_busy) return;
    _busy = true;
    try {
      final c = await connectivity.checkConnectivity();
      if (c == ConnectivityResult.none) return;

      await _uploadLoop();
      // TODO: optionally call _pullLoop();
    } catch (e, st) {
      print('SyncManager._attemptSync failed: $e\n$st');
    } finally {
      _busy = false;
    }
  }

  /// Upload batches of unsynced metrics until none remain or an error occurs.
  Future<void> _uploadLoop() async {
    while (true) {
      // fetch unsynced items (bounded by batchSize)
      final unsynced = await local.getUnsyncedMetrics(limit: batchSize);
      if (unsynced.isEmpty) {
        // nothing to sync
        return;
      }

      try {
        // Attempt upload (remote should throw on failure)
        await remote.uploadHealthMetrics(unsynced);

        // Mark uploaded items as synced locally
        final uuids = unsynced.map((e) => e.uuid).toList();
        await local.markAsSynced(uuids);
      } catch (e, st) {
        // Stop on error and rely on retry/backoff externally.
        print('SyncManager._uploadLoop upload failed: $e\n$st');
        return;
      }
    }
  }
}
