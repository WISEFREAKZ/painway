import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Handles ALL local, on-device notification scheduling.
///
/// Nothing here ever touches a server — every reminder is scheduled by
/// the OS's own alarm manager via `flutter_local_notifications`, which is
/// what keeps this app's backend costs at zero forever.
///
/// Notification ID ranges (kept distinct so cancel/reschedule never clash):
///   100–199 : water reminders (one id per scheduled time-of-day slot)
///   200     : daily stretching reminder
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _waterIdRangeStart = 100;
  static const int _stretchId = 200;

  bool _initialized = false;

  /// Must be called once, early in `main()`, before any scheduling calls.
  Future<void> init() async {
    if (_initialized) return;

    // Sets up the timezone database so `tz.TZDateTime` reflects the
    // device's real local time (required for accurate daily alarms).
    tz_data.initializeTimeZones();
    final String localTimeZone = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (_) {
      // Fallback: if the OS timezone name isn't in the tz database,
      // default to UTC rather than crashing initialization.
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // requested explicitly below
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Requests runtime notification permission. Required on Android 13+
  /// (API 33+) and iOS. Call this from the UI (e.g. on first launch or
  /// when the user enables a reminder toggle).
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImpl?.requestNotificationsPermission() ?? true;
      // Also request exact-alarm permission for precise daily scheduling
      // on Android 12+ (falls back to inexact if denied, no crash).
      await androidImpl?.requestExactAlarmsPermission();
      return granted;
    } else if (Platform.isIOS) {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImpl?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
      return granted;
    }
    return true;
  }

  // ---------------------------------------------------------------------
  // WATER REMINDER LOGIC
  // ---------------------------------------------------------------------

  /// Schedules a repeating hydration reminder every [intervalHours] hours
  /// between [startHour] and [endHour] (24h clock, inclusive of start,
  /// exclusive of the end boundary as the last trigger).
  ///
  /// Example: startHour=8, endHour=20, intervalHours=2 produces daily
  /// reminders at 08:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00.
  ///
  /// Each time slot gets its own daily-repeating notification (using
  /// `matchDateTimeComponents: DateTimeComponents.time`), which is the
  /// reliable, battery-friendly way to do "every N hours within a window"
  /// with this plugin — a single periodic timer can't express a window.
  Future<void> scheduleWaterReminders({
    int startHour = 8,
    int endHour = 20,
    int intervalHours = 2,
  }) async {
    await cancelWaterReminders();

    const androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Hydration Reminders',
      channelDescription: 'Reminders to drink water throughout the day',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    int slotIndex = 0;
    for (int hour = startHour; hour <= endHour; hour += intervalHours) {
      final scheduledTime = _nextInstanceOfTime(hour, 0);

      await _plugin.zonedSchedule(
        _waterIdRangeStart + slotIndex,
        'Time to hydrate 💧',
        'A quick glass of water keeps your tissues healthy and recovery on track.',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Required by flutter_local_notifications ^17.x. Only meaningful
        // on iOS versions older than 10 (irrelevant to Android, but the
        // shared Dart API still mandates it on this plugin version).
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      );

      slotIndex++;
    }
  }

  Future<void> cancelWaterReminders() async {
    // Clear a generous id range to be safe regardless of how many slots
    // were previously scheduled with a different interval configuration.
    for (int i = 0; i < 50; i++) {
      await _plugin.cancel(_waterIdRangeStart + i);
    }
  }

  // ---------------------------------------------------------------------
  // STRETCHING REMINDER LOGIC
  // ---------------------------------------------------------------------

  /// Schedules a single daily reminder at [time] (e.g. 07:30) for the
  /// user's morning stretching routine. Repeats every day at the same
  /// time until cancelled.
  Future<void> scheduleStretchReminder(TimeOfDay time) async {
    await cancelStretchReminder();

    const androidDetails = AndroidNotificationDetails(
      'stretch_reminder_channel',
      'Stretching Reminders',
      channelDescription: 'Daily reminder for your mobility/stretch routine',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    final scheduledTime = _nextInstanceOfTime(time.hour, time.minute);

    await _plugin.zonedSchedule(
      _stretchId,
      'Morning stretch time 🦶',
      'A few minutes of plantar fascia and hip mobility work goes a long way.',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Required by flutter_local_notifications ^17.x. Only meaningful
      // on iOS versions older than 10 (irrelevant to Android, but the
      // shared Dart API still mandates it on this plugin version).
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  Future<void> cancelStretchReminder() async {
    await _plugin.cancel(_stretchId);
  }

  // ---------------------------------------------------------------------
  // SHARED HELPERS
  // ---------------------------------------------------------------------

  /// Returns the next occurrence of [hour]:[minute] in local time —
  /// today if that time hasn't passed yet, otherwise tomorrow. This is
  /// the standard pattern for setting up a "repeat daily" zonedSchedule.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Cancels every notification this app has scheduled — used when the
  /// user disables all reminders from Settings.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
