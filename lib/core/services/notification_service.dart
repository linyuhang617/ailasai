import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'local_storage_service.dart';

const _kNotifEnabled = 'notif_enabled';
const _kNotifHour = 'notif_hour';
const _kNotifMinute = 'notif_minute';
const _notifId = 1;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    final tzName = tzInfo.identifier;
    tz.setLocalLocation(tz.getLocation(tzName));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kNotifEnabled) ?? true;
  }

  Future<TimeOfDay> getScheduledTime() async {
    final p = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: p.getInt(_kNotifHour) ?? 20,
      minute: p.getInt(_kNotifMinute) ?? 0,
    );
  }

  Future<void> setEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifEnabled, value);
    if (value) {
      await scheduleDaily();
    } else {
      await cancelAll();
    }
  }

  Future<void> setTime(TimeOfDay time) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kNotifHour, time.hour);
    await p.setInt(_kNotifMinute, time.minute);
    final enabled = await isEnabled();
    if (enabled) await scheduleDaily();
  }

  static const _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_review',
      '每日複習提醒',
      channelDescription: '提醒你每天複習單字',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> scheduleDaily() async {
    await cancelAll();
    final time = await getScheduledTime();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, time.hour, time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _notifId,
      '愛喇賽 📚',
      '今天還有單字等著你複習！',
      scheduled,
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('[Notif] 排程 ${time.hour}:${time.minute.toString().padLeft(2, "0")} 每日觸發');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static void _onTap(NotificationResponse response) {
    NotificationService.instance.onTapCallback?.call(response.payload);
  }

  void Function(String? payload)? onTapCallback;

  Future<void> rescheduleIfDoneToday() async {
    final enabled = await isEnabled();
    if (!enabled) return;
    final storage = LocalStorageService();
    final states = await storage.getAllStates();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final doneToday = states.any((s) {
      final local = s.lastReviewedAt.toLocal();
      return !local.isBefore(todayStart) && local.isBefore(todayEnd);
    });
    if (doneToday) {
      await cancelAll();
      final time = await getScheduledTime();
      final now = tz.TZDateTime.now(tz.local);
      final tomorrow = tz.TZDateTime(
        tz.local, now.year, now.month, now.day + 1, time.hour, time.minute,
      );
      await _plugin.zonedSchedule(
        _notifId,
        '愛喇賽 📚',
        '今天還有單字等著你複習！',
        tomorrow,
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[Notif] 今日已複習，通知推到明天');
    }
  }
}
