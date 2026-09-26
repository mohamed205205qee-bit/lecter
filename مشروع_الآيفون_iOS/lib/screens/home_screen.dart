import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/lecture.dart';
import '../widgets/lecture_card.dart';
import '../widgets/upcoming_lecture_card.dart';
import '../widgets/add_edit_lecture_dialog.dart';
import 'weekly_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);
    final todayWeekday = DateTime.now().weekday;

    final days = [
      {'day': DateTime.sunday, 'name': 'الأحد'},
      {'day': DateTime.monday, 'name': 'الاثنين'},
      {'day': DateTime.tuesday, 'name': 'الثلاثاء'},
      {'day': DateTime.wednesday, 'name': 'الأربعاء'},
      {'day': DateTime.thursday, 'name': 'الخميس'},
      {'day': DateTime.friday, 'name': 'الجمعة'},
      {'day': DateTime.saturday, 'name': 'السبت'},
    ];

    final lecturesToday = provider.lecturesForSelectedDay;
    final upcomingLecture = provider.nextUpcomingLectureToday;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school, color: theme.primaryColor),
            ),
            const SizedBox(width: 10),
            const Text(
              'جدول المحاضرات والسكاشن',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_view_week),
            tooltip: 'عرض الجدول الأسبوعي',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeeklyScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'الإعدادات والتنبيهات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Day Selection horizontal list
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final dayData = days[index];
                      final dayNum = dayData['day'] as int;
                      final dayName = dayData['name'] as String;
                      final isSelected = provider.selectedDay == dayNum;
                      final isToday = todayWeekday == dayNum;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: FilterChip(
                          selected: isSelected,
                          showCheckmark: false,
                          avatar: isToday
                              ? CircleAvatar(
                                  radius: 10,
                                  backgroundColor: isSelected
                                      ? Colors.white
                                      : theme.primaryColor,
                                  child: Text(
                                    'اليوم',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: isSelected
                                          ? theme.primaryColor
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          label: Text(
                            dayName,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.textTheme.bodyLarge?.color,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          backgroundColor: theme.cardColor,
                          selectedColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              provider.setSelectedDay(dayNum);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Highlight upcoming lecture if today is selected and lecture exists
                      if (provider.selectedDay == todayWeekday &&
                          upcomingLecture != null)
                        UpcomingLectureCard(lecture: upcomingLecture),

                      // Section title
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'مواعيد يوم ${Lecture.getDayName(provider.selectedDay)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Chip(
                              label: Text(
                                '${lecturesToday.length} مواعيد',
                                style: const TextStyle(fontSize: 12),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),

                      // Empty state
                      if (lecturesToday.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا يوجد محاضرات أو سكاشن في هذا اليوم (${Lecture.getDayName(provider.selectedDay)}) 🎉',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة موعد لهذا اليوم'),
                                onPressed: () => _openAddDialog(context, provider),
                              ),
                            ],
                          ),
                        ),

                      // Lecture list
                      ...lecturesToday.map((lecture) {
                        return LectureCard(
                          lecture: lecture,
                          onToggleNotification: () {
                            provider.toggleLectureNotification(lecture.id);
                          },
                          onEdit: () => _openEditDialog(context, provider, lecture),
                          onDelete: () => _confirmDelete(context, provider, lecture),
                        );
                      }),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context, provider),
        icon: const Icon(Icons.add_alarm),
        label: const Text(
          'إضافة محاضرة / سكشن',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _openAddDialog(BuildContext context, ScheduleProvider provider) async {
    final result = await showDialog<Lecture>(
      context: context,
      builder: (ctx) => AddEditLectureDialog(
        defaultDay: provider.selectedDay,
        defaultReminderMins: provider.defaultReminderMins,
      ),
    );

    if (result != null) {
      provider.addLecture(result);
    }
  }

  void _openEditDialog(
      BuildContext context, ScheduleProvider provider, Lecture lecture) async {
    final result = await showDialog<Lecture>(
      context: context,
      builder: (ctx) => AddEditLectureDialog(
        lecture: lecture,
        defaultDay: provider.selectedDay,
        defaultReminderMins: provider.defaultReminderMins,
      ),
    );

    if (result != null) {
      provider.updateLecture(result);
    }
  }

  void _confirmDelete(
      BuildContext context, ScheduleProvider provider, Lecture lecture) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت أؤكد من حذف موعد "${lecture.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteLecture(lecture.id);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
