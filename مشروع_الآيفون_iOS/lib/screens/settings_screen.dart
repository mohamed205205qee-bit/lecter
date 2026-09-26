import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/schedule_provider.dart';
import '../services/ocr_service.dart';
import '../services/alarm_sound_service.dart';
import '../models/lecture.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات وصوت المنبه ⚙️'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Lock Screen & Background Alarm Permissions Banner
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Colors.amber, size: 26),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'صلاحية تشغيل المنبه والشاشة مغلقة 🔐',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text(
                    'لتأكيد عمل المنبه ورنته الصوتي وتفتحه تلقائياً فوق الشاشة حتى لو كان الهاتف مغلقاً أو التطبيق مغلقاً، يرجى تفعيل الصلاحيات التالية:',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.screen_lock_portrait, color: Colors.white),
                      label: const Text(
                        'تفعيل صلاحية الظهور فوق التطبيقات والمنبه',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        await Permission.systemAlertWindow.request();
                        await Permission.ignoreBatteryOptimizations.request();
                        await Permission.scheduleExactAlarm.request();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إرسال طلب الصلاحيات لنظام الهاتف بنجاح!'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // OCR Document Import Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.document_scanner,
                          color: Theme.of(context).primaryColor, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'استيراد جدول من صورة أو PDF 📄📷',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'يمكنك رفع صورة لجدولك الدراسي أو ملف PDF وسيتم التعرف التلقائي على المواد والمواعيد وإضافتها لجدولك فوراً!',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: const Text(
                        'رفع ملف (صورة / PDF) وقراءة الجدول',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _handleOcrImport(context, provider),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notification & Custom Sound Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alarm_on,
                          color: Theme.of(context).primaryColor, size: 26),
                      const SizedBox(width: 8),
                      const Text(
                        'إعدادات نغمة وصوت المنبه 🔔',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    title: const Text('تفعيل التنبيه والمنبه التلقائي'),
                    subtitle: const Text('رنة منبه تنبيهية كأنه موبايل قبل الموعد'),
                    value: provider.globalNotificationsEnabled,
                    onChanged: (val) {
                      provider.toggleGlobalNotifications();
                    },
                  ),
                  const SizedBox(height: 8),

                  // Lead time
                  ListTile(
                    title: const Text('وقت التنبيه المسبق'),
                    subtitle: Text(
                        'ينبهك المنبه قبل الموعد بـ: ${provider.defaultReminderMins} دقيقة'),
                    trailing: DropdownButton<int>(
                      value: provider.defaultReminderMins,
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                        DropdownMenuItem(
                            value: 30, child: Text('30 دقيقة (نصف ساعة)')),
                        DropdownMenuItem(
                            value: 60, child: Text('ساعة واحدة (60 دقيقة)')),
                        DropdownMenuItem(value: 120, child: Text('ساعتين')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          provider.updateDefaultReminderMins(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Alarm Sound Type Selector
                  const Text(
                    'اختر نغمة وصوت المنبه:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<AlarmSoundType>(
                    value: provider.alarmSoundType,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.music_note),
                      border: OutlineInputBorder(),
                    ),
                    items: AlarmSoundType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        provider.setAlarmSoundType(val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Upload custom sound file button
                  if (provider.alarmSoundType == AlarmSoundType.customFile) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.customAlarmSoundPath != null
                                ? 'الملف الصوتي المختار: ${provider.customAlarmSoundPath!.split(RegExp(r'[/\\]')).last}'
                                : 'لم يتم اختيار ملف صوتي مخصص بعد',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.audio_file),
                            label: const Text('اختيار ملف صوتي (MP3 / WAV) من جهازك'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final success =
                                  await provider.pickAndSetCustomAlarmSound();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم اختيار الملف الصوتي المخصص بنجاح! 🎵'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Test and Stop buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.play_circle_fill,
                              color: Colors.green),
                          label: const Text('تجربة رنة المنبه'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await provider.triggerTestAlarm(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.stop, color: Colors.red),
                        label: const Text('إيقاف الصوت'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          await provider.stopAlarm();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم إيقاف صوت التنبيه'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Appearance Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'المظهر والنمط',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    title: const Text('الوضع الليلي (Dark Mode)'),
                    subtitle: const Text('تغيير مظهر التطبيق إلى الألوان الداكنة'),
                    value: provider.isDarkMode,
                    onChanged: (val) {
                      provider.toggleDarkMode();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reset Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: const Icon(Icons.refresh, color: Colors.red),
                title: const Text('استعادة جدول Excel الأصلي'),
                subtitle: const Text('إعادة تعيين المواعيد للجدول الأساسي'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تأكيد استعادة الجدول'),
                      content: const Text(
                          'هل تريد استعادة الجدول الأصلي وإعادة ضبط المواعيد؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () {
                            Navigator.pop(ctx);
                            provider.resetToDefaultSchedule();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تمت استعادة الجدول الأصلي بنجاح!'),
                              ),
                            );
                          },
                          child: const Text('استعادة',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOcrImport(BuildContext context, ScheduleProvider provider) async {
    final ocrService = OcrService();
    final result = await ocrService.pickAndParseScheduleFile(context);

    if (result == null || !context.mounted) return;

    if (result.detectedLectures.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('لم يتم العثور على مواد جديدة'),
          content: Text(
              'تعذرت قراءة بعض النصوص تلقائياً من الملف "${result.fileName}". يمكنك التأكد من وضوح الصورة أو إضافة المواد يدوياً.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.task_alt, color: Colors.green),
            const SizedBox(width: 8),
            Text('تم اكتشاف ${result.detectedLectures.length} مواعيد!'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: result.detectedLectures.length,
            itemBuilder: (context, index) {
              final item = result.detectedLectures[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(item.colorValue),
                  child: Text(
                    item.type == CourseType.lecture ? 'م' : 'س',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${Lecture.getDayName(item.dayOfWeek)} • ${item.location}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              for (final lecture in result.detectedLectures) {
                provider.addLecture(lecture);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'تم استيراد ${result.detectedLectures.length} موعد من الملف بنجاح! 🎉'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('إضافة هذه المواعيد للجدول'),
          ),
        ],
      ),
    );
  }
}
