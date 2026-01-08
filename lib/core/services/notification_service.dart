import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../navigation/navigator_key.dart';
import '../../features/meals/presentation/pages/meal_listing_page.dart';
import '../../features/hydration/presentation/pages/hydration_tracker_page.dart';
import '../../features/meals/presentation/bloc/bloc.dart';
import '../../features/hydration/presentation/bloc/bloc.dart';
import '../../core/injection_container.dart';

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
    print('DEBUG: Local Timezone set to: ${tz.local.name}');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

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
            if (notificationResponse.payload != null) {
              _handleNotificationTap(notificationResponse.payload!);
            }
          },
    );
  }

  void _handleNotificationTap(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'];
      final dateStr = data['date'];
      final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

      if (type == 'water') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => sl<HydrationBloc>(),
              child: HydrationTrackerPage(initialDate: date),
            ),
          ),
        );
      } else if (type == 'meal') {
        final mealType = data['subtype'] ?? 'Snack';
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => sl<MealBloc>()..add(LoadMealsForDate(date)),
              child: MealListingPage(mealType: mealType, initialDate: date),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      final bool? canScheduleExact = await androidImplementation
          ?.canScheduleExactNotifications();
      print('DEBUG: Can Schedule Exact Notifications: $canScheduleExact');
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String scheduleType, // 'Daily', 'Weekly', 'Monthly', 'As needed'
    String? payload,
  }) async {
    // ...
    // Note: I am NOT replacing the logic inside, just looking for the signature line and the end...
    // Wait, replace_file_content requires me to match the target content exactly.
    // The target content spans many lines. I should separate signature update and call update.
    // I will try to update signature first.

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
            scheduledTZDate.minute,
          );
        }
      }
    }

    // DEBUG: Check permission right before scheduling
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await androidImplementation
          ?.canScheduleExactNotifications();
      print('DEBUG: [scheduleReminder] Can Schedule Exact: $canExact');
    }

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
          'reminder_channel_v1',
          'Reminders',
          channelDescription: 'Channel for user reminders',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: matchComponent,
        payload: payload,
      );
      print(
        'DEBUG: Successfully called zonedSchedule for ID: $id with payload: $payload',
      );
    } catch (e, st) {
      print('ERROR: Failed to schedule notification: $e');
      print(st);
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'reminder_channel_v1',
          'Reminders',
          channelDescription: 'Channel for user reminders',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
