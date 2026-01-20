// lib/features/health_metrics/data/datasources/health_metrics_data_source_impl.dart

import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:health/health.dart';
import '../../../../../core/core.dart';
import 'health_metrics_data_source.dart';
import '../../domain/entities/entities.dart';
import 'local/health_preferences_service.dart';

/// Simple global guard to avoid Health Connect rate limits
class _HealthConnectRateGuard {
  static DateTime? _lastCall;

  static Future<void> wait() async {
    if (_lastCall != null) {
      final diff = DateTime.now().difference(_lastCall!);
      if (diff.inSeconds < 10) {
        await Future.delayed(Duration(seconds: 10 - diff.inSeconds));
      }
    }
    _lastCall = DateTime.now();
  }
}

class HealthMetricsDataSourceImpl implements HealthMetricsDataSource {
  final Health _health;
  final MetricAggregator? _aggregator;
  final HealthPreferencesService _preferencesService;

  HealthMetricsDataSourceImpl({
    required Health health,
    required HealthPreferencesService preferencesService,
    MetricAggregator? aggregator,
  }) : _health = health,
       _preferencesService = preferencesService,
       _aggregator = aggregator;

  // ---------------------------------------------------------------------------
  // TIER DEFINITIONS (CRITICAL FOR RATE-LIMIT SAFETY)
  // ---------------------------------------------------------------------------

  // Tier 1: Core Daily Activity, Vitals & Sleep (High Frequency Fetch)
  List<HealthDataType> _tier1CoreTypes() => [
    // Activity
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.WORKOUT, // New - Represents sessions like Running, etc.
    // Sleep
    // HealthDataType.SLEEP_IN_BED, // Removed: Not found in HC on some devices
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_SESSION, // Modern Health Connect sleep session
  ];

  // Tier 2: Body Measurements & Vitals (Medium Frequency / Lower Volatility)
  List<HealthDataType> _tier2BodyAndVitals() => [
    // Body Measurement
    HealthDataType.HEIGHT,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BODY_MASS_INDEX, // New
    // Vitals
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.BODY_TEMPERATURE,

    // Nutrition
    HealthDataType.WATER,
    HealthDataType.BASAL_ENERGY_BURNED,
  ];

  // Tier 3: Sensitive Medical & Detailed Nutrition (Low Frequency Fetch)
  List<HealthDataType> _tier3MedicalAndNutrition() => [
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.NUTRITION, // New - For detailed macro/micronutrients
    // Add other sensitive types like MENSTRUATION_FLOW if needed...
  ];

  // ---------------------------------------------------------------------------
  // HELPER: PERMISSION CHECK
  // ---------------------------------------------------------------------------
  // Cache permission status to avoid hitting rate limits on getGrantedPermissions
  bool _hasCachedPermissions = false;
  DateTime? _lastPermissionCheck;

  Future<void> _ensurePermissions(List<HealthDataType> types) async {
    // If we checked recently (within 60s) and had permissions, skip check
    if (_hasCachedPermissions &&
        _lastPermissionCheck != null &&
        DateTime.now().difference(_lastPermissionCheck!) <
            const Duration(seconds: 60)) {
      return;
    }

    // Apply rate guard before calling Health Connect API
    await _HealthConnectRateGuard.wait();

    try {
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        dev.log(
          'DEBUG: Health Connect SDK Status: $status',
          name: 'HealthDataSource',
        );
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          throw HealthConnectNotInstalledException();
        }
      }

      dev.log(
        'DEBUG: Checking permissions for ${types.length} types...',
        name: 'HealthDataSource',
      );
      final hasPerms = await _health.hasPermissions(types) ?? false;
      dev.log(
        'DEBUG: hasPermissions returned: $hasPerms',
        name: 'HealthDataSource',
      );

      _lastPermissionCheck = DateTime.now();

      if (hasPerms) {
        _hasCachedPermissions = true;
        dev.log(
          'DEBUG: Permissions already granted.',
          name: 'HealthDataSource',
        );
        return;
      }

      // If not granted, we must request. This shows UI, so we reset cache logic potentially?
      // Requesting permissions is a heavy operation.
      _hasCachedPermissions = false;

      // Request
      dev.log(
        'DEBUG: Requesting authorization for types...',
        name: 'HealthDataSource',
      );
      final granted = await _health.requestAuthorization(types);
      dev.log(
        'DEBUG: requestAuthorization returned: $granted',
        name: 'HealthDataSource',
      );

