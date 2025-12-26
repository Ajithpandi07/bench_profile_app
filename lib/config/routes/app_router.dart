import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/pages/health_metrics_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
import 'package:bench_profile_app/core/injection_container.dart' as di;

import '../../features/auth/presentation/pages/sign_in_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.healthMetrics:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<HealthMetricsBloc>(),
            child: const HealthMetricsPage(),
          ),
        );

      // Add more routes here:
      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // TODO: replace
        );

      case AppRoutes.auth:
        return MaterialPageRoute(
          builder: (_) => const SignInPage(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Route Not Found")),
          ),
        );
    }
  }
}
