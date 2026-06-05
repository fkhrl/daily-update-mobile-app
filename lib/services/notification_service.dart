import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Background message received: ${message.messageId}");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      // 1. Request notification permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Foreground message received: ${message.notification?.title}');
        }
        // You could trigger a local notification package here to show a banner in foreground
      });

      // 4. Handle notification clicks when app is opened from a terminated or background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Notification clicked, app opened: ${message.data}');
        }
      });

      // 5. Get and save FCM Token to API
      await syncFcmToken();
    } catch (e) {
      if (kDebugMode) {
        print("Firebase initialization error: $e");
      }
    }
  }

  Future<void> syncFcmToken() async {
    try {
      // Check if user is logged in
      final token = await ApiService().getToken();
      if (token == null) return; // Not logged in yet, skip syncing

      String? fcmToken = await _fcm.getToken();
      if (fcmToken != null) {
        if (kDebugMode) {
          print("FCM Token retrieved: $fcmToken");
        }
        // Save to Laravel backend
        await ApiService().saveFcmToken(fcmToken);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error syncing FCM Token: $e");
      }
    }
  }
}
