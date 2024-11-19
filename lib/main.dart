import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:newsaggregator/screens/LoginScreen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options:
  DefaultFirebaseOptions.currentPlatform);
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