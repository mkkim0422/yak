import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Wrapper around flutter_local_notifications.
///
/// Stage 1 wires the plugin and channel only. Concrete schedules are added
/// when the settings screen lands in Stage 3.
class NotificationService {
  NotificationService();

  static const String _channelId = 'supplement_reminder';
  static const String _channelName = '영양제 복용 알림';
  static const String _channelDescription = '영양제 복용 시간을 알려드려요';

  static const int _morningId = 1001;
  static const int _eveningId = 1002;
  static const int _reorderIdBase = 2000;

  /// Stable id derived from the member id, used to scope per-member
  /// schedules so we can cancel them all when the member is removed.
  static int _idFor(String memberId, int base, [String? suffix]) {
    final key = suffix == null ? memberId : '$memberId#$suffix';
    return base + key.hashCode.abs() % 999;
  }

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    await _configureLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await ensureInitialized();

    if (Platform.isIOS || Platform.isMacOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  /// Reschedule the morning + evening reminders. When [familyCount] >= 2 the
  /// title says "가족 영양제 챙기실 시간이에요" instead of singular phrasing,
  /// because most families add multiple members. Default 1 keeps older
  /// callers working unchanged.
  Future<void> rescheduleDaily({
    TimeOfDay? morning,
    TimeOfDay? evening,
    int familyCount = 1,
  }) async {
    await ensureInitialized();
    await _plugin.cancel(_morningId);
    await _plugin.cancel(_eveningId);

    final title = familyCount >= 2
        ? '가족 영양제 챙기실 시간이에요'
        : '오늘 영양제 챙기셨어요?';

    if (morning != null) {
      await _scheduleDaily(
        id: _morningId,
        time: morning,
        title: title,
        body: '물 한 컵과 함께 챙겨드세요',
      );
    }
    if (evening != null) {
      await _scheduleDaily(
        id: _eveningId,
        time: evening,
        title: title,
        body: '오늘도 수고 많으셨어요',
      );
    }
  }

  Future<void> scheduleReorderReminder(
    String memberId, {
    int daysFromNow = 25,
  }) async {
    await scheduleProductReorderReminder(
      memberId: memberId,
      productId: 'default',
      daysFromNow: daysFromNow,
    );
  }

  /// Per-product reorder reminder. Lets us cancel a single product's
  /// reminder when the user removes that product without disturbing the
  /// rest of the member's schedules.
  Future<void> scheduleProductReorderReminder({
    required String memberId,
    required String productId,
    int daysFromNow = 25,
  }) async {
    await ensureInitialized();
    final id = _idFor(memberId, _reorderIdBase, 'reorder:$productId');
    final fireAt =
        tz.TZDateTime.now(tz.local).add(Duration(days: daysFromNow));
    await _plugin.zonedSchedule(
      id,
      '영양제 재구매 시점이 다가왔어요',
      '남은 수량을 확인해보세요',
      fireAt,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reorder:$memberId:$productId',
    );
  }

  Future<void> cancelReorderReminder({
    required String memberId,
    required String productId,
  }) async {
    await ensureInitialized();
    await _plugin.cancel(
      _idFor(memberId, _reorderIdBase, 'reorder:$productId'),
    );
  }

  /// Cancels every member-scoped notification, regardless of payload.
  /// Used when a family member is removed.
  Future<void> cancelAllForMember(String memberId) async {
    await ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    final prefix = ':$memberId';
    for (final p in pending) {
      final payload = p.payload ?? '';
      if (payload.contains(prefix) || payload.endsWith(memberId)) {
        await _plugin.cancel(p.id);
      }
    }
  }

  Future<void> cancelAll() async {
    await ensureInitialized();
    await _plugin.cancelAll();
  }

  Future<void> _scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var fireAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!fireAt.isAfter(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      fireAt,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _configureLocalTimezone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
  }
}
