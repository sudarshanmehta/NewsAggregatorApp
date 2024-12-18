import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newsaggregator/models/Article.dart';
import 'package:newsaggregator/screens/ProfilePage.dart';
import 'package:newsaggregator/services/ArticleService.dart';
import 'package:newsaggregator/services/BookmarkService.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'CategorySelectionPage.dart';

class NewsPage extends StatefulWidget {
  final BookmarkService bookmarkService = BookmarkService();
  final ArticleService articleService = ArticleService();

  NewsPage({super.key});

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Article> newsArticles = [];
  int currentIndex = 0;
  bool isMenuVisible = false;
  bool isBookmarksTabSelected = false;
  String? firebaseToken;

  // ScreenshotController for capturing the screen
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    fetchFirebaseToken();
    fetchNewsArticles();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Fetch Firebase token
  Future<void> fetchFirebaseToken() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final String? token = await currentUser.getIdToken(false);
        final String? id = currentUser.uid;
        setState(() {
          firebaseToken = token;
        });
      } else {
        print("No user is currently signed in.");
      }
    } catch (e) {
      print("Error fetching Firebase token: $e");
    }
  }

  // Fetch news articles from Firebase Firestore
  Future<void> fetchNewsArticles() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print("No user is currently signed in.");
        return;
      }

      String userId = currentUser.uid;

      // Build the userRef as a DocumentReference
      DocumentReference userRef =
      FirebaseFirestore.instance.collection('users').doc(userId);

      // Query to find the recommendation document for the current user
      QuerySnapshot recommendationQuery = await FirebaseFirestore.instance
          .collection('recommendations')
          .where('userRef', isEqualTo: userRef)
          .get();

      List<String> recommendedArticleIds = [];
      List<Article> fetchedArticles = [];

      if (recommendationQuery.docs.isNotEmpty) {
        // Extract the recommendations array from the matched document
        DocumentSnapshot userRecommendationDoc = recommendationQuery.docs.first;
        recommendedArticleIds =
        List<String>.from(userRecommendationDoc['recommendations'] ?? []);
      } else {
        print("No recommendation document found for this user.");
      }

      // Fetch all articles from the "articles" collection
      QuerySnapshot allArticlesQuery =
      await FirebaseFirestore.instance.collection('articles').get();

      fetchedArticles = allArticlesQuery.docs.map((doc) {
        return Article.fromFirestore(doc);
      }).toList();

      // Sort articles by date first (publishedAt in descending order)
      fetchedArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      // Then prioritize recommended articles to the top
      fetchedArticles.sort((a, b) {
        bool aIsRecommended = recommendedArticleIds.contains(a.articleId);
        bool bIsRecommended = recommendedArticleIds.contains(b.articleId);

        // Recommended articles appear on top
        if (aIsRecommended && !bIsRecommended) return -1;
        if (!aIsRecommended && bIsRecommended) return 1;

        // If both or neither are recommended, keep existing order
        return 0;
      });

      // Update the state with the sorted articles
      setState(() {
        newsArticles = fetchedArticles;
      });
    } catch (e) {
      print("Error fetching recommendations or articles: $e");
    }
  }

  // Fetch bookmarked articles from Firestore
  Future<void> fetchBookmarkedArticles() async {
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .get();

      List<Article> fetchedArticles = snapshot.docs.map((doc) {
        return Article.fromFirestore(doc);
      }).toList();

      setState(() {
        newsArticles = fetchedArticles;
      });
    } catch (e) {
      print("Error fetching bookmarked articles: $e");
    }
  }

  // Bookmark an article
  Future<void> bookmarkArticle(Article article, bool isRemove) async {
    if (firebaseToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token not available. Please retry.')),
      );
      return;
    }

    final result = await widget.bookmarkService.bookmarkArticle(
      article,
      firebaseToken!,
      isRemove,
    );

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isRemove ? 'Bookmark removed!' : 'Article bookmarked!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to bookmark article')),
      );
    }
  }

  // Share functionality
  Future<void> captureAndShareScreenshot() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/screenshot.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      final xFile = XFile(imagePath);
      await Share.shareXFiles([xFile], text: 'Check out this article!');
    } catch (e) {
      print("Error capturing and sharing screenshot: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share the article.')),
      );
    }
  }

  Future<void> fetchLatestArticlesFromAPI() async {
    // Replace with API call logic
    final response = await widget.articleService.fetchArticle(firebaseToken);
    if (response) {
      fetchNewsArticles();
    } else {
      print("Failed to fetch latest articles from API.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: SafeArea(
        child: Scaffold(
          body: RefreshIndicator(
            onRefresh: fetchLatestArticlesFromAPI,
            child: newsArticles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      navigateToCategoriesSelectionPage(context);
                    }
                  },
                  onTap: () {
                    setState(() {
                      isMenuVisible = true;
                    });
                  },
                  onVerticalDragEnd: (details) async {
                    if (details.primaryVelocity! > 0) {
                      await fetchLatestArticlesFromAPI();
                    }
                  },
                  child: Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.vertical,
                    onDismissed: (direction) {
                      if (direction == DismissDirection.up) {
                        loadNextArticle();
                      } else if (direction == DismissDirection.down) {
                        loadPreviousArticle();
                      }
                    },
                    child: buildNewsCard(),
                  ),
                ),
                if (isMenuVisible) buildMenuOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget buildNewsCard() {
    final article = newsArticles[currentIndex % newsArticles.length];

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: CachedNetworkImage(
                imageUrl: article.url,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.content,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildBottomBar() {
    final article = newsArticles[currentIndex % newsArticles.length];
    bool isCurrentArticleBookmarked = article.isBookmarked ?? false;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 20, // Adjust for bottom padding
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {
              toggleBookmark(article.articleId!);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrentArticleBookmarked ? Colors.blue : Colors.grey[300],
              ),
              child: Icon(
                Icons.bookmark,
                size: 24,
                color: isCurrentArticleBookmarked ? Colors.white : Colors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await captureAndShareScreenshot();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: const Icon(
                Icons.share,
                size: 24,
                color: Colors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: const Icon(
                Icons.person_2_rounded,
                size: 24,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void toggleBookmark(String articleId) {
    setState(() {
      for (var article in newsArticles) {
        if (article.articleId == articleId) {
          bool isBookmarked = article.isBookmarked ?? false;
          article.isBookmarked = !isBookmarked;

          if (!isBookmarked) {
            bookmarkArticle(article, false);
          } else {
            bookmarkArticle(article, true);
          }
          break;
        }
      }
    });
  }

  void loadNextArticle() {
    setState(() {
      currentIndex = (currentIndex + 1) % newsArticles.length;
    });
  }

  void loadPreviousArticle() {
    setState(() {
      currentIndex =
          (currentIndex - 1 + newsArticles.length) % newsArticles.length;
    });
  }

  void navigateToCategoriesSelectionPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategorySelectionPage()),
    );
  }

  Widget buildMenuOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isMenuVisible = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isBookmarksTabSelected) {
                            isBookmarksTabSelected = false;
                            fetchNewsArticles();
                          } else {
                            isBookmarksTabSelected = true;
                            fetchBookmarkedArticles();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isBookmarksTabSelected
                              ? Colors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Bookmarks",
                          style: TextStyle(
                            color: isBookmarksTabSelected
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}
