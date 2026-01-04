import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A centralized place for the application's theme definitions.
///
/// This class provides static access to the light and dark [ThemeData]
/// for the application, ensuring a consistent look and feel.
class AppTheme {
  // Private constructor to prevent instantiation.
  AppTheme._();

  // The seed color that will be used to generate the color schemes.
  // Using a shade of blue as it's often associated with health and trust.
  static const primaryColor = Color(0xFFEE374D);

  static const primaryVariant = Color(0xFFA72740);
  static const primaryLight = Color.fromRGBO(226, 146, 146, 1);
  static const rippleBackground = Color(0xFFFFCED8);

  /// Defines the base text theme for the application.
  /// These styles will be adapted with appropriate colors by the ColorScheme.
  static final TextTheme _textTheme = TextTheme(
    // Example: Customizing the 'titleLarge' style used for screen titles.
    titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0),
    // Example: Customizing 'bodyMedium' for standard text.
    bodyMedium: const TextStyle(
      fontSize: 14.0,
      height: 1.5, // Line height
    ),
    // Example: Customizing 'labelLarge' for buttons.
    labelLarge: const TextStyle(
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
    // You can define other styles like headline, subtitle, caption, etc.
  );

  /// The light theme configuration for the application.
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF8F8F8),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: primaryVariant,
      brightness: Brightness.light,
    ),
    // You can add further customizations for component themes here.
    textTheme: _textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor:
          Colors.black, // or Color(0xFFEE374D) if they want red text
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    // Further component theme customizations can be added here.
  );

  /// The dark theme configuration for the application.
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: primaryVariant,
      brightness: Brightness.dark,
    ),
    // You can add further customizations for component themes here.
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    textTheme: _textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    // Further component theme customizations can be added here.
  );
}
