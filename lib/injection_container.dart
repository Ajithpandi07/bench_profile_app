// lib/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:bench_profile_app/features/bench_profile/data/datasources/health_data_source.dart';
import 'package:bench_profile_app/features/bench_profile/data/datasources/health_uploader.dart';
import 'package:bench_profile_app/features/bench_profile/data/repositories/health_repository_impl.dart';
import 'package:bench_profile_app/features/bench_profile/domain/repositories/health_repository.dart';
import 'package:bench_profile_app/features/bench_profile/domain/usecases/fetch_health_data.dart';
import 'package:bench_profile_app/features/bench_profile/domain/usecases/upload_health_data.dart';
import 'features/bench_profile/presentation/bloc/health_bloc.dart';
import 'package:bench_profile_app/health_service.dart';
// E:\Ajith\bench_profile_app\lib\features\bench_profile\presentation\bloc\health_bloc.dart

final sl = GetIt.instance;

void init() {
  // Blocs
  // sl.registerFactory(() => HealthBloc(fetchHealthData: sl(), uploadHealthData: sl()));

    // BLoC
  sl.registerFactory(
    () => HealthBloc(
      fetchHealthData: sl(),
      uploadHealthData: sl(),
    ), // get_it will find the registered usecases
  );

  // Usecases
  sl.registerLazySingleton(() => FetchHealthData(sl()));
  sl.registerLazySingleton(() => UploadHealthData(sl()));

  // Repositories
  sl.registerLazySingleton<HealthRepository>(() => HealthRepositoryImpl(healthService: sl(), uploader: sl()));

  // Data Sources
  // Register the concrete class
  sl.registerLazySingleton(() => HealthService());
  // Register the abstraction to resolve to the concrete class
  sl.registerLazySingleton<HealthDataSource>(() => sl<HealthService>());
  sl.registerLazySingleton<FirestoreHealthSource>(() => FirestoreHealthUploader());
}
