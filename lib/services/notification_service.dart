import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // name
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
);

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    if (kDebugMode) {
      print("Background message received: ${message.messageId}");
    }

    // Handle Medicine Voice Assistant from Push
    if (message.data['type'] == 'medicine_reminder') {
      final timeStr = message.data['time'] ?? '';
      final body = message.notification?.body ?? '';
      // Body looks like: "Time to take your medicine(s): Napa, Xinc"
      final medName = body.replaceAll('Time to take your medicine(s): ', '');

      final prefs = await SharedPreferences.getInstance();
      bool useVoice = prefs.getBool('medicine_voice_assistant') ?? true;
      bool useBangla = prefs.getBool('medicine_voice_bangla') ?? true;

      if (useVoice && !kIsWeb) {
        // TTS from push notification has been removed because it overlaps with the local alarm_service TTS.
        // The alarm_service.dart handles the offline, precise TTS.
      }
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
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
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
                styleInformation: BigTextStyleInformation(notification.body ?? ''),
              ),
            ),
          );
        }

        // Handle Medicine Voice Assistant from Push
        if (message.data['type'] == 'medicine_reminder') {
          final timeStr = message.data['time'] ?? '';
          final body = message.notification?.body ?? '';
          final medName = body.replaceAll('Time to take your medicine(s): ', '');
          // TTS from push notification has been removed because it overlaps with the local alarm_service TTS.
          // The alarm_service.dart handles the offline, precise TTS.
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

  tz.TZDateTime _nextInstanceOfTime(int weekday, int hour, int minute) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleWeeklyRoutineReminder(int id, String dayOfWeek, int hour, int minute, String subject) async {
    if (kIsWeb) return;
    
    int weekday = 1;
    switch (dayOfWeek.toLowerCase()) {
      case 'monday': weekday = 1; break;
      case 'tuesday': weekday = 2; break;
      case 'wednesday': weekday = 3; break;
      case 'thursday': weekday = 4; break;
      case 'friday': weekday = 5; break;
      case 'saturday': weekday = 6; break;
      case 'sunday': weekday = 7; break;
    }

    // Target time is exactly 2 minutes before schedule
    var targetDate = _nextInstanceOfTime(weekday, hour, minute);
    targetDate = targetDate.subtract(const Duration(minutes: 2));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id + 10000, // Offset to avoid collision with other notifications
      'Get ready!',
      'Your $subject routine starts in 2 minutes!',
      targetDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    
    if (kDebugMode) {
      print("Scheduled routine #$id reminder for $dayOfWeek at $hour:$minute (ringing at ${targetDate.hour}:${targetDate.minute})");
    }
  }

  Future<void> cancelRoutineReminder(int id) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(id + 10000);
    if (kDebugMode) {
      print("Cancelled scheduled routine reminder #$id");
    }
  }
}

