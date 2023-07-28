import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:moshi_client/services/auth.dart';
import 'package:moshi_client/widgets/langdropdown.dart';
import 'package:moshi_client/widgets/util.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

// Take language from selector, make new profile in Firebase.
//  - collection profiles
//  - document uid
Future<void> _createProfile(String uid, String name, String lang1, String lang2) async {
  DocumentReference<Map<String, dynamic>> documentReference =
      FirebaseFirestore.instance.collection('profiles').doc(uid);
  Map<String, dynamic> data = {
    'name': name,
    'lang': lang1,
    'primary_lang': lang2,
  };
  await documentReference.set(data);
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? firstLang;
  String? secondLang;

  @override
  void dispose() {
    firstNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<String?> signUp() async {
    String? err;
    String email = emailController.text;
    String password = passwordController.text;
    String name = firstNameController.text;
    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    if (name == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a name Moshi can call you.')),
      );
      return "Please provide a name Moshi can call you.";
    } else {
      setState(() {
        isLoading = true;
      });
      err = await authService.signUpWithEmailAndPassword(email, password, name);
      setState(() {
        isLoading = false;
      });
      if (err == null) {
        return err;
      }
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await _createProfile(uid, name, firstLang!, secondLang!);
      return err;
    }
  }

  @override
  Widget build(BuildContext context) {
    return withConfig(_buildScaffold);
  }

  Scaffold _buildScaffold(BuildContext context, List<String> supportedLangs) {
    DropdownButtonFormField<String> firstLangDropdown =
        languageDropdown(supportedLangs, lang: firstLang, prompt: "What's your native language?");
    DropdownButtonFormField<String> secondLangDropdown =
        languageDropdown(supportedLangs, lang: secondLang, prompt: "What language do you want to learn?");
    return Scaffold(
        appBar: AppBar(
          title: Text('Sign Up'),
        ),
        body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Stack(children: [
              if (isLoading) CircularProgressIndicator(),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Let's get started! You can always change these later, don't worry."),
                SizedBox(height: 24),
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
                firstLangDropdown,
                secondLangDropdown,
                SizedBox(height: 24),
                FloatingActionButton.extended(
                    heroTag: "signup",
                    label: Text('Sign up'),
                    icon: Icon(Icons.person_add),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: () async {
                      final String? err = await signUp();
                      if (err == null) {
                        if (mounted) {
                          context.go('/m');
                        }
                      } else {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        });
                      }
                    })
              ])
            ])));
  }
}
