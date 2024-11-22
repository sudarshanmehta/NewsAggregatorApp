import 'dart:convert';

import 'package:http/http.dart' as http;
import '../utils/Config.dart';

class ArticleService {

  Future<bool> fetchArticle(String? token) async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.fetchArticles),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Firebase token
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result == true;
      } else {
        throw Exception('Failed to bookmark article: ${response.statusCode}');
      }
    } catch (e) {
      print('Error bookmarking article: $e');
      return false;
    }
  }

}