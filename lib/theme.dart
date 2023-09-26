import 'package:flutter/material.dart';

final moshiTheme = ThemeData(
  fontFamily: 'Plex',
  textTheme: moshiTextTheme,
  colorScheme: moshiColorScheme,
);

final moshiColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color.fromARGB(255, 12, 185, 204),
  onPrimary: Color(0xFF3C3C3C),
  // secondary: Color(0xFFD2E04B),
  secondary: Color.fromARGB(255, 245, 103, 148),
  onSecondary: Color(0xFF3C3C3C),
  // tertiary: Color.fromARGB(255, 172, 238, 57),
  tertiary: Color.fromARGB(255, 248, 35, 102),
  onTertiary: Color.fromARGB(255, 28, 28, 28),
  background: Color.fromARGB(255, 28, 28, 28),
  onBackground: Color(0xFFF5F5F5),
  error: Color.fromARGB(255, 252, 81, 8),
  onError: Color(0xFFF5F5F5),
  surface: Color(0xFF3C3C3C),
  onSurface: Color(0xFFF5F5F5),
);

final moshiTextTheme = TextTheme(
  displayLarge: TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    fontFamily: 'Rubik',
    color: moshiColorScheme.primary,
  ),
  displayMedium: TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    fontFamily: 'Rubik',
    color: moshiColorScheme.primary,
  ),
  displaySmall: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: 'Rubik',
    color: moshiColorScheme.primary,
  ),
  headlineLarge: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: 'Rubik',
    color: moshiColorScheme.secondary,
  ),
  headlineMedium: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    fontFamily: 'Rubik',
    color: moshiColorScheme.secondary,
  ),
  headlineSmall: TextStyle(
    fontSize: 24,
    fontFamily: 'Rubik',
    color: moshiColorScheme.onSurface,
  ),
  bodyLarge: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.normal,
    fontFamily: 'Plex',
    color: moshiColorScheme.onSurface,
  ),
  bodyMedium: TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.normal,
    fontFamily: 'Plex',
    color: moshiColorScheme.onSurface,
  ),
  bodySmall: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    fontFamily: 'Plex',
    color: moshiColorScheme.onSurface,
  ),
);
