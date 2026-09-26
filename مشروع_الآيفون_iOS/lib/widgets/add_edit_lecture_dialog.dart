import 'package:flutter/material.dart';
import '../models/lecture.dart';

class AddEditLectureDialog extends StatefulWidget {
  final Lecture? lecture;
  final int defaultDay;
  final int defaultReminderMins;

  const AddEditLectureDialog({
    super.key,
    this.lecture,
    required this.defaultDay,
    required this.defaultReminderMins,
  });

  @override
  State<AddEditLectureDialog> createState() => _AddEditLectureDialogState();
}

class _AddEditLectureDialogState extends State<AddEditLectureDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late CourseType _type;
  late String _location;
  late String _doctorOrGroup;
  late int _dayOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _reminderMinutesBefore;
  late Color _selectedColor;

  final List<Color> _availableColors = [
    const Color(0xFF1E88E5), // Blue
    const Color(0xFF1565C0), // Dark Blue
    const Color(0xFFFB8C00), // Orange
    const Color(0xFF8E24AA), // Purple
    const Color(0xFF0097A7), // Cyan/Teal
    const Color(0xFFD81B60), // Pink
    const Color(0xFF388E3C), // Green
    const Color(0xFF5D4037), // Brown
  ];

  @override
  void initState() {
    super.initState();
    if (widget.lecture != null) {
      _title = widget.lecture!.title;
      _type = widget.lecture!.type;
      _location = widget.lecture!.location;
      _doctorOrGroup = widget.lecture!.doctorOrGroup;
      _dayOfWeek = widget.lecture!.dayOfWeek;
      _startTime = widget.lecture!.startTime;
      _endTime = widget.lecture!.endTime;
      _reminderMinutesBefore = widget.lecture!.reminderMinutesBefore;
      _selectedColor = Color(widget.lecture!.colorValue);
    } else {
      _title = '';
      _type = CourseType.lecture;
      _location = '';
      _doctorOrGroup = '';
      _dayOfWeek = widget.defaultDay;
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      _reminderMinutesBefore = widget.defaultReminderMins;
      _selectedColor = _availableColors[0];
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Auto adjust end time to 1 hour later if end time is before start time
        if (_endTime.hour < picked.hour ||
            (_endTime.hour == picked.hour && _endTime.minute <= picked.minute)) {
          _endTime = TimeOfDay(
              hour: (picked.hour + 1) % 24, minute: picked.minute);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.lecture != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_calendar : Icons.add_alarm,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            isEditing ? 'تعديل موعد' : 'إضافة موعد جديد',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'اسم المادة / المحاضرة',
                  hintText: 'مثال: Oral Radiology I',
                  prefixIcon: Icon(Icons.book),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'يرجى إدخال اسم المادة' : null,
                onSaved: (val) => _title = val!.trim(),
              ),
              const SizedBox(height: 12),

              // Type (Lecture vs Section)
              DropdownButtonFormField<CourseType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'النوع (محاضرة / سكشن)',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: CourseType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _type = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Location / Hall
              TextFormField(
                initialValue: _location,
                decoration: const InputDecoration(
                  labelText: 'القاعة / المدرج',
                  hintText: 'مثال: قاعة K102',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'يرجى إدخال مكان القاعة' : null,
                onSaved: (val) => _location = val!.trim(),
              ),
              const SizedBox(height: 12),

              // Doctor / Group
              TextFormField(
                initialValue: _doctorOrGroup,
                decoration: const InputDecoration(
                  labelText: 'الدكتور / المجموعة (اختياري)',
                  hintText: 'مثال: مجموعة G7 أو د. أحمد',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => _doctorOrGroup = val?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              // Day of week
              DropdownButtonFormField<int>(
                value: _dayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'اليوم',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DateTime.sunday,
                  DateTime.monday,
                  DateTime.tuesday,
                  DateTime.wednesday,
                  DateTime.thursday,
                  DateTime.friday,
                  DateTime.saturday,
                ].map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(Lecture.getDayName(day)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _dayOfWeek = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Start & End Time row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartTime,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'وقت البدء',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndTime,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'وقت الانتهاء',
                          prefixIcon: Icon(Icons.access_time_filled),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _endTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reminder Time before
              DropdownButtonFormField<int>(
                value: _reminderMinutesBefore,
                decoration: const InputDecoration(
                  labelText: 'تنبيهي قبل الموعد بـ',
                  prefixIcon: Icon(Icons.notifications_active),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                  DropdownMenuItem(value: 30, child: Text('30 دقيقة')),
                  DropdownMenuItem(value: 60, child: Text('ساعة واحدة (60 دقيقة)')),
                  DropdownMenuItem(value: 120, child: Text('ساعتين (120 دقيقة)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _reminderMinutesBefore = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Color picker row
              const Text(
                'اختر لون التمييز:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = color.value == _selectedColor.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 18,
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              final newLecture = Lecture(
                id: widget.lecture?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                title: _title,
                type: _type,
                location: _location,
                doctorOrGroup: _doctorOrGroup,
                dayOfWeek: _dayOfWeek,
                startHour: _startTime.hour,
                startMinute: _startTime.minute,
                endHour: _endTime.hour,
                endMinute: _endTime.minute,
                reminderMinutesBefore: _reminderMinutesBefore,
                isNotificationEnabled:
                    widget.lecture?.isNotificationEnabled ?? true,
                colorValue: _selectedColor.value,
              );

              Navigator.pop(context, newLecture);
            }
          },
          child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة'),
        ),
      ],
    );
  }
}
