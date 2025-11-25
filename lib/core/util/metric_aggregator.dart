import '../../features/bench_profile/domain/entities/health_metrics.dart';

/// Aggregates a list of HealthMetrics into a single summary metric.
///
/// This function processes a list of individual data points (e.g., multiple
/// heart rate readings or step counts from different sources) and combines them
/// into one representative HealthMetrics object.
HealthMetrics aggregateMetrics(List<HealthMetrics> metrics) {
  if (metrics.isEmpty) {
    return HealthMetrics(
      source: 'none',
      timestamp: DateTime.now(),
      steps: 0,
      heartRate: 0.0,
      weight: null,
      height: null,
      activeEnergyBurned: 0.0,
      sleepAsleep: 0.0,
      sleepAwake: 0.0,
      water: 0.0,
    );
  }

  int totalSteps = 0;
  double totalHeartRate = 0;
  int heartRateCount = 0;
  double? latestWeight;
  double? latestHeight;
  double totalEnergyBurned = 0;
  double totalSleepAsleep = 0;
  double totalSleepAwake = 0;
  double totalWater = 0;
  DateTime latestTimestamp = metrics.first.timestamp;
  final sources = <String>{};

  for (final metric in metrics) {
    totalSteps += metric.steps;
    if (metric.heartRate != null) {
      totalHeartRate += metric.heartRate!;
      heartRateCount++;
    }
    if (metric.weight != null) {
      latestWeight = metric.weight;
    }
    if (metric.height != null) {
      latestHeight = metric.height;
    }
    if (metric.activeEnergyBurned != null) {
      totalEnergyBurned += metric.activeEnergyBurned!;
    }
    if (metric.sleepAsleep != null) {
      totalSleepAsleep += metric.sleepAsleep!;
    }
    if (metric.sleepAwake != null) {
      totalSleepAwake += metric.sleepAwake!;
    }
    if (metric.water != null) {
      totalWater += metric.water!;
    }
    if (metric.timestamp.isAfter(latestTimestamp)) {
      latestTimestamp = metric.timestamp;
    }
    sources.add(metric.source);
  }

  final averageHeartRate = heartRateCount > 0 ? totalHeartRate / heartRateCount : null;
  final sourceString = sources.isEmpty ? 'unknown' : sources.join(', ');

  return HealthMetrics(
      source: sourceString,
      steps: totalSteps,
      heartRate: averageHeartRate,
      timestamp: latestTimestamp,
      weight: latestWeight,
      height: latestHeight,
      activeEnergyBurned: totalEnergyBurned,
      sleepAsleep: totalSleepAsleep,
      sleepAwake: totalSleepAwake,
      water: totalWater);
}
