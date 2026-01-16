import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import '../core/core.dart';
import '../features/auth/auth.dart';
import '../core/navigation/navigator_key.dart';

class BenchApp extends StatelessWidget {
  const BenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeService.mode and rebuild MaterialApp when it changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          useInheritedMediaQuery: true, // Required for DevicePreview
          locale: DevicePreview.locale(context), // Use DevicePreview locale
          builder: DevicePreview.appBuilder, // Use DevicePreview builder
          debugShowCheckedModeBanner: false,
          title: 'Bench Profile',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          navigatorKey: navigatorKey,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
