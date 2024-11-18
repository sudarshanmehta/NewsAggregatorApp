import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    subscribeToTopic();
    setupNotificationHandlers();
  }

  Future<void> subscribeToTopic() async {
    await _messaging.subscribeToTopic("news-updates");
    print("Subscribed to news-updates topic");
  }

  void setupNotificationHandlers() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Opened app via notification: ${message.notification?.title}');
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Background message received: ${message.notification?.title}');
  }
}
