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

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
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

    // Get user document reference
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    // Check if the user document exists
    DocumentSnapshot userSnapshot = await userDoc.get();
    if (!userSnapshot.exists) {
      // Set user profile if not exists
      userDoc.set(userProfile);
    }

    // Check if the bookmarks subcollection exists
    CollectionReference bookmarksCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection("bookmarks");
    QuerySnapshot bookmarksSnapshot = await bookmarksCollection.get();
    if (bookmarksSnapshot.docs.isEmpty) {
      // Initialize bookmarks if not exists
      bookmarksCollection.doc("defaultBookmark").set({
        "createdAt": Timestamp.now(),
      });
    }

    // Check if the recommendations document exists
    DocumentReference recommendationsDoc = FirebaseFirestore.instance.collection("recommendations").doc(userId);
    DocumentSnapshot recommendationsSnapshot = await recommendationsDoc.get();
    if (!recommendationsSnapshot.exists) {
      // Initialize recommendations document if not exists
      recommendationsDoc.set({
        "userRef": FirebaseFirestore.instance.collection('users').doc(userId),
        "recommendedArticles": [], // Empty List for recommendations
        "generatedAt": Timestamp.now(),
      });
    }

    // Check if the notifications collection exists
    CollectionReference notificationsCollection = FirebaseFirestore.instance.collection("notifications");
    QuerySnapshot notificationsSnapshot = await notificationsCollection.get();
    if (notificationsSnapshot.docs.isEmpty) {
      // Initialize notifications if not exists
      notificationsCollection.doc(userId).set({
        "title": "Welcome!",
        "content": "Welcome to our platform!",
        "category": "welcome",
        "sentAt": Timestamp.now(),
        "status": "unread",
      });
    }
  }


  // Show error message as a SnackBar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

              // Email input field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Password input field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Email/Password Login Button
              ElevatedButton(
                onPressed: () => signInWithEmailPassword(context),
                child: const Text('Login with Email'),
              ),
              const SizedBox(height: 20),

              // Google Sign-In Button
              ElevatedButton.icon(
                onPressed: () => signInWithGoogle(context),
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
