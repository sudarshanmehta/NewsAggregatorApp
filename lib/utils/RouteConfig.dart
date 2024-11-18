import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/CategorySelectionPage.dart';
import '../screens/NewsPage.dart';

class RouteConfig {
  static Future<Widget> determineInitialPage() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const CategorySelectionPage(); // Handle unauthenticated state
    }

    try {
      final docSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final data = docSnapshot.data();

      if (data != null &&
          data['preferredCategories'] != null &&
          (data['preferredCategories'] as List).isNotEmpty) {
        // If preferences exist, return NewsPage
        return NewsPage();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }

    // Default to CategorySelectionPage if preferences are not set
    return const CategorySelectionPage();
  }
}
