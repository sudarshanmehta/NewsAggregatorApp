import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:newsaggregator/screens/LoginScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
  await Firebase.initializeApp(
    name: 'NewsAggregator',
    options: FirebaseOptions(
      apiKey: "AIzaSyDcJTWXtu0W35LsnZTTzqgCynjmZLE2iIU",
      authDomain: "news-aggregator-a4193.firebaseapp.com",
      projectId: "news-aggregator-a4193",
      storageBucket: "news-aggregator-a4193.firebasestorage.app",
      messagingSenderId: "345943993270",
      appId: "1:345943993270:web:9cffbbef1b06edbe446f17",
      measurementId: "G-QY17KTC0L4",
    ),
  );
  }else{
    await Firebase.initializeApp();
  }
  runApp(const NewsAggregatorApp());
}
class NewsAggregatorApp extends StatelessWidget {
  const NewsAggregatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Aggregator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginScreen(),
    );
  }
}