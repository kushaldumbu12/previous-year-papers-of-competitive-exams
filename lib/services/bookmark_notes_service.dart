import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickSubtitleItem {
  final String id;
  final String label;
  final int colorValue;
  final int bgValue;

  QuickSubtitleItem({
    required this.id,
    required this.label,
    required this.colorValue,
    required this.bgValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'color': colorValue,
        'bg': bgValue,
      };

  factory QuickSubtitleItem.fromJson(Map<String, dynamic> json) =>
      QuickSubtitleItem(
        id: json['id'] as String? ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
        label: json['label'] as String? ?? '',
        colorValue: json['color'] as int? ?? 0xFF4338CA,
        bgValue: json['bg'] as int? ?? 0xFFEEF2FF,
      );

  QuickSubtitleItem copyWith({
    String? id,
    String? label,
    int? colorValue,
    int? bgValue,
  }) {
    return QuickSubtitleItem(
      id: id ?? this.id,
      label: label ?? this.label,
      colorValue: colorValue ?? this.colorValue,
      bgValue: bgValue ?? this.bgValue,
    );
  }
}

class NoteItem {
  final String id;
  final String? title;
  final String content;
  final bool isStarred;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteItem({
    required this.id,
    this.title,
    required this.content,
    this.isStarred = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'isStarred': isStarred,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      isStarred: json['isStarred'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NoteItem copyWith({
    String? id,
    String? title,
    String? content,
    bool? isStarred,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isStarred: isStarred ?? this.isStarred,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BookmarkNotesService {
  static final BookmarkNotesService _instance = BookmarkNotesService._internal();
  factory BookmarkNotesService() => _instance;
  BookmarkNotesService._internal();

  /// ValueNotifier to alert screens when bookmarks or notes update locally
  final ValueNotifier<int> updatesNotifier = ValueNotifier<int>(0);

  void _notify() {
    updatesNotifier.value++;
  }

  // --- BOOKMARKS ---

  String _bookmarkKey(String examId, String year) => 'bookmarks_${examId}_$year';

  /// Check if a specific paper is bookmarked
  Future<bool> isPaperBookmarked(String examId, String year, String paperId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_bookmarkKey(examId, year)) ?? [];
      return list.contains(paperId);
    } catch (_) {
      return false;
    }
  }

  /// Toggle bookmark status for a paper. Returns true if now bookmarked, false if unbookmarked.
  Future<bool> toggleBookmark(String examId, String year, String paperId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _bookmarkKey(examId, year);
      List<String> list = List<String>.from(prefs.getStringList(key) ?? []);
      bool isBookmarked;
      if (list.contains(paperId)) {
        list.remove(paperId);
        isBookmarked = false;
      } else {
        list.add(paperId);
        isBookmarked = true;
      }
      await prefs.setStringList(key, list);
      _notify();
      return isBookmarked;
    } catch (_) {
      return false;
    }
  }

  /// Check if any item in a specific year is bookmarked
  Future<bool> hasBookmarksForYear(String examId, String year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_bookmarkKey(examId, year)) ?? [];
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Get list of bookmarked paper IDs for a specific year
  Future<List<String>> getBookmarkedPaperIds(String examId, String year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_bookmarkKey(examId, year)) ?? [];
    } catch (_) {
      return [];
    }
  }

  // --- LOCAL DOWNLOADS (STORED IN APP LOCALLY, NEVER TOUCHES EXTERNAL DISK) ---

  String _downloadsKey(String examId, String year) => 'downloads_${examId}_$year';

  /// Get list of downloaded paper IDs for a specific year
  Future<List<String>> getDownloadedPaperIds(String examId, String year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_downloadsKey(examId, year)) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Toggle download status for a paper locally inside the app
  Future<bool> toggleDownloadMaterial(String examId, String year, String paperId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _downloadsKey(examId, year);
      List<String> list = List<String>.from(prefs.getStringList(key) ?? []);
      bool isDownloaded;
      if (list.contains(paperId)) {
        list.remove(paperId);
        isDownloaded = false;
      } else {
        list.add(paperId);
        isDownloaded = true;
      }
      await prefs.setStringList(key, list);
      _notify();
      return isDownloaded;
    } catch (_) {
      return false;
    }
  }

  /// Check if a specific material is downloaded locally in app
  Future<bool> isMaterialDownloaded(String examId, String year, String paperId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_downloadsKey(examId, year)) ?? [];
      return list.contains(paperId);
    } catch (_) {
      return false;
    }
  }

  // --- MULTIPLE NOTES PER YEAR ---

  String _notesListKey(String examId, String year) => 'notes_list_${examId}_$year';

  /// Retrieve all notes for a specific exam year
  Future<List<NoteItem>> getNotesList(String examId, String year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_notesListKey(examId, year));
      if (raw == null || raw.isEmpty) {
        // Migration from legacy single note format if existing
        final legacyNote = prefs.getString('notes_${examId}_$year');
        if (legacyNote != null && legacyNote.trim().isNotEmpty) {
          final note = NoteItem(
            id: 'note_${DateTime.now().millisecondsSinceEpoch}',
            title: null,
            content: legacyNote.trim(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await saveOrUpdateNote(examId, year, note);
          await prefs.remove('notes_${examId}_$year');
          return [note];
        }
        return [];
      }
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => NoteItem.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  /// Save or update a note item
  Future<void> saveOrUpdateNote(String examId, String year, NoteItem note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = await getNotesList(examId, year);
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        notes[index] = note;
      } else {
        notes.insert(0, note);
      }
      final raw = jsonEncode(notes.map((n) => n.toJson()).toList());
      await prefs.setString(_notesListKey(examId, year), raw);
      _notify();
    } catch (_) {}
  }

  /// Delete a note item
  Future<void> deleteNote(String examId, String year, String noteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = await getNotesList(examId, year);
      notes.removeWhere((n) => n.id == noteId);
      if (notes.isEmpty) {
        await prefs.remove(_notesListKey(examId, year));
      } else {
        final raw = jsonEncode(notes.map((n) => n.toJson()).toList());
        await prefs.setString(_notesListKey(examId, year), raw);
      }
      _notify();
    } catch (_) {}
  }

  /// Toggle starred status of a note
  Future<bool> toggleNoteStarred(String examId, String year, String noteId) async {
    try {
      final notes = await getNotesList(examId, year);
      final index = notes.indexWhere((n) => n.id == noteId);
      if (index >= 0) {
        final current = notes[index];
        final updated = current.copyWith(isStarred: !current.isStarred);
        notes[index] = updated;
        final prefs = await SharedPreferences.getInstance();
        final raw = jsonEncode(notes.map((n) => n.toJson()).toList());
        await prefs.setString(_notesListKey(examId, year), raw);
        _notify();
        return updated.isStarred;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if any notes exist for an exam year
  Future<bool> hasNotes(String examId, String year) async {
    try {
      final notes = await getNotesList(examId, year);
      return notes.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // --- QUICK SUBTITLES / TEMPLATES ---

  static const String _quickSubtitlesKey = 'quick_subtitles_templates';

  static final List<QuickSubtitleItem> defaultQuickSubtitles = [
    QuickSubtitleItem(
      id: 'formula',
      label: '📌 Formula',
      colorValue: 0xFF4338CA,
      bgValue: 0xFFEEF2FF,
    ),
    QuickSubtitleItem(
      id: 'important',
      label: '⭐ Important',
      colorValue: 0xFFB45309,
      bgValue: 0xFFFEF3C7,
    ),
    QuickSubtitleItem(
      id: 'key_answer',
      label: '✔ Key Answer',
      colorValue: 0xFF047857,
      bgValue: 0xFFECFDF5,
    ),
    QuickSubtitleItem(
      id: 'concept',
      label: '💡 Concept',
      colorValue: 0xFF7E22CE,
      bgValue: 0xFFF3E8FF,
    ),
    QuickSubtitleItem(
      id: 'reminder',
      label: '⚠️ Reminder',
      colorValue: 0xFFBE123C,
      bgValue: 0xFFFFE4E6,
    ),
  ];

  Future<List<QuickSubtitleItem>> getQuickSubtitles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_quickSubtitlesKey);
      if (raw == null || raw.isEmpty) {
        return List.from(defaultQuickSubtitles);
      }
      final List<dynamic> list = jsonDecode(raw);
      if (list.isEmpty) return List.from(defaultQuickSubtitles);
      return list
          .map((e) => QuickSubtitleItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List.from(defaultQuickSubtitles);
    }
  }

  Future<void> saveQuickSubtitles(List<QuickSubtitleItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_quickSubtitlesKey, raw);
      _notify();
    } catch (_) {}
  }
}
