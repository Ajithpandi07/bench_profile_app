// lib/core/routing/app_router.dart
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import '../../features/bench_profile/presentation/bloc/health_bloc.dart';
// import '../../features/bench_profile/presentation/pages/health_page.dart';
// import '../../injection_container.dart';

// final router = GoRouter(
//   routes: [
//     GoRoute(
//       path: '/',
//       builder: (context, state) => BlocProvider(
//         create: (_) => sl<HealthBloc>()..add(FetchHealthRequested()),
//         child: const HealthPage(),
//       ),
//     ),
//     // Define other routes here
//   ],
// );
