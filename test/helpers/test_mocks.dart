import 'package:mockito/annotations.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source.dart';
import 'package:bench_profile_app/core/network/network_info.dart';

@GenerateMocks([
  HealthMetricsDataSource,
  HealthMetricsLocalDataSource,
  HealthMetricsRemoteDataSource,
  NetworkInfo
])
void main() {}
