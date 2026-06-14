import 'dart:convert';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return;
    await AndroidAlarmManager.initialize();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  /// Schedules alarms for multiple medicines.
  /// Expects medicinesData to have 'name', 'duration_days', 'interval_days', and time fields 'morning_time', 'afternoon_time', 'night_time'.
  static Future<void> scheduleMedicineAlarms(List<Map<String, dynamic>> medicinesData) async {
    if (kIsWeb) return;

    bool isBangla = false;
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      if (timeZone.identifier.contains('Dhaka') || DateTime.now().timeZoneOffset.inHours == 6) {
        isBangla = true;
      }
    } catch (e) {
      if (DateTime.now().timeZoneOffset.inHours == 6) {
        isBangla = true;
      }
    }

    for (var med in medicinesData) {
      final name = med['name'] ?? 'Medicine';
      final duration = int.tryParse(med['duration_days']?.toString() ?? '1') ?? 1;
      final interval = int.tryParse(med['interval_days']?.toString() ?? '1') ?? 1;

      final times = [
        if (med['morning_time'] != null) med['morning_time'] as String,
        if (med['afternoon_time'] != null) med['afternoon_time'] as String,
        if (med['night_time'] != null) med['night_time'] as String,
      ];

      for (var timeStr in times) {
        // timeStr is usually like "08:00 AM" or "08:00:00"
        DateTime? parsedTime;
        try {
          if (timeStr.contains('AM') || timeStr.contains('PM')) {
            parsedTime = DateFormat('hh:mm a').parse(timeStr);
          } else {
            // It could be 'HH:mm:ss' from database or 'HH:mm' from local form
            if (timeStr.split(':').length == 2) {
              parsedTime = DateFormat('HH:mm').parse(timeStr);
            } else {
              parsedTime = DateFormat('HH:mm:ss').parse(timeStr);
            }
          }
        } catch (e) {
          if (kDebugMode) print('Failed to parse time $timeStr: $e');
          continue;
        }

        final now = DateTime.now();
        // Base time for today
        DateTime baseDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
          parsedTime.minute,
        );

        // Calculate schedule for the given duration and interval
        for (int dayOffset = 0; dayOffset < duration; dayOffset += interval) {
          DateTime scheduleTime = baseDateTime.add(Duration(days: dayOffset));
          // Schedule at the exact time
          DateTime alarmTime = scheduleTime;

          if (alarmTime.isAfter(now.subtract(const Duration(minutes: 1)))) {
            // Generate a unique ID for this specific alarm using medicine ID, time, and day offset
            final uniqueStr = '${med['id']}_${timeStr}_$dayOffset';
            final alarmId = uniqueStr.hashCode.abs() % 2147483647;
            
            if (kDebugMode) {
              print('Scheduling medicine alarm ID: $alarmId for $alarmTime (Medicine: $name)');
            }

            await AndroidAlarmManager.oneShotAt(
              alarmTime,
              alarmId,
              playAlarm,
              exact: true,
              wakeup: true,
              rescheduleOnReboot: true,
              params: {
                'medName': name, 
                'timeStr': DateFormat('hh:mm a').format(scheduleTime),
                'isBangla': isBangla
              },
            );
          } else {
            if (kDebugMode) {
              print('Skipped scheduling alarm for past time: $alarmTime (now: $now)');
            }
          }
        }
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> playAlarm(int id, Map<String, dynamic> params) async {
    WidgetsFlutterBinding.ensureInitialized();
    final medName = params['medName'] ?? 'Medicine';
    final timeStr = params['timeStr'] ?? '';
    final isBangla = params['isBangla'] == true;

    if (kDebugMode) {
      print('playAlarm triggered for ID $id! Medicine: $medName, Time: $timeStr');
    }

    // Initialize notifications plugin in this background isolate
    final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await notificationsPlugin.initialize(initSettings);

    final title = isBangla ? 'ঔষধ খাওয়ার সময়!' : 'Medicine Time!';
    final body = isBangla ? 'এখন $medName খাওয়ার সময় ($timeStr)' : 'It is time to take $medName ($timeStr)';

    // 1. Show Notification
    const androidDetails = AndroidNotificationDetails(
      'medicine_alarm_channel',
      'Medicine Alarms',
      importance: Importance.max,
      priority: Priority.high,
      channelDescription: 'Alarm for medicines',
    );
    const platformDetails = NotificationDetails(android: androidDetails);
    await notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );

    // 2. Play TTS
    final flutterTts = FlutterTts();
    await flutterTts.awaitSpeakCompletion(true); // VERY IMPORTANT: Wait for TTS to finish before isolate dies
    if (isBangla) {
      await flutterTts.setLanguage("bn-BD");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak("আপনার $medName খাওয়ার সময় হয়েছে।");
    } else {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak("It is time to take your $medName.");
    }
  }
}
