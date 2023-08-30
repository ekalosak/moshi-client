import 'package:flutter/material.dart';

final moshiTheme = ThemeData(
  fontFamily: 'Raleway',
  textTheme: moshiTextTheme,
  colorScheme: moshiColorScheme,
);

final moshiColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF087E8B),
  onPrimary: Color(0xFFF5F5F5),
  secondary: Color(0xFFD2E04B),
  onSecondary: Color(0xFF3C3C3C),
  tertiary: Color(0xFFFF8689),
  onTertiary: Color(0xFFF5F5F5),
  background: Color.fromARGB(255, 28, 28, 28),
  onBackground: Color(0xFFF5F5F5),
  error: Color(0xFFFF5A5F),
  onError: Color(0xFFF5F5F5),
  surface: Color(0xFF3C3C3C),
  onSurface: Color(0xFFF5F5F5),
);

final moshiTextTheme = TextTheme(
  displayLarge: TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    fontFamily: 'Raleway',
  ),
  displayMedium: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: 'Raleway',
  ),
  displaySmall: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'Raleway',
  ),
  bodyLarge: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.normal,
    fontFamily: 'Raleway',
  ),
  bodyMedium: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.normal,
    fontFamily: 'Raleway',
  ),
  bodySmall: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: 'Raleway',
  ),
);
