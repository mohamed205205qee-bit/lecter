import 'package:flutter/material.dart';
import '../models/lecture.dart';
import '../services/alarm_sound_service.dart';

class AlarmRingScreen extends StatefulWidget {
  final Lecture lecture;

  const AlarmRingScreen({
    super.key,
    required this.lecture,
  });

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lecture = widget.lecture;
    final cardColor = Color(lecture.colorValue);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Pulsing Alarm Icon
              ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.15).animate(
                  CurvedAnimation(
                    parent: _animController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.alarm_on,
                    size: 90,
                    color: Colors.amber,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⏰ تنبيه منبه المحاضرة (بعد ${lecture.reminderMinutesBefore} دقيقة)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                lecture.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    lecture.location,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'الميعاد: ${lecture.startTimeFormatted} - ${lecture.endTimeFormatted}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),

              const Spacer(),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.stop_circle, size: 28),
                      label: const Text(
                        'إيقاف رنة المنبه',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      onPressed: () async {
                        await AlarmSoundService().stopAlarmSound();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextButton.icon(
                icon: const Icon(Icons.snooze, color: Colors.amber),
                label: const Text(
                  'تأجيل التنبيه 5 دقائق',
                  style: TextStyle(color: Colors.amber, fontSize: 16),
                ),
                onPressed: () async {
                  await AlarmSoundService().stopAlarmSound();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تأجيل المنبه لمدة 5 دقائق'),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
