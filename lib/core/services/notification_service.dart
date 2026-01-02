import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        // Handle notification tap
      },
    );
  }

  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String scheduleType, // 'Daily', 'Weekly', 'Monthly', 'As needed'
  }) async {
    // If "As needed", we typically don't schedule a specific time unless the user picked one.
    // For this implementation, we assume if a date/time is passed, we schedule it.
    // If it's "As needed", maybe stick to a one-time notification or just the start date?
    // The requirement says "plan to the psh norifcation to thew user based on the reminder dates and its time".

    // Convert DateTime to TZDateTime
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);

    print('DEBUG: Scheduling Notification for ID: $id');
    print('DEBUG: Request Time: $scheduledDate');
    print('DEBUG: Local Now: $now');
    print('DEBUG: Initial ScheduledTZDate: $scheduledTZDate');

    // If scheduled date is in the past, adjust it to the future based on type
    if (scheduledTZDate.isBefore(now)) {
      if (scheduleType == 'Daily') {
        // Calculate next daily instance relative to Now
        // Start with Today + requested Time
        final tz.TZDateTime todayInstance = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          scheduledTZDate.hour,
          scheduledTZDate.minute,
        );

        if (todayInstance.isBefore(now)) {
          // If today's instance is past, schedule for tomorrow
          scheduledTZDate = todayInstance.add(const Duration(days: 1));
        } else {
          // Else schedule for today
          scheduledTZDate = todayInstance;
        }
      } else if (scheduleType == 'Weekly') {
        // Find next matching weekday
        // This simple logic just adds 7 days until future, or we can calculate math.
        // Let's stick to the loop for weekly/monthly as it's less frequent to be years behind,
        // BUT make sure we start from "Now" roughly.
        // Actually, let's keep the loop for Weekly/Monthly but log it.
        while (scheduledTZDate.isBefore(now)) {
          scheduledTZDate = scheduledTZDate.add(const Duration(days: 7));
        }
      } else if (scheduleType == 'Monthly') {
        while (scheduledTZDate.isBefore(now)) {
          scheduledTZDate = tz.TZDateTime(
              tz.local,
              scheduledTZDate.year,
              scheduledTZDate.month + 1,
              scheduledTZDate.day,
              scheduledTZDate.hour,
              scheduledTZDate.minute);
        }
      }
    }

    print('DEBUG: Final ScheduledTZDate: $scheduledTZDate');

    DateTimeComponents? matchComponent;
    if (scheduleType == 'Daily') {
      matchComponent = DateTimeComponents.time;
    } else if (scheduleType == 'Weekly') {
      matchComponent = DateTimeComponents.dayOfWeekAndTime;
    } else if (scheduleType == 'Monthly') {
      matchComponent = DateTimeComponents.dayOfMonthAndTime;
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Channel for user reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchComponent,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
