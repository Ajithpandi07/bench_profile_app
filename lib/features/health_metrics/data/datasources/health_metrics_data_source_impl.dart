// lib/features/health_metrics/data/datasources/health_metrics_data_source_impl.dart

import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'package:bench_profile_app/core/error/exceptions.dart';
import 'health_metrics_data_source.dart';
import '../../domain/entities/health_metrics.dart';

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

  HealthMetricsDataSourceImpl({
    required Health health,
    MetricAggregator? aggregator,
  })  : _health = health,
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
        // HealthDataType.SLEEP_IN_BED, // New - Total sleep session duration
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
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

  Future<void> _ensurePermissions(List<HealthDataType> types) async {
    try {
      final hasPerms = await _health.hasPermissions(types) ?? false;
      if (!hasPerms) {
        // Request
        final granted = await _health.requestAuthorization(types);
        if (!granted) {
          throw PermissionDeniedException();
        }
      }
    } catch (e) {
      // If requestAuthorization fails explicitly or throws
      dev.log('Permission request failed: $e', name: 'HealthDataSource');
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
            return HealthMetrics.fromHealthDataPoint(p);
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
  Future<List<HealthMetrics>> getHealthMetricsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      final allPoints = <HealthDataPoint>[];

      // Collect all potential types for permission request
      final allTypes = [
        ..._tier1CoreTypes(),
        ..._tier2BodyAndVitals(),
        ..._tier3MedicalAndNutrition(),
      ].toSet().toList(); // Deduplicate

      // ENSURE PERMISSIONS FIRST
      await _ensurePermissions(allTypes);

      // Tier 1 – Core Daily Activity & Sleep (1-day lookback)
      allPoints.addAll(
        await _fetchBatch(start, end, _tier1CoreTypes()),
      );

      // Tier 2 – Body Measurements & Vitals (No lookback, only today)
      allPoints.addAll(
        await _fetchBatch(
          start, // was start.subtract(Duration(days: 90))
          end,
          _tier2BodyAndVitals(),
        ),
      );

      // Tier 3 – Sensitive/Detailed (No lookback, only today)
      allPoints.addAll(
        await _fetchBatch(
          start, // was start.subtract(Duration(days: 180))
          end,
          _tier3MedicalAndNutrition(),
        ),
      );

      return _mapAndDeduplicate(allPoints);
    } catch (e) {
      if (e is PermissionDeniedException) {
        rethrow;
      }
      dev.log('Error in getHealthMetricsForDate: $e', name: 'HealthDataSource');
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

      // ENSURE PERMISSIONS
      await _ensurePermissions(typesToCheck);

      // If specific types requested → fetch once
      if (types.isNotEmpty) {
        allPoints.addAll(await _fetchBatch(start, end, types));
      } else {
        // Otherwise use tiered strategy
        allPoints.addAll(await _fetchBatch(start, end, _tier1CoreTypes()));
        allPoints.addAll(
          await _fetchBatch(
            start, // was start.subtract(Duration(days: 90))
            end,
            _tier2BodyAndVitals(),
          ),
        );
        allPoints.addAll(
          await _fetchBatch(
            start, // was start.subtract(Duration(days: 180))
            end,
            _tier3MedicalAndNutrition(),
          ),
        );
      }

      return _mapAndDeduplicate(allPoints);
    } catch (e) {
      if (e is PermissionDeniedException) rethrow;
      dev.log('Error in getHealthMetricsRange: $e', name: 'HealthDataSource');
      if (e.toString().toLowerCase().contains('permission')) {
        throw PermissionDeniedException();
      }
      return [];
    }
  }
}
