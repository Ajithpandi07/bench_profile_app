import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/pages/health_metrics_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.healthMetrics:
        return MaterialPageRoute(
          builder: (_) => const HealthMetricsPage(),
        );

      // Add more routes here:
      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // TODO: replace
        );

      case AppRoutes.auth:
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // TODO: replace
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
