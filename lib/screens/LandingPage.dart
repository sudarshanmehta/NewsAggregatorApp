import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newsaggregator/utils/Config.dart';

class LandingPage extends StatefulWidget {
  final String token; // Firebase ID Token passed from the Login screen

  const LandingPage({super.key, required this.token});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String? backendData = 'Loading...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Call the backend API as soon as the landing page is loaded
    fetchDataFromBackend();
  }

  Future<void> fetchDataFromBackend() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.userInfoEndpoint),
        headers: {
          'Authorization': 'Bearer ${widget.token}', // Pass the token from the LoginScreen
        },
      );

      if (response.statusCode == 200) {
        print('Response: ${response.body}');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during API request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landing Page'),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator() // Show a loading spinner while waiting for the response
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Backend Response:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                backendData ?? 'No data received',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
