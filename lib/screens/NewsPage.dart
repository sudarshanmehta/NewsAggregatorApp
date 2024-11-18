import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newsaggregator/services/BookmarkService.dart';
import 'CategorySelectionPage.dart';

class NewsPage extends StatefulWidget {
  final BookmarkService bookmarkService = BookmarkService();

  NewsPage({super.key});

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Map<String, String>> newsArticles = [];
  int currentIndex = 0;
  bool isMenuVisible = false;
  bool isBookmarksTabSelected = false;
  String? firebaseToken; // Firebase token stored here

  @override
  void initState() {
    super.initState();
    fetchFirebaseToken();
    fetchNewsArticles();
  }

  // Fetch Firebase token
  Future<void> fetchFirebaseToken() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final String? token = await currentUser.getIdToken(false);
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
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('articles').get();
      List<Map<String, String>> fetchedArticles = [];
      for (var doc in snapshot.docs) {
        Map<String, String> articleData = {
          'articleId': doc.id,
          'title': doc['title'] ?? 'No Title',
          'description': doc['description'] ?? 'No Description',
          'imageUrl': doc['image_url'] ?? '',
        };
        fetchedArticles.add(articleData);
      }

      setState(() {
        newsArticles = fetchedArticles;
      });
    } catch (e) {
      print("Error fetching articles: $e");
    }
  }

  // Fetch bookmarked articles from Firestore
  Future<void> fetchBookmarkedArticles() async {
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the list of bookmarked article references
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .get();

      // Extract the article references
      List<String> bookmarkedArticleRefs = snapshot.docs
          .map((doc) => doc.get('articleRef') as String)
          .toList();

      // Filter the `newsArticles` list based on the article references
      List<Map<String, String>> filteredArticles = newsArticles
          .where((article) => bookmarkedArticleRefs.contains(article['articleId']))
          .toList();

      // Update the state with filtered articles
      setState(() {
        newsArticles = filteredArticles;
      });
    } catch (e) {
      print("Error fetching bookmarked articles: $e");
    }
  }


  // Bookmark an article using the BookmarkService
  Future<void> bookmarkArticle(String articleId, bool isRemove) async {
    if (firebaseToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token not available. Please retry.')),
      );
      return;
    }

    final result = await widget.bookmarkService.bookmarkArticle(
      articleId,
      firebaseToken!,
      isRemove
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: newsArticles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                navigateToCategoriesSelectionPage(context);
              }
            },
            onTap: () {
              setState(() {
                isMenuVisible = true;
              });
            },
            child: Dismissible(
              key: ValueKey<int>(currentIndex),
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
    );
  }

  Widget buildNewsCard() {
    return Card(
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
              imageUrl: newsArticles[currentIndex]['imageUrl']!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
              const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsArticles[currentIndex]['title']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  newsArticles[currentIndex]['description']!,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
              // Updated Tab Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Bookmarks Tab
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
                    const SizedBox(width: 10), // Spacing between tabs

                    // Other Tab Example: Daily Roundups (Static for now)
                    GestureDetector(
                      onTap: () {
                        // Add functionality for Daily Roundups if needed
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Daily Roundups",
                          style: TextStyle(
                            color: Colors.grey,
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

              // Bottom Bar
              buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildBottomBar() {
    bool isCurrentArticleBookmarked = newsArticles[currentIndex]['isBookmarked'] == 'true';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Bookmark Button
          GestureDetector(
            onTap: () {
              toggleBookmark(newsArticles[currentIndex]['articleId']!);
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

          // Share Button
          GestureDetector(
            onTap: () {
              // Add share logic here
              print("Share button pressed");
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
        ],
      ),
    );
  }

  void toggleBookmark(String articleId) {
    setState(() {
      // Find the article and toggle its bookmark state
      for (var article in newsArticles) {
        if (article['articleId'] == articleId) {
          bool isBookmarked = article['isBookmarked'] == 'true';
          article['isBookmarked'] = (!isBookmarked).toString();

          // Optionally: Call the bookmark API here to persist the change
          if (!isBookmarked) {
            bookmarkArticle(articleId, false);
          } else {
            bookmarkArticle(articleId, true);
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
}
