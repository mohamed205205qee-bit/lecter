import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lecture.dart';
import '../data/initial_data.dart';
import '../services/alarm_sound_service.dart';

class StorageService {
  static const String _keyLectures = 'lectures_schedule_data_v1';
  static const String _keyDefaultReminderMins = 'default_reminder_mins';
  static const String _keyDarkMode = 'is_dark_mode';
  static const String _keyNotificationsEnabled = 'global_notifications_enabled';
  static const String _keyCustomAlarmSoundPath = 'custom_alarm_sound_path';
  static const String _keyAlarmSoundType = 'alarm_sound_type';

  Future<List<Lecture>> loadLectures() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_keyLectures);

    if (jsonStr == null || jsonStr.isEmpty) {
      final initialData = getInitialLectures();
      await saveLectures(initialData);
      return initialData;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => Lecture.fromJson(e)).toList();
    } catch (e) {
      final initialData = getInitialLectures();
      await saveLectures(initialData);
      return initialData;
    }
  }

  Future<void> saveLectures(List<Lecture> lectures) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(lectures.map((e) => e.toJson()).toList());
    await prefs.setString(_keyLectures, jsonStr);
  }

  Future<int> getDefaultReminderMins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDefaultReminderMins) ?? 60; // 60 minutes default
  }

  Future<void> setDefaultReminderMins(int mins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultReminderMins, mins);
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
  }

  Future<bool> getGlobalNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setGlobalNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  Future<String?> getCustomAlarmSoundPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomAlarmSoundPath);
  }

  Future<void> setCustomAlarmSoundPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_keyCustomAlarmSoundPath);
    } else {
      await prefs.setString(_keyCustomAlarmSoundPath, path);
    }
  }

  Future<AlarmSoundType> getAlarmSoundType() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyAlarmSoundType);
    if (name == null) return AlarmSoundType.defaultTone;
    return AlarmSoundType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AlarmSoundType.defaultTone,
    );
  }

  Future<void> setAlarmSoundType(AlarmSoundType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAlarmSoundType, type.name);
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLectures);
  }
}
