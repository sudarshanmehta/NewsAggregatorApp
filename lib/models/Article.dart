import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String? articleId; // Nullable for new documents
  final String title;
  final String content;
  final String url;
  final String category;
  final String sentiment;
  final Timestamp publishedAt;
  bool? isBookmarked;

  Article({
    this.articleId,
    required this.title,
    required this.content,
    required this.url,
    required this.category,
    required this.sentiment,
    required this.publishedAt,
    required this.isBookmarked,
  });

  // Factory constructor to create an Article instance from Firestore
  factory Article.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Article(
      articleId: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      url: data['url'] ?? '',
      category: data['category'] ?? '',
      sentiment: data['sentiment'] ?? '',
      publishedAt: data['published_at'] ?? Timestamp.now(),
      isBookmarked: data['isBookmarked']
    );
  }

  // Method to convert an Article instance into a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'articleId' : articleId,
      'title': title,
      'content': content,
      'url': url,
      'category': category,
      'sentiment': sentiment,
      'published_at': publishedAt,
      'isBookmarked' : isBookmarked,
    };
  }

  Map<String, dynamic> toJson() => {
    'articleId' : articleId,
    'title': title,
    'content': content,
    'url': url,
    'category': category,
    'sentiment': sentiment,
    'published_at': publishedAt.toDate().toIso8601String(),
    'isBookmarked' : isBookmarked,
  };
}
