import 'package:flutter/material.dart';
import '../main/main.dart';
import '../../services/auth.dart';

class SignUpScreen extends StatefulWidget {
  final AuthService authService;

  SignUpScreen({required this.authService});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService;
  }

  Future<void> signUp(BuildContext context) async {
    String email = emailController.text;
    String password = passwordController.text;
    String name = firstNameController.text;
    if (name == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a name Moshi can call you.')),
      );
    } else {
      setState(() {
        isLoading = true;
      });
      final String? authToken = await _authService.signUpWithEmailAndPassword(
        email,
        password,
        name,
        context,
      );
      setState(() {
        isLoading = false;
      });

      if (authToken != null) {
        print("Signup succeded!");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(authService: _authService)),
          (route) => false, // Removes all the previous routes from the stack
        );
      } else {
        print("Signup failed.");  // NOTE authService handles the popups for user
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Sign Up'),
              onPressed: isLoading ? null : () => signUp(context),
              style: ButtonStyle(
                // Set button color to grey when disabled
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey;
                    }
                    return Theme.of(context).primaryColor;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
