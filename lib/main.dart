import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'screens/home.dart';
import 'screens/main/main.dart';
import 'screens/auth/login.dart';
import 'services/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

final AuthService authService = AuthService();

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return HomeScreen(authService: authService);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/m',
          builder: (BuildContext context, GoRouterState state) {
            return MainScreen(authService: authService);
          },
        ),
        GoRoute(
          path: '/a',
          builder: (BuildContext context, GoRouterState state) {
            return LoginScreen(authService: authService);
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // title: 'Moshi',
      // theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: _router,
    );
  }
}
