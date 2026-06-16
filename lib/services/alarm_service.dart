import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
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

    // 1. Cancel all existing medicine alarms using stored IDs
    final prefs = await SharedPreferences.getInstance();
    List<String> oldAlarmIds = prefs.getStringList('medicine_alarm_ids') ?? [];
    for (String idStr in oldAlarmIds) {
      final id = int.tryParse(idStr);
      if (id != null) {
        await AndroidAlarmManager.cancel(id);
      }
    }
    await prefs.remove('medicine_alarm_ids');

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

    Map<int, List<String>> groupedMedicines = {}; // Key: epoch milliseconds of scheduleTime

    for (var med in medicinesData) {
      final name = med['name'] ?? 'Medicine';
      
      // Calculate duration properly from start/end date if available
      int duration = 1;
      if (med['duration_days'] != null) {
        duration = int.tryParse(med['duration_days'].toString()) ?? 1;
      } else if (med['start_date'] != null && med['end_date'] != null) {
        try {
          final start = DateTime.parse(med['start_date']);
          final end = DateTime.parse(med['end_date']);
          duration = end.difference(start).inDays + 1;
        } catch (e) {
          // Ignore parse errors, fallback to 1
        }
      }
      
      final interval = int.tryParse(med['interval_days']?.toString() ?? '1') ?? 1;

      final times = [
        if (med['morning_time'] != null) med['morning_time'] as String,
        if (med['afternoon_time'] != null) med['afternoon_time'] as String,
        if (med['night_time'] != null) med['night_time'] as String,
      ];

      for (var timeStr in times) {
        DateTime? parsedTime;
        try {
          if (timeStr.contains('AM') || timeStr.contains('PM')) {
            parsedTime = DateFormat('hh:mm a').parse(timeStr);
          } else {
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
        
        // Base datetime is derived from start_date if available, else today.
        DateTime baseDateTime;
        if (med['start_date'] != null) {
          try {
             final start = DateTime.parse(med['start_date']);
             baseDateTime = DateTime(start.year, start.month, start.day, parsedTime.hour, parsedTime.minute);
          } catch(e) {
             baseDateTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
          }
        } else {
          baseDateTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
        }

        for (int dayOffset = 0; dayOffset < duration; dayOffset += interval) {
          DateTime scheduleTime = baseDateTime.add(Duration(days: dayOffset));
          // Skip if the medicine's scheduled time has already passed
          // We only schedule future occurrences
          if (scheduleTime.isAfter(now.subtract(const Duration(minutes: 5)))) {
            int key = scheduleTime.millisecondsSinceEpoch;
            if (!groupedMedicines.containsKey(key)) {
              groupedMedicines[key] = [];
            }
            groupedMedicines[key]!.add(name);
          }
        }
      }
    }

    List<String> newAlarmIds = [];

    for (var entry in groupedMedicines.entries) {
      DateTime scheduleTime = DateTime.fromMillisecondsSinceEpoch(entry.key);
      // Fire alarm exactly 5 minutes before the medicine time
      DateTime alarmTime = scheduleTime.subtract(const Duration(minutes: 5));
      List<String> names = entry.value;

      // Skip if the 5-minute early alarm time has already passed
      if (alarmTime.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
        if (kDebugMode) {
          print('Skipped grouped alarm because 5-min warning time ($alarmTime) already passed.');
        }
        continue;
      }

      final uniqueStr = 'med_group_${entry.key}';
      final alarmId = uniqueStr.hashCode.abs() % 2147483647;
      
      newAlarmIds.add(alarmId.toString());

      if (kDebugMode) {
        print('Scheduling grouped medicine alarm ID: $alarmId for $alarmTime (Medicines: ${names.join(', ')})');
      }

      await AndroidAlarmManager.oneShotAt(
        alarmTime,
        alarmId,
        playAlarm,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {
          'medName': names.join(', '), 
          'timeStr': DateFormat('hh:mm a').format(scheduleTime),
          'hour': scheduleTime.hour,
          'minute': scheduleTime.minute,
          'isBangla': isBangla
        },
      );
    }
    
    // Save the new alarm IDs so we can cancel them later
    await prefs.setStringList('medicine_alarm_ids', newAlarmIds);
  }

  @pragma('vm:entry-point')
  static Future<void> playAlarm(int id, Map<String, dynamic> params) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    
    // Create an emergency debug log in SharedPreferences
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_alarm_log', 'playAlarm started for $id at ${DateTime.now()}');
    } catch(e) {
      print('prefs error: $e');
    }

    try {
      final medName = params['medName'] ?? 'Medicine';
      final timeStr = params['timeStr'] ?? '';
      final isBangla = params['isBangla'] == true;

      if (prefs != null) {
        await prefs.setString('last_alarm_log', 'playAlarm parsing done: $medName, $timeStr');
      }

      if (kDebugMode) {
        print('playAlarm triggered for ID $id! Medicine: $medName, Time: $timeStr');
      }

      // Initialize notifications plugin in this background isolate
      final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await notificationsPlugin.initialize(initSettings);

      // STRICT TIME WINDOW CHECK: 
      // The alarm is supposed to ring EXACTLY 5 minutes before the medicine time.
      // If it rings at any other time (OS delayed it, or fired it early by bug), we ABORT!
      try {
        DateTime parsedTime = DateFormat('hh:mm a').parse(timeStr);
        DateTime now = DateTime.now();
        DateTime medicineTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
        
        int diffInMinutes = medicineTime.difference(now).inMinutes;

        // Valid window: 3 to 7 minutes before the medicine time
        if (diffInMinutes < 3 || diffInMinutes > 7) {
          if (kDebugMode) print('playAlarm aborted: Not the right time! Diff: $diffInMinutes mins. Medicine: $medicineTime, Now: $now');
          return;
        }
      } catch (e) {
        if (kDebugMode) print('Strict time check failed: $e');
      }

      final title = isBangla ? 'ঔষধ খাওয়ার সময় ৫ মিনিট পর!' : 'Medicine Time Soon!';
      final body = isBangla ? 'আপনার $timeStr এর $medName খাওয়ার সময় ৫ মিনিট পর।' : 'Take $medName in 5 mins ($timeStr)';

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
      await flutterTts.setVolume(1.0);
      
      // Give TTS engine a moment to initialize in background isolate
      await Future.delayed(const Duration(seconds: 1));

      bool useBangla = isBangla;
      if (useBangla) {
        final available = await flutterTts.isLanguageAvailable("bn-BD");
        if (available != true && available != 1) { // some versions return 1 for true
          useBangla = false;
        }
      }

      if (useBangla) {
        await flutterTts.setLanguage("bn-BD");
        await flutterTts.setSpeechRate(0.5);
        
        // Convert time to pure Bangla text words to prevent TTS from reading international format
        String spokenTime = timeStr;
        try {
          int h;
          int m;
          
          if (params['hour'] != null && params['minute'] != null) {
            h = params['hour'] as int;
            m = params['minute'] as int;
          } else {
            DateTime pt = DateFormat('hh:mm a').parse(timeStr);
            h = pt.hour;
            m = pt.minute;
          }

          String period = '';
          if (h >= 4 && h < 12) period = 'সকাল';
          else if (h >= 12 && h < 16) period = 'দুপুর';
          else if (h >= 16 && h < 18) period = 'বিকাল';
          else if (h >= 18 && h < 20) period = 'সন্ধ্যা';
          else period = 'রাত';
          
          int dh = h % 12;
          if (dh == 0) dh = 12;
          
          final Map<int, String> numWords = {
            0: 'শূন্য', 1: 'এক', 2: 'দুই', 3: 'তিন', 4: 'চার', 5: 'পাঁচ',
            6: 'ছয়', 7: 'সাত', 8: 'আট', 9: 'নয়', 10: 'দশ', 11: 'এগারো',
            12: 'বারো', 13: 'তেরো', 14: 'চোদ্দ', 15: 'পনেরো', 16: 'ষোলো',
            17: 'সতেরো', 18: 'আঠারো', 19: 'উনিশ', 20: 'বিশ', 21: 'একুশ',
            22: 'বাইশ', 23: 'তেইশ', 24: 'চব্বিশ', 25: 'পঁচিশ', 26: 'ছাব্বিশ',
            27: 'সাতাশ', 28: 'আঠাশ', 29: 'উনত্রিশ', 30: 'ত্রিশ', 31: 'একত্রিশ',
            32: 'বত্রিশ', 33: 'তেত্রিশ', 34: 'চৌত্রিশ', 35: 'পঁয়ত্রিশ',
            36: 'ছত্রিশ', 37: 'সাঁইত্রিশ', 38: 'আটত্রিশ', 39: 'উনচল্লিশ',
            40: 'চল্লিশ', 41: 'একচল্লিশ', 42: 'বিয়াল্লিশ', 43: 'তেতাল্লিশ',
            44: 'চুয়াল্লিশ', 45: 'পঁয়তাল্লিশ', 46: 'ছেচল্লিশ', 47: 'সাতচল্লিশ',
            48: 'আটচল্লিশ', 49: 'উনপঞ্চাশ', 50: 'পঞ্চাশ', 51: 'একান্ন',
            52: 'বায়ান্ন', 53: 'তিপ্পান্ন', 54: 'চুয়ান্ন', 55: 'পঞ্চান্ন',
            56: 'ছাপ্পান্ন', 57: 'সাতান্ন', 58: 'আটান্ন', 59: 'উনষাট'
          };
          
          String hStr = numWords[dh] ?? dh.toString();
          String mStr = m > 0 ? ' বেজে ${numWords[m] ?? m.toString()} মিনিট' : ' টা';
          if (m > 0) hStr += ' টা';
          
          spokenTime = '$period $hStr$mStr';
        } catch(e) {}

        await flutterTts.speak("আপনার $spokenTime এর $medName খাওয়ার সময় ৫ মিনিট পর।");
      } else {
        await flutterTts.setLanguage("en-US");
        await flutterTts.setSpeechRate(0.5);
        await flutterTts.speak("It is almost time to take your $medName in 5 minutes.");
      }
      
      if (prefs != null) {
        await prefs.setString('last_alarm_log', 'playAlarm TTS finished successfully');
      }

    } catch (e, stack) {
      if (prefs != null) {
        await prefs.setString('last_alarm_log', 'playAlarm failed: $e\n$stack');
      }
      if (kDebugMode) {
        print("playAlarm failed: $e");
        print(stack);
      }
    }
  }
}
