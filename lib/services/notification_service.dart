import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // name
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
);

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    if (kDebugMode) {
      print("Background message received: ${message.messageId}");
    }
  } catch (e) {
    if (kDebugMode) {
      print("Background message init error: $e");
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    try {
      final fcm = _fcm;
      if (fcm == null) {
        if (kDebugMode) {
          print("FirebaseMessaging instance not available.");
        }
        return;
      }

      // 1. Request notification permission
      NotificationSettings settings = await fcm.requestPermission(
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

      // Initialize local notifications
      if (!kIsWeb) {
        const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
        await flutterLocalNotificationsPlugin.initialize(initializationSettings);

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // 2. Set background message handler
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }

      // 3. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Foreground message received: ${message.notification?.title}');
        }
        
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null && !kIsWeb) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
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
      final fcm = _fcm;
      if (fcm == null) {
        if (kDebugMode) {
          print("Skipping token sync: FirebaseMessaging not initialized.");
        }
        return;
      }

      // Check if user is logged in
      final token = await ApiService().getToken();
      if (token == null) return; // Not logged in yet, skip syncing

      String? fcmToken = await fcm.getToken();
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

