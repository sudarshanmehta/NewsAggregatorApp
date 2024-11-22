import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newsaggregator/screens/LoginScreen.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;
  Map<String, dynamic>? notificationSettings;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  // Fetch user email and notification settings
  Future<void> fetchUserDetails() async {
    try {
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        setState(() {
          notificationSettings = Map<String, dynamic>.from(
              userDoc['notificationSettings'] ?? {});
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  // Toggle notification settings
  Future<void> updateNotificationSetting(String key, bool value) async {
    if (currentUser == null) return;

    try {
      setState(() {
        notificationSettings![key] = value;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'notificationSettings.$key': value});
    } catch (e) {
      print("Error updating notification settings: $e");
    }
  }

  // Log out the user
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false, // This clears all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold, // Makes the text bold
              fontSize: 20,               // Optional: Adjust font size
            ),
          ),
        ),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: currentUser == null || notificationSettings == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Email
            Text(
              "Email: ${currentUser!.email}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Notification Settings
            const Text(
              "Notification Settings",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: notificationSettings!.keys.length,
                itemBuilder: (context, index) {
                  String key = notificationSettings!.keys.elementAt(index);
                  bool value = notificationSettings![key] ?? false;

                  return SwitchListTile(
                    title: Text(key),
                    value: value,
                    onChanged: (newValue) {
                      updateNotificationSetting(key, newValue);
                    },
                  );
                },
              ),
            ),
            const Spacer(),
            // Logout Button
            Center(
              child: ElevatedButton(
                onPressed: () async{
                  await logout(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  "Log Out",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
