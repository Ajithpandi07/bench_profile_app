// lib/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:bench_profile_app/features/bench_profile/data/datasources/health_data_source.dart';
import 'package:bench_profile_app/features/bench_profile/data/datasources/health_uploader.dart';
import 'package:bench_profile_app/features/bench_profile/data/repositories/health_repository_impl.dart';
import 'package:bench_profile_app/features/bench_profile/domain/repositories/health_repository.dart';
import 'package:bench_profile_app/features/bench_profile/domain/usecases/fetch_health_data.dart';
import 'package:bench_profile_app/features/bench_profile/domain/usecases/upload_health_data.dart';
import 'package:bench_profile_app/features/bench_profile/presentation/bloc/health_bloc.dart';
import 'package:bench_profile_app/health_service.dart';

final sl = GetIt.instance;

void init() {
  // Blocs
  sl.registerFactory(() => HealthBloc(fetchHealthData: sl(), uploadHealthData: sl()));

  // Usecases
  sl.registerLazySingleton(() => FetchHealthData(sl()));
  sl.registerLazySingleton(() => UploadHealthData(sl()));

  // Repositories
  sl.registerLazySingleton<HealthRepository>(() => HealthRepositoryImpl(healthService: sl(), uploader: sl()));

  // Data Sources
  sl.registerLazySingleton<HealthDataSource>(() => HealthService());
  sl.registerLazySingleton<FirestoreHealthSource>(() => FirestoreHealthUploader());
}
