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
      bloodOxygen: null,
      basalEnergyBurned: 0.0,
      flightsClimbed: 0,
      distanceWalkingRunning: 0.0,
      bodyFatPercentage: null,
      bodyMassIndex: null,
      heartRateVariabilitySdnn: null,
      bloodPressureSystolic: null,
      bloodPressureDiastolic: null,
      bloodGlucose: null,
      dietaryEnergyConsumed: 0.0,
      sleepInBed: 0.0,
      sleepDeep: 0.0,
      sleepLight: 0.0,
      sleepRem: 0.0,
      restingHeartRate: null,
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

  // New metric variables
  double totalBloodOxygen = 0;
  int bloodOxygenCount = 0;
  double totalBasalEnergy = 0;
  int totalFlightsClimbed = 0;
  double totalDistance = 0;
  double? latestBodyFat;
  double? latestBmi;
  double totalHrv = 0;
  int hrvCount = 0;
  double totalSystolic = 0;
  int systolicCount = 0;
  double totalDiastolic = 0;
  int diastolicCount = 0;
  double totalBloodGlucose = 0;
  int bloodGlucoseCount = 0;
  double totalDietaryEnergy = 0;
  double totalSleepInBed = 0;
  double totalSleepDeep = 0;
  double totalSleepLight = 0;
  double totalSleepRem = 0;
  double totalRestingHeartRate = 0;
  int restingHeartRateCount = 0;

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

    // Aggregate new metrics
    if (metric.bloodOxygen != null) {
      totalBloodOxygen += metric.bloodOxygen!;
      bloodOxygenCount++;
    }
    totalBasalEnergy += metric.basalEnergyBurned ?? 0;
    totalFlightsClimbed += metric.flightsClimbed ?? 0;
    totalDistance += metric.distanceWalkingRunning ?? 0;
    if (metric.bodyFatPercentage != null) {
      latestBodyFat = metric.bodyFatPercentage;
    }
    if (metric.bodyMassIndex != null) {
      latestBmi = metric.bodyMassIndex;
    }
    if (metric.heartRateVariabilitySdnn != null) {
      totalHrv += metric.heartRateVariabilitySdnn!;
      hrvCount++;
    }
    if (metric.bloodPressureSystolic != null) {
      totalSystolic += metric.bloodPressureSystolic!;
      systolicCount++;
    }
    if (metric.bloodPressureDiastolic != null) {
      totalDiastolic += metric.bloodPressureDiastolic!;
      diastolicCount++;
    }
    if (metric.bloodGlucose != null) {
      totalBloodGlucose += metric.bloodGlucose!;
      bloodGlucoseCount++;
    }
    totalDietaryEnergy += metric.dietaryEnergyConsumed ?? 0;
    totalSleepInBed += metric.sleepInBed ?? 0;
    totalSleepDeep += metric.sleepDeep ?? 0;
    totalSleepLight += metric.sleepLight ?? 0;
    totalSleepRem += metric.sleepRem ?? 0;
    if (metric.restingHeartRate != null) {
      totalRestingHeartRate += metric.restingHeartRate!;
      restingHeartRateCount++;
    }

    if (metric.timestamp.isAfter(latestTimestamp)) {
      latestTimestamp = metric.timestamp;
    }
    sources.add(metric.source);
  }

  final averageHeartRate = heartRateCount > 0 ? totalHeartRate / heartRateCount : null;
  final sourceString = sources.isEmpty ? 'unknown' : sources.join(', ');

  // Calculate averages for new metrics
  final averageBloodOxygen = bloodOxygenCount > 0 ? totalBloodOxygen / bloodOxygenCount : null;
  final averageHrv = hrvCount > 0 ? totalHrv / hrvCount : null;
  final averageSystolic = systolicCount > 0 ? totalSystolic / systolicCount : null;
  final averageDiastolic = diastolicCount > 0 ? totalDiastolic / diastolicCount : null;
  final averageBloodGlucose = bloodGlucoseCount > 0 ? totalBloodGlucose / bloodGlucoseCount : null;
  final averageRestingHeartRate = restingHeartRateCount > 0 ? totalRestingHeartRate / restingHeartRateCount : null;


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
      water: totalWater,
      bloodOxygen: averageBloodOxygen,
      basalEnergyBurned: totalBasalEnergy,
      flightsClimbed: totalFlightsClimbed,
      distanceWalkingRunning: totalDistance,
      bodyFatPercentage: latestBodyFat,
      bodyMassIndex: latestBmi,
      heartRateVariabilitySdnn: averageHrv,
      bloodPressureSystolic: averageSystolic,
      bloodPressureDiastolic: averageDiastolic,
      bloodGlucose: averageBloodGlucose,
      dietaryEnergyConsumed: totalDietaryEnergy,
      sleepInBed: totalSleepInBed,
      sleepDeep: totalSleepDeep,
      sleepLight: totalSleepLight,
      sleepRem: totalSleepRem,
      restingHeartRate: averageRestingHeartRate);
}
