// lib/features/bench_profile/data/datasources/health_uploader.dart
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/health_metrics.dart';
import '../models/health_model.dart';

/// Interface for uploading health metrics. Implementations should provide the
/// concrete storage mechanism (Firestore, REST API, etc.). Keeping this as
/// an interface makes it easy to mock in tests.
abstract class FirestoreHealthSource {
  Future<void> upload(String uid, HealthModel model);
  Future<HealthMetrics?> fetchLatest(String uid);
}

/// Firestore-based implementation of [HealthUploader].
class FirestoreHealthUploader implements FirestoreHealthSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<void> upload(String uid, HealthModel model) {
    // Use the platform to determine which subcollection to write to.
    final subcollection = Platform.isAndroid ? 'healthmetricesandroid' : 'healthmetriceios';
    final ref = _db.collection('bench_profile').doc(uid).collection(subcollection);
    final data = model.toMap()..['uploadedAt'] = FieldValue.serverTimestamp();
    return ref.add(data);
  }

  @override
  Future<HealthMetrics?> fetchLatest(String uid) async {
    final subcollection = Platform.isAndroid ? 'healthmetricesandroid' : 'healthmetriceios';
    final ref = _db.collection('bench_profile').doc(uid).collection(subcollection);

    final querySnapshot = await ref
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return HealthModel.fromMap(querySnapshot.docs.first.data());
  }
}