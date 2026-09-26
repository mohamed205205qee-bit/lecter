import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/lecture.dart';
import 'alarm_sound_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = tz.local.name;
      debugPrint('Local Timezone: $timeZoneName');
    } catch (e) {
      debugPrint('Error getting local timezone: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        debugPrint('Notification clicked: ${details.payload}');
        await AlarmSoundService().stopAlarmSound();
      },
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    // Notification Permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Exact Alarm Permission
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // Display over other apps (System Alert Window) for lock screen alarm popup
    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }

    // Ignore Battery Optimizations so alarm fires even if device is sleeping/locked
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    return true;
  }

  int _generateNotificationId(Lecture lecture) {
    return lecture.id.hashCode.abs() % 100000;
  }

  Future<void> scheduleLectureNotification(Lecture lecture) async {
    if (!lecture.isNotificationEnabled) {
      await cancelLectureNotification(lecture.id);
      return;
    }

    await init();
    await requestPermissions();

    final int notificationId = _generateNotificationId(lecture);
    final tz.TZDateTime scheduledDate = _nextInstanceOfLecture(lecture);

    final Int64List vibrationPattern =
        Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'lecture_alarm_channel_v3',
      'تنبيهات منبه المحاضرات والسكاشن',
      channelDescription: 'رنة منبه عالية واهتزاز وتنبيه فوق الشاشة المغلقة',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alarm.caf',
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    final String typeName =
        lecture.type == CourseType.lecture ? 'المحاضرة' : 'الساكشن';

    try {
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: '⏰ تنبيه منبه: $typeName القادمة ⏰',
        body: 'ميعاد $typeName "${lecture.title}" بعد ${lecture.reminderMinutesBefore} دقيقة في ${lecture.location}',
        scheduledDate: scheduledDate,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: lecture.id,
      );
      debugPrint(
          'Scheduled alarm notification for ${lecture.title} at $scheduledDate (ID: $notificationId)');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfLecture(Lecture lecture) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    DateTime lectureStartTime = DateTime(
      now.year,
      now.month,
      now.day,
      lecture.startHour,
      lecture.startMinute,
    );

    DateTime reminderTime = lectureStartTime.subtract(
      Duration(minutes: lecture.reminderMinutesBefore),
    );

    int daysUntilTargetDay = (lecture.dayOfWeek - now.weekday + 7) % 7;

    DateTime targetDateTime = reminderTime.add(Duration(days: daysUntilTargetDay));

    if (daysUntilTargetDay == 0 && targetDateTime.isBefore(now)) {
      targetDateTime = targetDateTime.add(const Duration(days: 7));
    }

    return tz.TZDateTime.from(targetDateTime, tz.local);
  }

  Future<void> cancelLectureNotification(String lectureId) async {
    await init();
    final int notificationId = lectureId.hashCode.abs() % 100000;
    await _notificationsPlugin.cancel(id: notificationId);
    await AlarmSoundService().stopAlarmSound();
    debugPrint('Cancelled notification ID $notificationId');
  }

  Future<void> rescheduleAll(List<Lecture> lectures) async {
    await init();
    await _notificationsPlugin.cancelAll();
    for (final lecture in lectures) {
      if (lecture.isNotificationEnabled) {
        await scheduleLectureNotification(lecture);
      }
    }
  }

  Future<void> showTestNotification() async {
    await init();
    await requestPermissions();

    final Int64List vibrationPattern =
        Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'lecture_alarm_channel_v3',
      'تنبيهات منبه المحاضرات والسكاشن',
      channelDescription: 'تنبيهات تجريبية للمستخدم برنة منبه وشاشة قفل',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    await _notificationsPlugin.show(
      id: 99999,
      title: '⏰ تجربة رنة المنبه وشاشة التنبيه ⏰',
      body: 'هذه رنة المنبه والواجهة التلقائية التي ستظهر فوق الشاشة حتى لو كان الهاتف مغلقاً!',
      notificationDetails: details,
    );
  }
}
