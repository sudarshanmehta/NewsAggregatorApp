import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:newsaggregator/utils/Config.dart';

class BookmarkService {
  Future<bool> bookmarkArticle(String articleId, String? token, bool isRemove) async {
     try {
      final response = await http.post(
        Uri.parse(isRemove ? AppConfig.removeBookmark : AppConfig.bookmark),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Firebase token
        },
        body: articleId,
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
