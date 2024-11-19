import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:newsaggregator/services/NotificationService.dart';
import 'package:newsaggregator/utils/RouteConfig.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  // Controllers for email and password inputs
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Function to handle Google Sign-In
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("Google Sign-In canceled by user.");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Route user based on their preferences
      _navigateToNextScreen(context);
    } catch (e) {
      debugPrint("Error during Google Sign-In: $e");
      _showErrorSnackbar(context, "Google Sign-In failed. Please try again.");
    }
  }

  // Function to handle Email/Password Sign-In
  Future<void> signInWithEmailPassword(BuildContext context) async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackbar(context, "Email and Password cannot be empty.");
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Route user based on their preferences
      _navigateToNextScreen(context);
    } catch (e) {
      debugPrint("Error during Email/Password Sign-In: $e");
      _showErrorSnackbar(context, "Email/Password Sign-In failed. Please try again.");
    }
  }

  // Navigation to the next screen based on user preferences
  Future<void> _navigateToNextScreen(BuildContext context) async {
    NotificationService().initialize();
    initializeUserCollections(FirebaseAuth.instance.currentUser?.uid);
    final nextPage = await RouteConfig.determineInitialPage();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  void initializeUserCollections(String? userId) async {
    final userProfile = {
      "username": "",
      "preferredCategories": [], // Default empty preferences as a List
      "notificationSettings": {"breaking_news": true, "daily_summary": false},
      "createdAt": Timestamp.now(),
      "lastLogin": Timestamp.now(),
    };

    DocumentReference userDoc =
    FirebaseFirestore.instance.collection('users').doc(userId);

    DocumentSnapshot userSnapshot = await userDoc.get();
    if (!userSnapshot.exists) {
      userDoc.set(userProfile);
    }
  }

  // Show error message as a SnackBar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App title
              Text(
                'News Aggregator',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Welcome Text
              const Text(
                'Welcome back! Sign in to continue.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Email input field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 20),

              // Password input field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 20),

              // Email/Password Login Button
              ElevatedButton(
                onPressed: () => signInWithEmailPassword(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Login with Email',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              // OR Divider
              Row(
                children: [
                  Expanded(
                      child: Divider(
                        color: Colors.grey.shade400,
                        thickness: 1,
                      )),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('OR'),
                  ),
                  Expanded(
                      child: Divider(
                        color: Colors.grey.shade400,
                        thickness: 1,
                      )),
                ],
              ),
              const SizedBox(height: 20),

              // Google Sign-In Button
              ElevatedButton.icon(
                onPressed: () => signInWithGoogle(context),
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
