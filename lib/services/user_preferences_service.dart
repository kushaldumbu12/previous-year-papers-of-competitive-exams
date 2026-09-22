import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam_model.dart';

class UserPreferencesService {
  static const String _keyPreferredExam = 'user_preferred_exam_json';
  static const String _keyPreferredExamId = 'user_preferred_exam_id';

  /// Saves the user's selected exam target preference
  static Future<void> savePreferredExam(Exam exam) async {
    final prefs = await SharedPreferences.getInstance();
    final examMap = exam.toFirestore();
    examMap['id'] = exam.id;
    await prefs.setString(_keyPreferredExam, jsonEncode(examMap));
    await prefs.setString(_keyPreferredExamId, exam.id);
  }

  /// Retrieves the saved preferred exam, or null if no preference is saved
  static Future<Exam?> getPreferredExam() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final examJson = prefs.getString(_keyPreferredExam);
      if (examJson != null && examJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(examJson);
        final String docId = data['id'] ?? prefs.getString(_keyPreferredExamId) ?? '';
        return Exam.fromFirestore(data, docId);
      }
    } catch (e) {
      // Return null on parsing or storage errors
    }
    return null;
  }

  /// Retrieves the saved preferred exam ID, or null
  static Future<String?> getPreferredExamId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPreferredExamId);
  }

  /// Clears the user's preferred exam (allows picking a new one from scratch)
  static Future<void> clearPreferredExam() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPreferredExam);
    await prefs.remove(_keyPreferredExamId);
  }
}
