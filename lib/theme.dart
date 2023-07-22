import 'package:flutter/material.dart';

final moshiTheme = ThemeData(
  fontFamily: 'Raleway',
  textTheme: moshiTextTheme,
  colorScheme: moshiColorScheme,
);

const Color pink = Color.fromARGB(255, 229, 183, 232);
const Color lightblue = Color.fromRGBO(149, 201, 237, 1);
const Color deepindigo = Color.fromARGB(255, 16, 24, 40);
const Color angryorange = Color.fromARGB(255, 248, 106, 11);
const Color eggshell = Color.fromRGBO(245, 244, 223, 1);
const Color warmyellow = Color.fromRGBO(248, 235, 85, 1);

final moshiColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: pink,
  onPrimary: deepindigo,
  secondary: lightblue,
  onSecondary: deepindigo,
  error: angryorange,
  onError: deepindigo,
  background: deepindigo,
  onBackground: eggshell,
  surface: deepindigo,
  onSurface: eggshell,
  tertiary: warmyellow,
  onTertiary: deepindigo,
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
    fontSize: 28,
    fontWeight: FontWeight.normal,
    fontFamily: 'Raleway',
  ),
  bodyMedium: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    fontFamily: 'Raleway',
  ),
  bodySmall: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: 'Raleway',
  ),
);
