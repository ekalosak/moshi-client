import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth.dart';
import 'screens/home.dart';
import 'screens/main/main.dart';
import 'screens/auth/login.dart';
import 'screens/auth/sign_up.dart';
import 'screens/auth/password_reset.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'm',
          builder: (BuildContext context, GoRouterState state) {
            return MainScreen();
          },
        ),
        GoRoute(
          path: 'a',
          builder: (BuildContext context, GoRouterState state) {
            return LoginScreen();
          },
        ),
        GoRoute(
          path: 'a/signup',
          builder: (BuildContext context, GoRouterState state) {
            return SignUpScreen();
          },
        ),
        GoRoute(
          path: 'a/reset',
          builder: (BuildContext context, GoRouterState state) {
            return PasswordResetScreen();
          },
        ),
      ],
    ),
  ],
);
