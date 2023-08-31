import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'theme.dart';
import 'screens/home.dart';

const useRemoteFirebaseAuth = false;
const useRemoteFirestore = false;
const useRemoteStorage = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("DEBUG");
    print("MREMOTEAUTH: $useRemoteFirebaseAuth");
    print("MRMOTEFIRESTORE: $useRemoteFirestore");
    String host = defaultTargetPlatform == TargetPlatform.iOS ? 'localhost' : '10.0.2.2';
    if (!useRemoteFirebaseAuth || !useRemoteFirestore) {
      print("EMULATOR HOST: $host");
    }
    try {
      if (!useRemoteFirebaseAuth) {
        print("USING LOCAL EMULATED FIREBASE AUTH");
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      } else {
        print("USING REMOTE FIREBASE AUTH");
      }
      if (!useRemoteFirestore) {
        print("USING LOCAL EMULATED FIRESTORE");
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      } else {
        print("USING REMOTE FIRESTORE");
      }
      if (!useRemoteStorage) {
        print("USING LOCAL EMULATED STORAGE");
        FirebaseStorage.instance.useStorageEmulator(host, 9199);
      } else {
        print("USING REMOTE STORAGE");
      }
    } catch (e) {
      print(e);
    }
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
