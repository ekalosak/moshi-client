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
  secondary: Color(0xFFD2E04B),
  onSecondary: Color(0xFF3C3C3C),
  tertiary: Color.fromARGB(255, 172, 238, 57),
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
    color: moshiColorScheme.secondary,
  ),
  displayMedium: TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    fontFamily: 'Rubik',
  ),
  displaySmall: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: 'Rubik',
  ),
  headlineLarge: TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    fontFamily: 'Rubik',
  ),
  headlineMedium: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: 'Rubik',
  ),
  headlineSmall: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    fontFamily: 'Rubik',
  ),
  bodyLarge: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.normal,
    fontFamily: 'Plex',
  ),
  bodyMedium: TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.normal,
    fontFamily: 'Plex',
  ),
  bodySmall: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    fontFamily: 'Plex',
  ),
);
