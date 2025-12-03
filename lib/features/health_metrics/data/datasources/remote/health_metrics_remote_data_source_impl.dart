import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';

class HealthMetricsRemoteDataSourceImpl implements HealthMetricsRemoteDataSource {
  final FirebaseFirestore firestore;

  HealthMetricsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> uploadHealthMetrics(HealthMetrics metrics) async {
    final collection = firestore.collection('health_metrics');
    final docId = metrics.timestamp.toIso8601String().substring(0, 10); // YYYY-MM-DD

    // You would create a toMap() method in your HealthMetrics entity
    final map = {
      'timestamp': metrics.timestamp,
      'source': metrics.source,
      'steps': metrics.steps,
      'heartRate': metrics.heartRate,
      'weight': metrics.weight,
      'height': metrics.height,
      'activeEnergyBurned': metrics.activeEnergyBurned,
      'sleepAsleep': metrics.sleepAsleep,
      'sleepAwake': metrics.sleepAwake,
      'water': metrics.water,
      'bloodOxygen': metrics.bloodOxygen,
      'basalEnergyBurned': metrics.basalEnergyBurned,
      'flightsClimbed': metrics.flightsClimbed,
      // ... add all other fields
    };

    // Use set with merge:true to create or update the document.
    await collection.doc(docId).set(map, SetOptions(merge: true));
  }
}