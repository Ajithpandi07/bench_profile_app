// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

// // Make sure to import your dashboard page widget.
// // The path might be different in your project.
// import 'features/bench_profile/presentation/pages/dashboard_page.dart';
// import 'features/bench_profile/presentation/pages/login_page.dart'; // Assuming you have a lo

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {

//     return MaterialApp(
//       title: 'Health Tracking App',
//       // ...
//       initialRoute: '/dashboard', // Change this to your dashboard's route name
//       routes: {
//         '/login': (context) => const LoginPage(),
//         '/dashboard': (context) => const DashboardPage(),
//       },
//     );
// // ...

//   }
// }


// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:bench_profile_app/features/bench_profile/presentation/bloc/health_bloc.dart';
// import 'package:bench_profile_app/injection_container.dart' as di; // Dependency Injection
// import '/features/bench_profile/presentation/pages/dashboard_page.dart'; // Import your home page
// // import 'package:bench_profile_app/features/bench_profile/presentation/pages/home_page.dart';

// void main() {
//   // 1. Initialize your dependencies using get_it
//   di.init();

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // 2. Provide the BLoC to the entire widget tree
//     // We use BlocProvider to create and provide the HealthBloc.
//     // It uses the service locator 'di.sl()' to get the HealthBloc instance
//     // that you registered in injection_container.dart.
//     return BlocProvider(
//       create: (_) => di.sl<HealthBloc>(),
//       child: MaterialApp(
//         title: 'Bench Profile App',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//         ),
//         home: const DashboardPage(), // Your initial route
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import Firebase Core
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package.dart'; // Your other imports (HomePage, etc.)
import 'package:bench_profile_app/features/bench_profile/presentation/bloc/health_bloc.dart';
import '/features/bench_profile/presentation/pages/dashboard_page.dart'; // Import your home page
import 'package:bench_profile_app/injection_container.dart' as di;

// 2. Make your main function async
void main() async {
  // 3. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Initialize Firebase and wait for it to complete
  await Firebase.initializeApp();

  // 5. Now, initialize your dependencies
  di.init();

  // 6. Finally, run your app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<HealthBloc>(),
      child: MaterialApp(
        title: 'Bench Profile App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const DashboardPage(), // Replace with your actual home page widget
      ),
    );
  }
}

