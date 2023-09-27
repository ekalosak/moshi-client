import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_app_check/firebase_app_check.dart';

import 'theme.dart';
import 'screens/switch.dart';

const useEmulators = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  if (kDebugMode) {
    print("DEBUG");
    String host = defaultTargetPlatform == TargetPlatform.iOS ? 'localhost' : '10.0.2.2';
    try {
      if (useEmulators) {
        print("USING LOCAL EMULATED FIRESTORE: port 8080");
        FirebaseFirestore.instance.settings = Settings(persistenceEnabled: false);
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        print("USING LOCAL EMULATED FIREBASE AUTH: port 9099");
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        print("USING LOCAL EMULATED STORAGE: port 9199");
        await FirebaseStorage.instance.useStorageEmulator(host, 9199);
        print("USING LOCAL EMULATED FUNCTIONS: port 5001");
        FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
        print("EMULATOR HOST: $host");
      } else {
        print("USING REMOTE FIREBASE AUTH");
        print("USING REMOTE FIRESTORE");
        print("USING REMOTE STORAGE");
        print("USING REMOTE FUNCTIONS");
      }
    } catch (e) {
      print(e);
    }
    // // log out user
    // print("LOGGING OUT USER");
    // await FirebaseAuth.instance.signOut();
  } else {
    print("RELEASE");
    await FirebaseAppCheck.instance.activate(
      webRecaptchaSiteKey: 'recaptcha-v3-site-key',
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatMoshi',
      theme: moshiTheme,
      home: SwitchScreen(),
    );
  }
}
