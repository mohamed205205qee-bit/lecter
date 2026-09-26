import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum AlarmSoundType {
  defaultTone('صوت المنبه الافتراضي (تي تي تي تي)'),
  systemAlarm('صوت نغمة المنبه الخاصة بالنظام'),
  customFile('صوت مخصص من ملفات الجهاز (MP3 / WAV)');

  final String label;
  const AlarmSoundType(this.label);
}

class AlarmSoundService {
  static final AlarmSoundService _instance = AlarmSoundService._internal();
  factory AlarmSoundService() => _instance;
  AlarmSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playAlarmSound({
    AlarmSoundType type = AlarmSoundType.defaultTone,
    String? customPath,
  }) async {
    try {
      await stopAlarmSound();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      if (type == AlarmSoundType.customFile &&
          customPath != null &&
          customPath.isNotEmpty &&
          File(customPath).existsSync()) {
        await _audioPlayer.play(DeviceFileSource(customPath));
        debugPrint('Playing custom alarm sound file: $customPath');
      } else {
        // High volume beep alarm clock tone
        await _audioPlayer.play(UrlSource(
            'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg'));
        debugPrint('Playing default alarm clock sound');
      }
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  Future<void> stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      debugPrint('Alarm sound stopped');
    } catch (e) {
      debugPrint('Error stopping alarm sound: $e');
    }
  }
}
