import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/lecture.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/alarm_sound_service.dart';
import '../screens/alarm_ring_screen.dart';
import '../data/initial_data.dart';

class ScheduleProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final AlarmSoundService _alarmSoundService = AlarmSoundService();

  List<Lecture> _lectures = [];
  int _selectedDay = DateTime.now().weekday;
  bool _isDarkMode = false;
  bool _globalNotificationsEnabled = true;
  int _defaultReminderMins = 60; // Default 1 hour before
  bool _isLoading = true;

  AlarmSoundType _alarmSoundType = AlarmSoundType.defaultTone;
  String? _customAlarmSoundPath;

  List<Lecture> get lectures => _lectures;
  int get selectedDay => _selectedDay;
  bool get isDarkMode => _isDarkMode;
  bool get globalNotificationsEnabled => _globalNotificationsEnabled;
  int get defaultReminderMins => _defaultReminderMins;
  bool get isLoading => _isLoading;
  AlarmSoundType get alarmSoundType => _alarmSoundType;
  String? get customAlarmSoundPath => _customAlarmSoundPath;

  List<Lecture> get lecturesForSelectedDay {
    final dayList =
        _lectures.where((l) => l.dayOfWeek == _selectedDay).toList();
    dayList.sort((a, b) {
      final aMins = a.startHour * 60 + a.startMinute;
      final bMins = b.startHour * 60 + b.startMinute;
      return aMins.compareTo(bMins);
    });
    return dayList;
  }

  Lecture? get nextUpcomingLectureToday {
    final now = DateTime.now();
    final todayLectures =
        _lectures.where((l) => l.dayOfWeek == now.weekday).toList();

    todayLectures.sort((a, b) {
      final aMins = a.startHour * 60 + a.startMinute;
      final bMins = b.startHour * 60 + b.startMinute;
      return aMins.compareTo(bMins);
    });

    final currentMins = now.hour * 60 + now.minute;

    for (final l in todayLectures) {
      final endMins = l.endHour * 60 + l.endMinute;
      if (endMins > currentMins) {
        return l;
      }
    }
    return null;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _isDarkMode = await _storageService.getDarkMode();
    _globalNotificationsEnabled =
        await _storageService.getGlobalNotificationsEnabled();
    _defaultReminderMins = await _storageService.getDefaultReminderMins();
    _alarmSoundType = await _storageService.getAlarmSoundType();
    _customAlarmSoundPath = await _storageService.getCustomAlarmSoundPath();
    _lectures = await _storageService.loadLectures();

    if (_globalNotificationsEnabled) {
      await _notificationService.rescheduleAll(_lectures);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedDay(int day) {
    _selectedDay = day;
    notifyListeners();
  }

  Future<void> addLecture(Lecture lecture) async {
    _lectures.add(lecture);
    await _storageService.saveLectures(_lectures);
    if (_globalNotificationsEnabled && lecture.isNotificationEnabled) {
      await _notificationService.scheduleLectureNotification(lecture);
    }
    notifyListeners();
  }

  Future<void> updateLecture(Lecture lecture) async {
    final index = _lectures.indexWhere((l) => l.id == lecture.id);
    if (index != -1) {
      _lectures[index] = lecture;
      await _storageService.saveLectures(_lectures);
      if (_globalNotificationsEnabled && lecture.isNotificationEnabled) {
        await _notificationService.scheduleLectureNotification(lecture);
      } else {
        await _notificationService.cancelLectureNotification(lecture.id);
      }
      notifyListeners();
    }
  }

  Future<void> deleteLecture(String id) async {
    _lectures.removeWhere((l) => l.id == id);
    await _storageService.saveLectures(_lectures);
    await _notificationService.cancelLectureNotification(id);
    notifyListeners();
  }

  Future<void> toggleLectureNotification(String id) async {
    final index = _lectures.indexWhere((l) => l.id == id);
    if (index != -1) {
      final updated = _lectures[index].copyWith(
        isNotificationEnabled: !_lectures[index].isNotificationEnabled,
      );
      _lectures[index] = updated;
      await _storageService.saveLectures(_lectures);

      if (_globalNotificationsEnabled && updated.isNotificationEnabled) {
        await _notificationService.scheduleLectureNotification(updated);
      } else {
        await _notificationService.cancelLectureNotification(id);
      }
      notifyListeners();
    }
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> toggleGlobalNotifications() async {
    _globalNotificationsEnabled = !_globalNotificationsEnabled;
    await _storageService.setGlobalNotificationsEnabled(
        _globalNotificationsEnabled);

    if (_globalNotificationsEnabled) {
      await _notificationService.rescheduleAll(_lectures);
    } else {
      for (final l in _lectures) {
        await _notificationService.cancelLectureNotification(l.id);
      }
    }
    notifyListeners();
  }

  Future<void> updateDefaultReminderMins(int mins) async {
    _defaultReminderMins = mins;
    await _storageService.setDefaultReminderMins(mins);

    _lectures =
        _lectures.map((l) => l.copyWith(reminderMinutesBefore: mins)).toList();
    await _storageService.saveLectures(_lectures);

    if (_globalNotificationsEnabled) {
      await _notificationService.rescheduleAll(_lectures);
    }
    notifyListeners();
  }

  Future<void> setAlarmSoundType(AlarmSoundType type) async {
    _alarmSoundType = type;
    await _storageService.setAlarmSoundType(type);
    notifyListeners();
  }

  Future<bool> pickAndSetCustomAlarmSound() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      _customAlarmSoundPath = files.first.path;
      _alarmSoundType = AlarmSoundType.customFile;
      await _storageService.setCustomAlarmSoundPath(_customAlarmSoundPath);
      await _storageService.setAlarmSoundType(AlarmSoundType.customFile);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> resetToDefaultSchedule() async {
    _lectures = getInitialLectures();
    await _storageService.saveLectures(_lectures);
    if (_globalNotificationsEnabled) {
      await _notificationService.rescheduleAll(_lectures);
    }
    notifyListeners();
  }

  Future<void> triggerTestAlarm(BuildContext context) async {
    await _notificationService.showTestNotification();
    await _alarmSoundService.playAlarmSound(
      type: _alarmSoundType,
      customPath: _customAlarmSoundPath,
    );

    final sampleLecture = _lectures.isNotEmpty
        ? _lectures.first
        : Lecture(
            id: 'sample',
            title: 'Oral Radiology I',
            type: CourseType.lecture,
            location: 'قاعة K301',
            dayOfWeek: DateTime.sunday,
            startHour: 9,
            startMinute: 0,
            endHour: 10,
            endMinute: 0,
            reminderMinutesBefore: _defaultReminderMins,
            colorValue: Colors.teal.value,
          );

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlarmRingScreen(lecture: sampleLecture),
        ),
      );
    }
  }

  Future<void> stopAlarm() async {
    await _alarmSoundService.stopAlarmSound();
  }
}
