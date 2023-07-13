import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth.dart';
import 'screens/home.dart';
import 'screens/main/main.dart';
import 'screens/auth/login.dart';

final AuthService authService = AuthService();

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return HomeScreen(authService: authService);
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'm',
          builder: (BuildContext context, GoRouterState state) {
            return MainScreen(authService: authService);
          },
        ),
        GoRoute(
          path: 'a',
          builder: (BuildContext context, GoRouterState state) {
            return LoginScreen(authService: authService);
          },
        ),
      ],
    ),
  ],
);
