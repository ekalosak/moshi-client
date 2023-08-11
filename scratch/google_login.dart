import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _currentUser;

  AuthService() {
    _firebaseAuth.authStateChanges().listen((user) {
      _currentUser = user;
    });
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _currentUser;

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print('Sign in with Google failed: $e');
      // Handle the sign-in failure as desired
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
    } catch (e) {
      print('Sign out failed: $e');
      // Handle the sign-out failure as desired
    }
  }
}
