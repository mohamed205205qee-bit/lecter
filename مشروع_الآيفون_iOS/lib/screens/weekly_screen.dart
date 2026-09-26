import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/lecture.dart';

class WeeklyScreen extends StatelessWidget {
  const WeeklyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);

    final days = [
      {'day': DateTime.sunday, 'name': 'الأحد'},
      {'day': DateTime.monday, 'name': 'الاثنين'},
      {'day': DateTime.tuesday, 'name': 'الثلاثاء'},
      {'day': DateTime.wednesday, 'name': 'الأربعاء'},
      {'day': DateTime.thursday, 'name': 'الخميس'},
      {'day': DateTime.friday, 'name': 'الجمعة'},
      {'day': DateTime.saturday, 'name': 'السبت'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الجدول الأسبوعي الكامل 📅'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: days.map((dayData) {
            final dayNum = dayData['day'] as int;
            final dayName = dayData['name'] as String;

            final dayLectures = provider.lectures
                .where((l) => l.dayOfWeek == dayNum)
                .toList();

            dayLectures.sort((a, b) {
              final aMins = a.startHour * 60 + a.startMinute;
              final bMins = b.startHour * 60 + b.startMinute;
              return aMins.compareTo(bMins);
            });

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ExpansionTile(
                initiallyExpanded: dayLectures.isNotEmpty,
                leading: CircleAvatar(
                  backgroundColor: dayLectures.isNotEmpty
                      ? theme.primaryColor
                      : Colors.grey.shade400,
                  child: Text(
                    '${dayLectures.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  dayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  dayLectures.isEmpty
                      ? 'إجازة / لا يوجد محاضرات'
                      : '${dayLectures.length} مواعيد مبرمجة',
                  style: TextStyle(
                    color: dayLectures.isEmpty ? Colors.grey : theme.primaryColor,
                    fontSize: 12,
                  ),
                ),
                children: [
                  if (dayLectures.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'لا يوجد مواعيد مسجلة في هذا اليوم.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: dayLectures.map((lecture) {
                          final cardColor = Color(lecture.colorValue);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cardColor.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lecture.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${lecture.type.label} • ${lecture.location}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    lecture.timeSlotFormatted,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
