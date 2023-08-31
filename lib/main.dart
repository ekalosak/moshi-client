import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moshi/firebase_options.dart';

import 'theme.dart';
import 'screens/home.dart';

const useEmulators = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    print("DEBUG");
    String host = defaultTargetPlatform == TargetPlatform.iOS ? 'localhost' : '10.0.2.2';
    try {
      if (useEmulators) {
        print("USING LOCAL EMULATED FIRESTORE: port 8080");
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
    // await FirebaseAuth.instance.signOut();
  } else {
    print("RELEASE");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moshi',
      theme: moshiTheme,
      home: HomeScreen(),
    );
  }
}
