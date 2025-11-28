import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/config/routes/app_router.dart';
// /home/support/bench_profile_app/lib/config/routes/app_router.dart
import '/config/routes/app_routes.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
import 'package:bench_profile_app/injection_container.dart' as di;

import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  di.init();

  // debug checks — remove after verification
  print('Registered GetHealthMetrics: ${di.sl.isRegistered<GetHealthMetrics>()}');
  print('Registered GetHealthMetricsForDate: ${di.sl.isRegistered<GetHealthMetricsForDate>()}');
  print('Registered HealthMetricsBloc: ${di.sl.isRegistered<HealthMetricsBloc>()}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<HealthMetricsBloc>()),
      ],
      child: MaterialApp(
        title: 'Bench Profile',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: AppRoutes.healthMetrics,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
