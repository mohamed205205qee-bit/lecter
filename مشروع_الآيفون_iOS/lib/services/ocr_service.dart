import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/lecture.dart';

class OcrImportResult {
  final List<Lecture> detectedLectures;
  final String rawText;
  final String fileName;

  OcrImportResult({
    required this.detectedLectures,
    required this.rawText,
    required this.fileName,
  });
}

class OcrService {
  Future<OcrImportResult?> pickAndParseScheduleFile(BuildContext context) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
    );

    if (files.isEmpty || files.first.path == null) {
      return null;
    }

    final filePath = files.first.path!;
    final fileName = files.first.name;

    String extractedText = '';

    if (filePath.toLowerCase().endsWith('.pdf')) {
      // PDF text extraction fallback/parser
      extractedText = await _extractTextFromPdf(filePath);
    } else {
      // Image OCR text recognition
      extractedText = await _extractTextFromImage(filePath);
    }

    final parsedLectures = parseTextToLectures(extractedText);

    return OcrImportResult(
      detectedLectures: parsedLectures,
      rawText: extractedText,
      fileName: fileName,
    );
  }

  Future<String> _extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      return recognizedText.text;
    } catch (e) {
      debugPrint('Error running MLKit Text Recognition: $e');
      return '';
    }
  }

  Future<String> _extractTextFromPdf(String pdfPath) async {
    try {
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      final str = String.fromCharCodes(bytes);
      // Basic text extraction from pdf stream
      final RegExp regExp = RegExp(r'\((.*?)\)');
      final matches = regExp.allMatches(str);
      final buffer = StringBuffer();
      for (final match in matches) {
        final text = match.group(1);
        if (text != null && text.length > 2) {
          buffer.writeln(text);
        }
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('Error reading PDF: $e');
      return '';
    }
  }

  List<Lecture> parseTextToLectures(String rawText) {
    final List<Lecture> lectures = [];
    final lines = rawText.split('\n');

    int currentDay = DateTime.sunday;
    final Map<String, int> dayKeywords = {
      'الأحد': DateTime.sunday,
      'sunday': DateTime.sunday,
      'الاثنين': DateTime.monday,
      'الإثنين': DateTime.monday,
      'monday': DateTime.monday,
      'الثلاثاء': DateTime.tuesday,
      'tuesday': DateTime.tuesday,
      'الأربعاء': DateTime.wednesday,
      'الاربعاء': DateTime.wednesday,
      'wednesday': DateTime.wednesday,
      'الخميس': DateTime.thursday,
      'thursday': DateTime.thursday,
      'الجمعة': DateTime.friday,
      'friday': DateTime.friday,
      'السبت': DateTime.saturday,
      'saturday': DateTime.saturday,
    };

    final RegExp timePattern = RegExp(r'(\d{1,2})\s*[-:]\s*(\d{1,2})');
    final RegExp hallPattern = RegExp(r'([KM]\s*\d{2,3}|قاعة\s*\w+|مدرج\s*\w+)');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check day header
      for (final entry in dayKeywords.entries) {
        if (line.toLowerCase().contains(entry.key)) {
          currentDay = entry.value;
          break;
        }
      }

      // Check if line contains course title or time
      final timeMatch = timePattern.firstMatch(line);
      final hallMatch = hallPattern.firstMatch(line);

      if (line.length > 3 && !dayKeywords.keys.any((k) => line.toLowerCase() == k)) {
        int startHour = 9;
        int endHour = 10;

        if (timeMatch != null) {
          final h1 = int.tryParse(timeMatch.group(1) ?? '9') ?? 9;
          final h2 = int.tryParse(timeMatch.group(2) ?? '10') ?? 10;
          startHour = h1 < 7 ? h1 + 12 : h1;
          endHour = h2 < 7 ? h2 + 12 : h2;
        }

        final location = hallMatch != null ? hallMatch.group(0)! : 'قاعة المحاضرات';
        final isSection = line.contains('-G') ||
            line.contains('G1') ||
            line.contains('G2') ||
            line.contains('G3') ||
            line.contains('G5') ||
            line.contains('G7') ||
            line.contains('G8') ||
            line.contains('سكشن');

        final courseType = isSection ? CourseType.section : CourseType.lecture;

        // Clean title
        String title = line
            .replaceAll(timePattern, '')
            .replaceAll(hallPattern, '')
            .replaceAll('جدول', '')
            .replaceAll('المحاضرات', '')
            .trim();

        if (title.isEmpty) title = 'مادة أثر قراءة الجدول';

        lectures.add(
          Lecture(
            id: 'ocr_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: title,
            type: courseType,
            location: location,
            doctorOrGroup: isSection ? 'مجموعة من التصدير' : 'محاضرة',
            dayOfWeek: currentDay,
            startHour: startHour,
            startMinute: 0,
            endHour: endHour,
            endMinute: 0,
            reminderMinutesBefore: 60,
            colorValue: courseType.defaultColor.value,
          ),
        );
      }
    }

    return lectures;
  }
}
