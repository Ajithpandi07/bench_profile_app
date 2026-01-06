import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bench_profile_app/features/hydration/data/datasources/hydration_remote_data_source.dart';

void main() {
  // Try to instantiate the implementation to see if it correctly implements the interface
  final HydrationRemoteDataSource ds = HydrationRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );

  print('Successfully instantiated ${ds.runtimeType}');
}
