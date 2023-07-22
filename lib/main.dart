import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'routes.dart';
import 'services/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final authService = AuthService();
  runApp(
    AuthServiceProvider(
      authService: authService,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Moshi',
      theme: ThemeData(
        fontFamily: 'Raleway',
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF69420d),  // dark brown
          onPrimary: Color(0xFFf5f4df),  // eggshell
          secondary: Color(0xFFec96c3),  // light pink
          onSecondary: Color(0xFF69420d),  // dark brown
          error: Color(0xFFdf3215),  // strawberry red
          onError: Color(0xFF95c9ed),  // light blue
          background: Color(0xFF69420d),  // dark brown
          onBackground: Color(0xFFf5f4df),  // eggshell
          surface: Color(0xFF69420d),
          onSurface: Color(0xFFf5f4df),
          // tertiary: Color(0x95c0ed),
        ),
        textTheme: TextTheme(
          headline1: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: 'Raleway',
          ),
        )
        // colorScheme: ColorScheme.fromSwatch(
        //   primarySwatch: Colors.deepPurple,
        // )
        // #69420d brown
        // #da95df light pink
        // #95c9ed light blue  ## PRIMARY: #2f76bc
        // #ec96c3 light pink triadic to light blue
      ),
      routerConfig: router,
    );
  }
}