      if (!granted) {
        throw PermissionDeniedException();
      }

      // If granted after request
      _hasCachedPermissions = true;
      _lastPermissionCheck = DateTime.now();
      dev.log(
        'DEBUG: Permissions granted after request.',
        name: 'HealthDataSource',
      );
    } catch (e) {
      if (e is HealthConnectNotInstalledException) rethrow;

      // If requestAuthorization fails explicitly or throws
      dev.log('Permission request failed: $e', name: 'HealthDataSource');
      _hasCachedPermissions = false;
      throw PermissionDeniedException();
    }
  }

  // ---------------------------------------------------------------------------
  // SAFE BATCH FETCH (NO PER-TYPE LOOPS)
  // ---------------------------------------------------------------------------

  Future<List<HealthDataPoint>> _fetchBatch(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    if (types.isEmpty) return [];

    await _HealthConnectRateGuard.wait();

    try {
      dev.log(
        'Fetching batch: ${types.map((e) => e.name).toList()}',
        name: 'HealthDataSource',
      );

      return await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );
    } catch (e) {
      dev.log(
        'Batch fetch failed (${types.length} types): $e',
        name: 'HealthDataSource',
      );
      // CRITICAL FIX: Do NOT swallow permission errors here.
      if (e.toString().toLowerCase().contains('permission') ||
          e is PermissionDeniedException) {
        throw PermissionDeniedException();
      }
      // For other errors, we might return empty list to avoid crashing the whole sync
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // MAPPING + DEDUPLICATION
  // ---------------------------------------------------------------------------

  List<HealthMetrics> _mapAndDeduplicate(List<HealthDataPoint> points) {
    final mapped = points
        .map((p) {
          try {
            return HealthMetrics.tryParse(p);
          } catch (e, st) {
            dev.log('Mapping failed: $e\n$st', name: 'HealthDataSource');
            return null;
          }
        })
        .whereType<HealthMetrics>()
        .toList();

    final Map<String, HealthMetrics> byUuid = {};
    for (final m in mapped) {
      final existing = byUuid[m.uuid];
      if (existing == null || m.dateFrom.isAfter(existing.dateFrom)) {
        byUuid[m.uuid] = m;
      }
    }
    return byUuid.values.toList();
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API
  // ---------------------------------------------------------------------------

  @override
  Future<List<HealthMetrics>> fetchFromDeviceForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      final allPoints = <HealthDataPoint>[];

      // Collect all potential types for permission request
      // Collect all potential types for permission request
      final allTypes = [
        ..._tier1CoreTypes(),
        ..._tier2BodyAndVitals(),
        ..._tier3MedicalAndNutrition(),
      ].toSet().toList(); // Deduplicate

      // FILTER BASED ON PREFERENCES
      final prefs = await _preferencesService.getAllPreferences(allTypes);
      final allowedTypes = allTypes.where((t) => prefs[t] == true).toList();

      if (allowedTypes.isEmpty) {
        // If all disabled, return empty list
        dev.log(
          'All health types disabled by user preferences.',
          name: 'HealthDataSource',
        );
        return [];
      }

      // ENSURE PERMISSIONS FIRST (only for allowed types)
      await _ensurePermissions(allowedTypes);

      // OPTIMIZATION: Fetch ALL types in a single batch
      // We reuse allowedTypes which contains the filtered union of all tiers.
      allPoints.addAll(await _fetchBatch(start, end, allowedTypes));

      dev.log(
        'Fetched ${allPoints.length} raw points from Health Connect for date $date (Start: $start, End: $end). Types found: ${allPoints.map((e) => e.typeString).toSet().toList()}',
        name: 'HealthDataSource',
      );

      if (allPoints.isEmpty) {
        dev.log(
          'WARNING: Health Connect returned 0 points. Checking permissions...',
          name: 'HealthDataSource',
        );
        final perms = await _health.hasPermissions(allTypes);
        dev.log(
          'HasPermissions for all types: $perms',
          name: 'HealthDataSource',
        );

        // DEBUG FALLBACK: Try fetching JUST STEPS to see if it's a batch issue
        dev.log(
          'DEBUG: Attempting isolated STEPS fetch...',
          name: 'HealthDataSource',
        );
        final steps = await _fetchBatch(start, end, [HealthDataType.STEPS]);
        dev.log(
          'DEBUG: Isolated STEPS fetch result count: ${steps.length}',
          name: 'HealthDataSource',
        );
        if (steps.isNotEmpty) {
          dev.log(
            'DEBUG: Steps found: ${steps.length} - ${steps.first}',
            name: 'HealthDataSource',
          );
          allPoints.addAll(steps);
        } else {
          dev.log('DEBUG: Steps list is empty', name: 'HealthDataSource');
        }

        // DEBUG FALLBACK: Try fetching JUST SLEEP to see if it's a batch issue
        dev.log(
          'DEBUG: Attempting isolated SLEEP fetch...',
          name: 'HealthDataSource',
        );
        final sleepTypes = [
          HealthDataType.SLEEP_SESSION,
          // HealthDataType.SLEEP_IN_BED, // Removed
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_AWAKE,
        ];
        final sleep = await _fetchBatch(start, end, sleepTypes);
        dev.log(
          'DEBUG: Isolated SLEEP fetch result count: ${sleep.length}',
          name: 'HealthDataSource',
        );
        if (sleep.isNotEmpty) {
          dev.log(
            'DEBUG: Sleep found: ${sleep.length}',
            name: 'HealthDataSource',
          );
          allPoints.addAll(sleep);
        }
      }

      return _mapAndDeduplicate(allPoints);
    } catch (e) {
      if (e is PermissionDeniedException) {
        rethrow;
      }
      if (e is HealthConnectNotInstalledException) {
        rethrow;
      }
      dev.log('Error in fetchFromDeviceForDate: $e', name: 'HealthDataSource');
      if (e.toString().toLowerCase().contains('permission')) {
        throw PermissionDeniedException();
      }
      return [];
    }
  }

  @override
  Future<List<HealthMetrics>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    try {
      final allPoints = <HealthDataPoint>[];

      // Prepare types for permission check
      List<HealthDataType> typesToCheck;
      if (types.isNotEmpty) {
        typesToCheck = types;
      } else {
        typesToCheck = [
          ..._tier1CoreTypes(),
          ..._tier2BodyAndVitals(),
          ..._tier3MedicalAndNutrition(),
        ].toSet().toList();
      }

      // FILTER BASED ON PREFERENCES
      final prefs = await _preferencesService.getAllPreferences(typesToCheck);
      final allowedTypes = typesToCheck.where((t) => prefs[t] == true).toList();

      if (allowedTypes.isEmpty) return [];

      // ENSURE PERMISSIONS
      await _ensurePermissions(allowedTypes);

      // If specific types requested → fetch once (filtered)
      if (types.isNotEmpty) {
        allPoints.addAll(await _fetchBatch(start, end, allowedTypes));
      } else {
        // Otherwise use tiered strategy (filtered)
        // Helper to filter tier
        List<HealthDataType> filterTier(List<HealthDataType> tier) {
          return tier.where((t) => allowedTypes.contains(t)).toList();
        }

        allPoints.addAll(
          await _fetchBatch(start, end, filterTier(_tier1CoreTypes())),
        );
        allPoints.addAll(
          await _fetchBatch(
            start, // was start.subtract(Duration(days: 90))
            end,
            filterTier(_tier2BodyAndVitals()),
          ),
        );
        allPoints.addAll(
          await _fetchBatch(
            start, // was start.subtract(Duration(days: 180))
            end,
            filterTier(_tier3MedicalAndNutrition()),
          ),
        );
      }

      return _mapAndDeduplicate(allPoints);
    } catch (e) {
      if (e is PermissionDeniedException) rethrow;
      if (e is HealthConnectNotInstalledException) rethrow;
      dev.log('Error in getHealthMetricsRange: $e', name: 'HealthDataSource');
      if (e.toString().toLowerCase().contains('permission')) {
        throw PermissionDeniedException();
      }
      return [];
    }
  }

  @override
  Future<bool> requestPermissions(List<HealthDataType> types) async {
    try {
      // Use the internal ensuring logic which handles caching/rate-limiting
      // But force a request if needed.
      // _ensurePermissions logic: checks cache, if false, requests.
      // If we are calling this method explicitly, we likely WANT to show the UI.
      // So let's force a request by invalidating cache.
      _hasCachedPermissions = false;
      await _ensurePermissions(types);
      return true;
    } catch (e) {
      if (e is PermissionDeniedException) return false;
      // If error, assume false
      return false;
    }
  }
}
