import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:newsaggregator/screens/CategorySelectionPage.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  // Function to get Firebase ID token
  Future<String?> getIdToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? idToken = await user.getIdToken();
      return idToken;
    }
    return null;
  }

  // Google Sign-In function
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      // Get the ID token after successful login
      String? idToken = await getIdToken();
      if (idToken != null) {
        // Navigate to the LandingPage passing the ID Token
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategorySelectionPage(token: idToken),
          ),
        );
      }

      return user;
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      return null;
    }
  }

  // Function for Email and Password sign-in
  Future<User?> signInWithEmailPassword(String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      // Get the ID token after successful login
      String? idToken = await getIdToken();
      if (idToken != null) {
        // Navigate to the LandingPage passing the ID Token
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategorySelectionPage(token: idToken),
          ),
        );
      }

      return user;
    } catch (e) {
      debugPrint('Error during Email/Password Sign-In: $e');
      return null;
    }
  }

  // Email/Password sign-in form fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // App title
              Text(
                'News Aggregator',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 40),

              // Email & Password form
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Email/Password Login Button
              ElevatedButton(
                onPressed: () async {
                  String email = emailController.text.trim();
                  String password = passwordController.text.trim();
                  User? user = await signInWithEmailPassword(email, password, context);
                  if (user != null) {
                    debugPrint("Signed in as: ${user.displayName}");
                  } else {
                    debugPrint("Email/Password Sign-In failed.");
                  }
                },
                child: const Text('Login with Email'),
              ),
              const SizedBox(height: 20),

              // Google Sign-In Button
              ElevatedButton.icon(
                onPressed: () async {
                  User? user = await signInWithGoogle(context);
                  if (user != null) {
                    debugPrint("Signed in as: ${user.displayName}");
                  } else {
                    debugPrint("Google Sign-In canceled or failed.");
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
