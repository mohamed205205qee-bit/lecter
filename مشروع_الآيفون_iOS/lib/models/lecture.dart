import 'package:flutter/material.dart';

enum CourseType {
  lecture('محاضرة', Colors.blue),
  section('سكنشن', Colors.orange);

  final String label;
  final Color defaultColor;
  const CourseType(this.label, this.defaultColor);
}

class Lecture {
  final String id;
  final String title;
  final CourseType type;
  final String location;
  final String doctorOrGroup;
  final int dayOfWeek; // 1 = Monday, 2 = Tuesday, ... 7 = Sunday
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int reminderMinutesBefore; // Default 60 (1 hour before)
  final bool isNotificationEnabled;
  final int colorValue;

  Lecture({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    this.doctorOrGroup = '',
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.reminderMinutesBefore = 60,
    this.isNotificationEnabled = true,
    required this.colorValue,
  });

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }

  String get startTimeFormatted => formatTimeOfDay(startTime);
  String get endTimeFormatted => formatTimeOfDay(endTime);
  String get timeSlotFormatted => '$startTimeFormatted - $endTimeFormatted';

  static String getDayName(int day) {
    switch (day) {
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.saturday:
        return 'السبت';
      default:
        return '';
    }
  }

  Lecture copyWith({
    String? id,
    String? title,
    CourseType? type,
    String? location,
    String? doctorOrGroup,
    int? dayOfWeek,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    int? reminderMinutesBefore,
    bool? isNotificationEnabled,
    int? colorValue,
  }) {
    return Lecture(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      location: location ?? this.location,
      doctorOrGroup: doctorOrGroup ?? this.doctorOrGroup,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'location': location,
      'doctorOrGroup': doctorOrGroup,
      'dayOfWeek': dayOfWeek,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isNotificationEnabled': isNotificationEnabled,
      'colorValue': colorValue,
    };
  }

  factory Lecture.fromJson(Map<String, dynamic> json) {
    return Lecture(
      id: json['id'],
      title: json['title'],
      type: CourseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CourseType.lecture,
      ),
      location: json['location'],
      doctorOrGroup: json['doctorOrGroup'] ?? '',
      dayOfWeek: json['dayOfWeek'],
      startHour: json['startHour'],
      startMinute: json['startMinute'],
      endHour: json['endHour'],
      endMinute: json['endMinute'],
      reminderMinutesBefore: json['reminderMinutesBefore'] ?? 60,
      isNotificationEnabled: json['isNotificationEnabled'] ?? true,
      colorValue: json['colorValue'] ?? Colors.teal.value,
    );
  }
}
