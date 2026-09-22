import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/bookmark_notes_service.dart';

/// Style representation for a character range [start, end)
class StyleSpan {
  int start;
  int end;
  bool bold;
  bool italic;
  bool underline;
  int? colorValue;

  StyleSpan({
    required this.start,
    required this.end,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.colorValue,
  });

  bool get isDefault => !bold && !italic && !underline && colorValue == null;

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'bold': bold,
        'italic': italic,
        'underline': underline,
        if (colorValue != null) 'color': colorValue,
      };

  factory StyleSpan.fromJson(Map<String, dynamic> json) => StyleSpan(
        start: json['start'] as int? ?? 0,
        end: json['end'] as int? ?? 0,
        bold: json['bold'] as bool? ?? false,
        italic: json['italic'] as bool? ?? false,
        underline: json['underline'] as bool? ?? false,
        colorValue: json['color'] as int?,
      );

  StyleSpan copyWith({
    int? start,
    int? end,
    bool? bold,
    bool? italic,
    bool? underline,
    int? colorValue,
  }) {
    return StyleSpan(
      start: start ?? this.start,
      end: end ?? this.end,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

/// Rich document data container containing clean plain text and character-level style spans
class RichDocData {
  final String text;
  final List<StyleSpan> spans;

  RichDocData({required this.text, required this.spans});

  static RichDocData fromSerialized(String content) {
    if (content.trim().isEmpty) {
      return RichDocData(text: '', spans: []);
    }
    if (content.startsWith('{"rich_doc":true') ||
        (content.startsWith('{') && content.contains('"rich_doc"'))) {
      try {
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        final text = decoded['text'] as String? ?? '';
        final rawSpans = decoded['spans'] as List<dynamic>? ?? [];
        final spans = rawSpans
            .map((s) => StyleSpan.fromJson(s as Map<String, dynamic>))
            .toList();
        return RichDocData(text: text, spans: spans);
      } catch (_) {}
    }
    // Fallback: Parse legacy markdown string or plain text into clean text + spans
    return parseLegacyMarkdown(content);
  }

  String toSerialized() {
    return jsonEncode({
      'rich_doc': true,
      'text': text,
      'spans': spans.map((s) => s.toJson()).toList(),
    });
  }

  static RichDocData parseLegacyMarkdown(String raw) {
    final buffer = StringBuffer();
    final List<StyleSpan> spans = [];

    // Comprehensive pattern matching all markdown and HTML variations
    final pattern = RegExp(
      r'(\*\*\*(.*?)\*\*\*)|(\*\*(.*?)\*\*)|(\*(?!\s)([^*]+?)(?<!\s)\*)|(<u>(.*?)<\/u>)|(<ins>(.*?)<\/ins>)|(<b>(.*?)<\/b>)|(<strong>(.*?)<\/strong>)|(<i>(.*?)<\/i>)|(<em>(.*?)<\/em>)|(__([^_]+)__)|(_(?!\s)([^_]+?)(?<!\s)_)|(📌[^\n]*)|(⭐[^\n]*)|(✔[^\n]*)|(•[^\n]*)',
      multiLine: true,
    );

    int lastIndex = 0;
    for (final match in pattern.allMatches(raw)) {
      if (match.start > lastIndex) {
        buffer.write(raw.substring(lastIndex, match.start));
      }

      final boldItalicContent = match.group(2);
      final boldContent = match.group(4);
      final italicAsterisk = match.group(6);
      final underlineHtml = match.group(8);
      final underlineIns = match.group(10);
      final boldHtml = match.group(12);
      final boldStrong = match.group(14);
      final italicHtml = match.group(16);
      final italicEm = match.group(18);
      final underlineDunder = match.group(20);
      final italicUnderscore = match.group(22);
      final formulaGroup = match.group(23);
      final starGroup = match.group(24);
      final keyGroup = match.group(25);
      final bulletGroup = match.group(26);

      final startOffset = buffer.length;

      if (boldItalicContent != null) {
        buffer.write(boldItalicContent);
        spans.add(StyleSpan(start: startOffset, end: buffer.length, bold: true, italic: true));
      } else if (boldContent != null) {
        buffer.write(boldContent);
        spans.add(StyleSpan(start: startOffset, end: buffer.length, bold: true));
      } else if (italicAsterisk != null) {
        buffer.write(italicAsterisk);
        spans.add(StyleSpan(start: startOffset, end: buffer.length, italic: true));
      } else if (underlineHtml != null || underlineIns != null) {
        final text = underlineHtml ?? underlineIns!;
        buffer.write(text);
        spans.add(StyleSpan(start: startOffset, end: buffer.length, underline: true));
      } else if (boldHtml != null || boldStrong != null) {
        final text = boldHtml ?? boldStrong!;
        buffer.write(text);
        spans.add(StyleSpan(start: startOffset, end: buffer.length, bold: true));
      } else if (italicHtml != null || italicEm != null) {
        final text = italicHtml ?? italicEm!;
        buffer.write(text);
        spans.add(StyleSpan(start: startOffset, end: buffer.length, italic: true));
      } else if (underlineDunder != null) {
        buffer.write(underlineDunder);
        spans.add(StyleSpan(start: startOffset, end: buffer.length, underline: true));
      } else if (italicUnderscore != null) {
        buffer.write(italicUnderscore);
        spans.add(StyleSpan(start: startOffset, end: buffer.length, italic: true));
      } else if (formulaGroup != null) {
        buffer.write(formulaGroup);
        spans.add(StyleSpan(
            start: startOffset,
            end: buffer.length,
            bold: true,
            colorValue: 0xFF4338CA));
      } else if (starGroup != null) {
        buffer.write(starGroup);
        spans.add(StyleSpan(
            start: startOffset,
            end: buffer.length,
            bold: true,
            colorValue: 0xFFB45309));
      } else if (keyGroup != null) {
        buffer.write(keyGroup);
        spans.add(StyleSpan(
            start: startOffset,
            end: buffer.length,
            bold: true,
            colorValue: 0xFF047857));
      } else if (bulletGroup != null) {
        buffer.write(bulletGroup);
        spans.add(StyleSpan(start: startOffset, end: buffer.length, bold: false));
      }

      lastIndex = match.end;
    }

    if (lastIndex < raw.length) {
      buffer.write(raw.substring(lastIndex));
    }

    return RichDocData(text: buffer.toString(), spans: spans);
  }
}

/// Helper to render clean Rich Text from a serialized note content
TextSpan buildRichTextSpan(String content, TextStyle baseStyle) {
  final doc = RichDocData.fromSerialized(content);
  final text = doc.text;
  if (text.isEmpty) return TextSpan(style: baseStyle);
  if (doc.spans.isEmpty) return TextSpan(text: text, style: baseStyle);

  final Set<int> boundaries = {0, text.length};
  for (final span in doc.spans) {
    boundaries.add(span.start.clamp(0, text.length));
    boundaries.add(span.end.clamp(0, text.length));
  }
  final sorted = boundaries.toList()..sort();

  final List<InlineSpan> inlineSpans = [];
  for (int i = 0; i < sorted.length - 1; i++) {
    final segStart = sorted[i];
    final segEnd = sorted[i + 1];
    if (segStart >= segEnd) continue;

    final segText = text.substring(segStart, segEnd);

    bool bold = false;
    bool italic = false;
    bool underline = false;
    int? colorVal;

    for (final span in doc.spans) {
      if (span.start <= segStart && span.end >= segEnd) {
        if (span.bold) bold = true;
        if (span.italic) italic = true;
        if (span.underline) underline = true;
        if (span.colorValue != null) colorVal = span.colorValue;
      }
    }

    TextStyle style = baseStyle;
    if (bold) {
      style = style.copyWith(
        fontWeight: FontWeight.w900,
        color: colorVal != null ? Color(colorVal) : const Color(0xFF0F172A),
      );
    } else if (colorVal != null) {
      style = style.copyWith(
        fontWeight: FontWeight.w700,
        color: Color(colorVal),
      );
    }
    if (italic) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (underline) {
      style = style.copyWith(
        decoration: TextDecoration.underline,
        decorationColor:
            colorVal != null ? Color(colorVal) : const Color(0xFF4F46E5),
      );
    }

    inlineSpans.add(TextSpan(text: segText, style: style));
  }

  return TextSpan(children: inlineSpans);
}

/// Word-document-like Rich Text Editing Controller
/// Operates directly on clean plain text with character-level attributed styles.
/// Zero raw markdown or HTML tags are inserted into the text stream.
class WordDocumentEditingController extends TextEditingController {
  List<StyleSpan> spans = [];
  String _previousText = '';

  bool isBoldActive = false;
  bool isItalicActive = false;
  bool isUnderlineActive = false;

  VoidCallback? onFormatStateChanged;

  WordDocumentEditingController({String? initialContent}) {
    if (initialContent != null && initialContent.isNotEmpty) {
      final doc = RichDocData.fromSerialized(initialContent);
      text = doc.text;
      spans = List.from(doc.spans);
      _previousText = doc.text;
    } else {
      _previousText = '';
    }
  }

  void loadContent(String content) {
    final doc = RichDocData.fromSerialized(content);
    _previousText = doc.text;
    spans = List.from(doc.spans);
    value = TextEditingValue(
      text: doc.text,
      selection: TextSelection.collapsed(offset: doc.text.length),
    );
    _syncFormatFromCursor(value.selection);
  }

  String getSerializedContent() {
    spans = _mergeAdjacentSpans(spans, text.length);
    return RichDocData(text: text, spans: spans).toSerialized();
  }

  static List<StyleSpan> _mergeAdjacentSpans(List<StyleSpan> raw, int maxLen) {
    if (raw.isEmpty) return [];
    final list = List<StyleSpan>.from(raw)
      ..removeWhere((s) => s.start >= s.end || s.start >= maxLen)
      ..sort((a, b) => a.start.compareTo(b.start));

    final List<StyleSpan> merged = [];
    for (final span in list) {
      span.start = span.start.clamp(0, maxLen);
      span.end = span.end.clamp(0, maxLen);
      if (span.start >= span.end) continue;

      if (merged.isNotEmpty) {
        final last = merged.last;
        if (last.end >= span.start &&
            last.bold == span.bold &&
            last.italic == span.italic &&
            last.underline == span.underline &&
            last.colorValue == span.colorValue) {
          last.end = span.end > last.end ? span.end : last.end;
          continue;
        }
      }
      merged.add(span.copyWith());
    }
    return merged;
  }

  bool _spanMatchesActive(StyleSpan span) {
    if (span.colorValue != null) return false;
    return span.bold == isBoldActive &&
        span.italic == isItalicActive &&
        span.underline == isUnderlineActive;
  }

  int _lastSyncedOffset = -1;

  @override
  set value(TextEditingValue newValue) {
    final oldText = _previousText;
    String newText = newValue.text;

    // Auto-strip any typed or pasted markdown/HTML markers and convert directly to rich spans
    final hasMarkup = (newText.contains('**') ||
        newText.contains('<u>') ||
        newText.contains('</u>') ||
        newText.contains('<b>') ||
        newText.contains('</b>') ||
        newText.contains('<i>') ||
        newText.contains('</i>') ||
        newText.contains('<strong>') ||
        newText.contains('</strong>') ||
        newText.contains('<em>') ||
        newText.contains('</em>') ||
        newText.contains('__'));

    if (hasMarkup) {
      final doc = RichDocData.parseLegacyMarkdown(newText);
      newText = doc.text;
      spans = _mergeAdjacentSpans([...spans, ...doc.spans], newText.length);
      _previousText = newText;
      _lastSyncedOffset = newValue.selection.baseOffset.clamp(0, newText.length);
      super.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: _lastSyncedOffset),
      );
      return;
    }

    if (oldText != newText) {
      _handleTextDiff(oldText, newText);
      _previousText = newText;
      _lastSyncedOffset = newValue.selection.baseOffset;
    } else if (newValue.selection != selection) {
      if (newValue.selection.baseOffset != _lastSyncedOffset) {
        _syncFormatFromCursor(newValue.selection);
      }
    }

    super.value = newValue;
  }

  void _syncFormatFromCursor(TextSelection sel) {
    if (!sel.isValid) return;
    _lastSyncedOffset = sel.baseOffset;

    if (sel.isCollapsed) {
      final pos = sel.baseOffset;
      if (pos > 0 && pos <= text.length) {
        final checkPos = pos - 1;
        bool b = false, i = false, u = false;
        for (final span in spans) {
          if (span.start <= checkPos && span.end > checkPos) {
            if (span.bold) b = true;
            if (span.italic) i = true;
            if (span.underline) u = true;
          }
        }
        isBoldActive = b;
        isItalicActive = i;
        isUnderlineActive = u;
      } else {
        isBoldActive = false;
        isItalicActive = false;
        isUnderlineActive = false;
      }
    } else {
      final selStart = sel.start;
      final selEnd = sel.end;
      bool b = false, i = false, u = false;
      for (final span in spans) {
        if (span.start < selEnd && span.end > selStart) {
          if (span.bold) b = true;
          if (span.italic) i = true;
          if (span.underline) u = true;
        }
      }
      isBoldActive = b;
      isItalicActive = i;
      isUnderlineActive = u;
    }
    onFormatStateChanged?.call();
  }

  void _handleTextDiff(String oldText, String newText) {
    final oldLen = oldText.length;
    final newLen = newText.length;

    int prefix = 0;
    while (prefix < oldLen &&
        prefix < newLen &&
        oldText[prefix] == newText[prefix]) {
      prefix++;
    }

    int suffix = 0;
    while (suffix < (oldLen - prefix) &&
        suffix < (newLen - prefix) &&
        oldText[oldLen - 1 - suffix] == newText[newLen - 1 - suffix]) {
      suffix++;
    }

    final deletedStart = prefix;
    final deletedEnd = oldLen - suffix;
    final deletedCount = deletedEnd - deletedStart;

    final insertedStart = prefix;
    final insertedEnd = newLen - suffix;
    final insertedCount = insertedEnd - insertedStart;

    final diff = insertedCount - deletedCount;

    final updatedSpans = <StyleSpan>[];

    for (final span in spans) {
      if (deletedCount > 0) {
        if (span.end <= deletedStart) {
          updatedSpans.add(span);
        } else if (span.start >= deletedEnd) {
          span.start = (span.start + diff).clamp(0, newLen);
          span.end = (span.end + diff).clamp(0, newLen);
          if (span.start < span.end) updatedSpans.add(span);
        } else {
          final newStart = span.start < deletedStart
              ? span.start
              : deletedStart;
          final newEnd = span.end > deletedEnd
              ? span.end + diff
              : deletedStart;
          span.start = newStart.clamp(0, newLen);
          span.end = newEnd.clamp(0, newLen);
          if (span.start < span.end) updatedSpans.add(span);
        }
      } else {
        if (span.end < insertedStart) {
          updatedSpans.add(span);
        } else if (span.start > insertedStart) {
          span.start = (span.start + insertedCount).clamp(0, newLen);
          span.end = (span.end + insertedCount).clamp(0, newLen);
          updatedSpans.add(span);
        } else if (span.start == insertedStart) {
          if (_spanMatchesActive(span)) {
            span.end = (span.end + insertedCount).clamp(0, newLen);
          } else {
            span.start = (span.start + insertedCount).clamp(0, newLen);
            span.end = (span.end + insertedCount).clamp(0, newLen);
          }
          updatedSpans.add(span);
        } else if (span.end == insertedStart) {
          if (_spanMatchesActive(span)) {
            span.end = (span.end + insertedCount).clamp(0, newLen);
          }
          updatedSpans.add(span);
        } else {
          if (_spanMatchesActive(span)) {
            span.end = (span.end + insertedCount).clamp(0, newLen);
            updatedSpans.add(span);
          } else {
            final first = span.copyWith(end: insertedStart);
            final second = span.copyWith(
              start: (insertedStart + insertedCount).clamp(0, newLen),
              end: (span.end + insertedCount).clamp(0, newLen),
            );
            if (first.start < first.end) updatedSpans.add(first);
            if (second.start < second.end) updatedSpans.add(second);
          }
        }
      }
    }

    if (insertedCount > 0 &&
        (isBoldActive || isItalicActive || isUnderlineActive)) {
      updatedSpans.add(StyleSpan(
        start: insertedStart,
        end: insertedEnd,
        bold: isBoldActive,
        italic: isItalicActive,
        underline: isUnderlineActive,
      ));
    }

    spans = _mergeAdjacentSpans(updatedSpans, newLen);
  }

  void toggleBold() {
    if (selection.isValid && !selection.isCollapsed) {
      _toggleStyleForSelection((span) => span.bold, (span, val) => span.bold = val);
    } else {
      isBoldActive = !isBoldActive;
    }
    _lastSyncedOffset = selection.baseOffset;
    notifyListeners();
    onFormatStateChanged?.call();
  }

  void toggleItalic() {
    if (selection.isValid && !selection.isCollapsed) {
      _toggleStyleForSelection((span) => span.italic, (span, val) => span.italic = val);
    } else {
      isItalicActive = !isItalicActive;
    }
    _lastSyncedOffset = selection.baseOffset;
    notifyListeners();
    onFormatStateChanged?.call();
  }

  void toggleUnderline() {
    if (selection.isValid && !selection.isCollapsed) {
      _toggleStyleForSelection((span) => span.underline, (span, val) => span.underline = val);
    } else {
      isUnderlineActive = !isUnderlineActive;
    }
    _lastSyncedOffset = selection.baseOffset;
    notifyListeners();
    onFormatStateChanged?.call();
  }

  void _toggleStyleForSelection(
    bool Function(StyleSpan) getter,
    void Function(StyleSpan, bool) setter,
  ) {
    final selStart = selection.start;
    final selEnd = selection.end;
    if (selStart >= selEnd) return;

    bool allFormatted = true;
    for (int i = selStart; i < selEnd; i++) {
      bool charHasStyle = false;
      for (final span in spans) {
        if (span.start <= i && span.end > i && getter(span)) {
          charHasStyle = true;
          break;
        }
      }
      if (!charHasStyle) {
        allFormatted = false;
        break;
      }
    }

    final targetVal = !allFormatted;

    final updated = <StyleSpan>[];
    for (final span in spans) {
      if (span.end <= selStart || span.start >= selEnd) {
        updated.add(span);
      } else {
        if (span.start < selStart) {
          updated.add(span.copyWith(end: selStart));
        }
        if (span.end > selEnd) {
          updated.add(span.copyWith(start: selEnd));
        }
        final innerStart = span.start < selStart ? selStart : span.start;
        final innerEnd = span.end > selEnd ? selEnd : span.end;
        if (innerStart < innerEnd) {
          final innerSpan = span.copyWith(start: innerStart, end: innerEnd);
          setter(innerSpan, targetVal);
          if (!innerSpan.isDefault) {
            updated.add(innerSpan);
          }
        }
      }
    }

    if (targetVal) {
      final newSpan = StyleSpan(
        start: selStart,
        end: selEnd,
        bold: getter == (s) => s.bold ? true : isBoldActive,
        italic: getter == (s) => s.italic ? true : isItalicActive,
        underline: getter == (s) => s.underline ? true : isUnderlineActive,
      );
      setter(newSpan, true);
      updated.add(newSpan);
    }

    spans = _mergeAdjacentSpans(updated, text.length);
    if (getter == (s) => s.bold) isBoldActive = targetVal;
    if (getter == (s) => s.italic) isItalicActive = targetVal;
    if (getter == (s) => s.underline) isUnderlineActive = targetVal;
    _lastSyncedOffset = selection.baseOffset;
  }

  void insertBulletList() {
    final curText = text;
    final pos = selection.isValid ? selection.baseOffset : curText.length;
    final lineStart = curText.lastIndexOf('\n', pos > 0 ? pos - 1 : 0);
    final insertPos = lineStart == -1 ? 0 : lineStart + 1;

    const bullet = '• ';
    final newText = curText.replaceRange(insertPos, insertPos, bullet);
    _previousText = newText;
    _lastSyncedOffset = pos + bullet.length;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: _lastSyncedOffset),
    );
    notifyListeners();
  }

  void insertChipPrompt(String label, {int? colorValue}) {
    final curText = text;
    final pos = (selection.isValid && selection.baseOffset >= 0 && selection.baseOffset <= curText.length)
        ? selection.baseOffset
        : curText.length;

    final insertText = '$label ';
    final newText = curText.replaceRange(pos, pos, insertText);

    final updatedSpans = <StyleSpan>[];
    for (final span in spans) {
      if (span.end <= pos) {
        updatedSpans.add(span);
      } else if (span.start >= pos) {
        updatedSpans.add(span.copyWith(
          start: span.start + insertText.length,
          end: span.end + insertText.length,
        ));
      } else {
        updatedSpans.add(span.copyWith(
          end: span.end + insertText.length,
        ));
      }
    }

    updatedSpans.add(StyleSpan(
      start: pos,
      end: pos + insertText.length,
      bold: true,
      colorValue: colorValue,
    ));

    spans = _mergeAdjacentSpans(updatedSpans, newText.length);
    _previousText = newText;
    _lastSyncedOffset = pos + insertText.length;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: _lastSyncedOffset),
    );
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final currentText = text;
    final baseStyle = style ??
        const TextStyle(
          fontSize: 15,
          color: Color(0xFF1E293B),
          height: 1.5,
        );

    if (currentText.isEmpty) {
      return TextSpan(style: baseStyle);
    }

    if (spans.isEmpty) {
      return TextSpan(text: currentText, style: baseStyle);
    }

    final Set<int> boundaries = {0, currentText.length};
    for (final span in spans) {
      boundaries.add(span.start.clamp(0, currentText.length));
      boundaries.add(span.end.clamp(0, currentText.length));
    }
    final sorted = boundaries.toList()..sort();

    final List<InlineSpan> inlineSpans = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final segStart = sorted[i];
      final segEnd = sorted[i + 1];
      if (segStart >= segEnd) continue;

      final segText = currentText.substring(segStart, segEnd);

      bool bold = false;
      bool italic = false;
      bool underline = false;
      int? colorVal;

      for (final span in spans) {
        if (span.start <= segStart && span.end >= segEnd) {
          if (span.bold) bold = true;
          if (span.italic) italic = true;
          if (span.underline) underline = true;
          if (span.colorValue != null) colorVal = span.colorValue;
        }
      }

      TextStyle segStyle = baseStyle;
      if (bold) {
        segStyle = segStyle.copyWith(
          fontWeight: FontWeight.w900,
          color: colorVal != null ? Color(colorVal) : const Color(0xFF0F172A),
        );
      } else if (colorVal != null) {
        segStyle = segStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: Color(colorVal),
        );
      }
      if (italic) {
        segStyle = segStyle.copyWith(fontStyle: FontStyle.italic);
      }
      if (underline) {
        segStyle = segStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: colorVal != null
              ? Color(colorVal)
              : const Color(0xFF4F46E5),
        );
      }

      inlineSpans.add(TextSpan(text: segText, style: segStyle));
    }

    return TextSpan(children: inlineSpans);
  }
}

class YearNotesModal extends StatefulWidget {
  final String examId;
  final String examTitle;
  final String year;

  const YearNotesModal({
    super.key,
    required this.examId,
    required this.examTitle,
    required this.year,
  });

  static Future<void> show(
    BuildContext context, {
    required String examId,
    required String examTitle,
    required String year,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => YearNotesModal(
        examId: examId,
        examTitle: examTitle,
        year: year,
      ),
    );
  }

  @override
  State<YearNotesModal> createState() => _YearNotesModalState();
}

enum _NotesViewMode { list, view, edit }

class _YearNotesModalState extends State<YearNotesModal> {
  final BookmarkNotesService _service = BookmarkNotesService();
  _NotesViewMode _mode = _NotesViewMode.list;

  List<NoteItem> _notes = [];
  List<QuickSubtitleItem> _quickSubtitles = [];
  bool _isLoading = true;

  NoteItem? _selectedNote;
  NoteItem? _editingNote;
  String? _activeMenuNoteId;
  final TextEditingController _titleController = TextEditingController();
  late final WordDocumentEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contentController = WordDocumentEditingController();
    _contentController.onFormatStateChanged = () {
      if (mounted) setState(() {});
    };
    _loadNotes();
    _loadQuickSubtitles();
  }

  Future<void> _loadQuickSubtitles() async {
    final list = await _service.getQuickSubtitles();
    if (mounted) {
      setState(() => _quickSubtitles = list);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final list = await _service.getNotesList(widget.examId, widget.year);
    if (mounted) {
      setState(() {
        _notes = list;
        _isLoading = false;
        if (_selectedNote != null) {
          final updated =
              list.where((n) => n.id == _selectedNote!.id).firstOrNull;
          if (updated != null) {
            _selectedNote = updated;
          }
        }
      });
    }
  }

  void _startAddNote() {
    setState(() {
      _editingNote = null;
      _titleController.clear();
      _contentController.clear();
      _contentController.spans = [];
      _mode = _NotesViewMode.edit;
    });
  }

  void _startEditNote(NoteItem note) {
    setState(() {
      _editingNote = note;
      _titleController.text = note.title ?? '';
      _contentController.loadContent(note.content);
      _mode = _NotesViewMode.edit;
    });
  }

  void _openNoteView(NoteItem note) {
    setState(() {
      _selectedNote = note;
      _mode = _NotesViewMode.view;
    });
  }

  Future<void> _toggleStar(NoteItem note) async {
    final newStarred =
        await _service.toggleNoteStarred(widget.examId, widget.year, note.id);
    setState(() {
      if (_selectedNote?.id == note.id) {
        _selectedNote = _selectedNote!.copyWith(isStarred: newStarred);
      }
      final idx = _notes.indexWhere((n) => n.id == note.id);
      if (idx >= 0) {
        _notes[idx] = _notes[idx].copyWith(isStarred: newStarred);
      }
    });
  }

  Future<void> _saveCurrentNote() async {
    final rawText = _contentController.text.trim();
    final title = _titleController.text.trim().isEmpty
        ? null
        : _titleController.text.trim();

    if (rawText.isEmpty && (title == null || title.isEmpty)) {
      setState(() => _mode = _NotesViewMode.list);
      return;
    }

    setState(() => _isSaving = true);

    final serializedContent = _contentController.getSerializedContent();

    final note = NoteItem(
      id: _editingNote?.id ?? 'note_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: serializedContent,
      isStarred: _editingNote?.isStarred ?? false,
      createdAt: _editingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _service.saveOrUpdateNote(widget.examId, widget.year, note);
    await _loadNotes();

    if (mounted) {
      setState(() {
        _isSaving = false;
        _selectedNote = note;
        _mode = _NotesViewMode.view;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 18),
              SizedBox(width: 8),
              Text('Note saved locally',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text(
            'Are you sure you want to delete this note? This cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteNote(widget.examId, widget.year, noteId);
      await _loadNotes();
      if (mounted) {
        setState(() {
          _selectedNote = null;
          _mode = _NotesViewMode.list;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      constraints: BoxConstraints(
        maxHeight: isKeyboardOpen
            ? screenHeight * 0.95
            : (_mode == _NotesViewMode.view || _mode == _NotesViewMode.edit
                ? screenHeight * 0.90
                : screenHeight * 0.85),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (_mode == _NotesViewMode.list)
              _buildListHeader()
            else if (_mode == _NotesViewMode.view)
              _buildViewHeader()
            else
              _buildEditHeader(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4F46E5), strokeWidth: 2),
                    )
                  : (_mode == _NotesViewMode.list
                      ? _buildNotesListView()
                      : (_mode == _NotesViewMode.view
                          ? _buildReadOnlyView()
                          : _buildNoteEditor())),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. NOTES LIST VIEW & HEADER
  // ===========================================================================

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 12, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sticky_note_2_rounded,
              color: Color(0xFF4F46E5),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes • ${widget.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  widget.examTitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _startAddNote,
            icon: const Icon(
              Icons.add_rounded,
              color: Color(0xFF4F46E5),
              size: 26,
            ),
            tooltip: 'Add Note',
          ),
        ],
      ),
    );
  }

  Widget _buildNotesListView() {
    if (_notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  size: 40,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No Notes Added Yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap the + icon above to add important points, formulas, or reminders for this year.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final note = _notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(NoteItem note) {
    final title = note.title;
    final hasTitle = title != null && title.trim().isNotEmpty;
    final isStarred = note.isStarred;
    final isMenuOpen = _activeMenuNoteId == note.id;

    return GestureDetector(
      onTap: () {
        if (_activeMenuNoteId != null) {
          setState(() => _activeMenuNoteId = null);
        } else {
          _openNoteView(note);
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: isStarred
              ? const Color(0xFFFFFBEB)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isStarred
                ? const Color(0xFFFDE68A)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _toggleStar(note),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 22,
                      color: isStarred
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasTitle) ...[
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text.rich(
                        buildRichTextSpan(
                          note.content,
                          const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(note.updatedAt),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Options',
                  onPressed: () {
                    setState(() {
                      if (_activeMenuNoteId == note.id) {
                        _activeMenuNoteId = null;
                      } else {
                        _activeMenuNoteId = note.id;
                      }
                    });
                  },
                ),
              ],
            ),
            if (isMenuOpen)
              Positioned(
                top: 0,
                right: 20,
                child: Material(
                  elevation: 6,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() => _activeMenuNoteId = null);
                            _startEditNote(note);
                          },
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded, size: 15, color: Color(0xFF4F46E5)),
                                SizedBox(width: 8),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                        InkWell(
                          onTap: () {
                            setState(() => _activeMenuNoteId = null);
                            _deleteNote(note.id);
                          },
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. READ-ONLY FULL BOTTOM PAGE VIEW & HEADER
  // ===========================================================================

  Widget _buildViewHeader() {
    final isStarred = _selectedNote?.isStarred ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _mode = _NotesViewMode.list),
            icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF1E293B), size: 20),
            tooltip: 'Back to Notes',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _selectedNote?.updatedAt != null
                  ? _formatDate(_selectedNote!.updatedAt)
                  : 'Note',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          if (_selectedNote != null) ...[
            IconButton(
              onPressed: () => _toggleStar(_selectedNote!),
              icon: Icon(
                isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                color: isStarred
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF94A3B8),
                size: 24,
              ),
              tooltip: isStarred ? 'Starred' : 'Star Note',
            ),
            IconButton(
              onPressed: () => _startEditNote(_selectedNote!),
              icon: const Icon(Icons.edit_rounded,
                  color: Color(0xFF4F46E5), size: 20),
              tooltip: 'Edit Note',
            ),
            IconButton(
              onPressed: () => _deleteNote(_selectedNote!.id),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 20),
              tooltip: 'Delete Note',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyView() {
    if (_selectedNote == null) {
      return const SizedBox.shrink();
    }

    final note = _selectedNote!;
    final hasTitle = note.title != null && note.title!.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle) ...[
            Text(
              note.title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),
          ],
          Text.rich(
            buildRichTextSpan(
              note.content,
              const TextStyle(
                fontSize: 15,
                color: Color(0xFF1E293B),
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. EDIT NOTE VIEW & HEADER (WORD-LIKE WYSIWYG)
  // ===========================================================================

  Widget _buildEditHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _mode = _NotesViewMode.list),
            icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF1E293B), size: 20),
            tooltip: 'Cancel',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _editingNote != null ? 'Edit Note' : 'New Note',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveCurrentNote,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteEditor() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
          child: TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
            decoration: const InputDecoration(
              hintText: 'Title (Optional)',
              hintStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: TextField(
              controller: _contentController,
              focusNode: _contentFocusNode,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1E293B),
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText: 'Type your notes, formulas, or reminders here...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildWordFormatBtn(
                  label: 'B',
                  isActive: _contentController.isBoldActive,
                  isBold: true,
                  tooltip: 'Bold',
                  onTap: () {
                    _contentController.toggleBold();
                    _contentFocusNode.requestFocus();
                  },
                ),
                const SizedBox(width: 6),
                _buildWordFormatBtn(
                  label: 'I',
                  isActive: _contentController.isItalicActive,
                  isItalic: true,
                  tooltip: 'Italic',
                  onTap: () {
                    _contentController.toggleItalic();
                    _contentFocusNode.requestFocus();
                  },
                ),
                const SizedBox(width: 6),
                _buildWordFormatBtn(
                  label: 'U',
                  isActive: _contentController.isUnderlineActive,
                  isUnderline: true,
                  tooltip: 'Underline',
                  onTap: () {
                    _contentController.toggleUnderline();
                    _contentFocusNode.requestFocus();
                  },
                ),
                const SizedBox(width: 6),
                _buildWordFormatBtn(
                  label: '• List',
                  isActive: false,
                  tooltip: 'Bullet List',
                  onTap: () {
                    _contentController.insertBulletList();
                    _contentFocusNode.requestFocus();
                  },
                ),
                const SizedBox(width: 8),
                Container(
                    height: 20, width: 1, color: const Color(0xFFCBD5E1)),
                const SizedBox(width: 8),
                ..._quickSubtitles.map((sub) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildChipPrompt(
                        label: sub.label,
                        color: Color(sub.bgValue),
                        textColor: Color(sub.colorValue),
                        onTap: () {
                          _contentController.insertChipPrompt(
                            sub.label,
                            colorValue: sub.colorValue,
                          );
                          _contentFocusNode.requestFocus();
                        },
                      ),
                    )),
                // Plus icon button to Add Subtitle
                InkWell(
                  onTap: _showAddSubtitleDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Pencil icon button to Manage/Edit Subtitles
                InkWell(
                  onTap: _showManageSubtitlesDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSubtitleDialog() {
    final titleCtrl = TextEditingController();
    int selectedColor = 0xFF4338CA;
    int selectedBg = 0xFFEEF2FF;

    final palette = [
      {'name': 'Indigo', 'color': 0xFF4338CA, 'bg': 0xFFEEF2FF},
      {'name': 'Amber', 'color': 0xFFB45309, 'bg': 0xFFFEF3C7},
      {'name': 'Emerald', 'color': 0xFF047857, 'bg': 0xFFECFDF5},
      {'name': 'Purple', 'color': 0xFF7E22CE, 'bg': 0xFFF3E8FF},
      {'name': 'Rose', 'color': 0xFFBE123C, 'bg': 0xFFFFE4E6},
      {'name': 'Sky', 'color': 0xFF0369A1, 'bg': 0xFFE0F2FE},
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Quick Subtitle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. 🎯 Goal or 📝 Summary',
                  labelText: 'Subtitle Label',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Theme Color',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: palette.map((p) {
                  final isSel = selectedColor == p['color'];
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedColor = p['color'] as int;
                        selectedBg = p['bg'] as int;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(p['color'] as int),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? Colors.black87 : Colors.transparent,
                          width: isSel ? 2.5 : 0,
                        ),
                      ),
                      child: isSel
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final label = titleCtrl.text.trim();
                if (label.isEmpty) return;
                final newItem = QuickSubtitleItem(
                  id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                  label: label,
                  colorValue: selectedColor,
                  bgValue: selectedBg,
                );
                final updated = [..._quickSubtitles, newItem];
                await _service.saveQuickSubtitles(updated);
                setState(() => _quickSubtitles = updated);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                _contentFocusNode.requestFocus();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageSubtitlesDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Manage Subtitles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              TextButton(
                onPressed: () async {
                  final reset = List<QuickSubtitleItem>.from(
                      BookmarkNotesService.defaultQuickSubtitles);
                  await _service.saveQuickSubtitles(reset);
                  setState(() => _quickSubtitles = reset);
                  setDialogState(() {});
                },
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _quickSubtitles.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (ctx, idx) {
                final item = _quickSubtitles[idx];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(item.bgValue),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(item.colorValue),
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded,
                            size: 18, color: Color(0xFF4F46E5)),
                        onPressed: () => _showEditSubtitleDialog(item),
                      ),
                      if (_quickSubtitles.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Color(0xFFEF4444)),
                          onPressed: () async {
                            final updated =
                                List<QuickSubtitleItem>.from(_quickSubtitles)
                                  ..removeAt(idx);
                            await _service.saveQuickSubtitles(updated);
                            setState(() => _quickSubtitles = updated);
                            setDialogState(() {});
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _contentFocusNode.requestFocus();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubtitleDialog(QuickSubtitleItem item) {
    final titleCtrl = TextEditingController(text: item.label);
    int selectedColor = item.colorValue;
    int selectedBg = item.bgValue;

    final palette = [
      {'name': 'Indigo', 'color': 0xFF4338CA, 'bg': 0xFFEEF2FF},
      {'name': 'Amber', 'color': 0xFFB45309, 'bg': 0xFFFEF3C7},
      {'name': 'Emerald', 'color': 0xFF047857, 'bg': 0xFFECFDF5},
      {'name': 'Purple', 'color': 0xFF7E22CE, 'bg': 0xFFF3E8FF},
      {'name': 'Rose', 'color': 0xFFBE123C, 'bg': 0xFFFFE4E6},
      {'name': 'Sky', 'color': 0xFF0369A1, 'bg': 0xFFE0F2FE},
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Quick Subtitle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Subtitle Label',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Theme Color',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: palette.map((p) {
                  final isSel = selectedColor == p['color'];
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedColor = p['color'] as int;
                        selectedBg = p['bg'] as int;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(p['color'] as int),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? Colors.black87 : Colors.transparent,
                          width: isSel ? 2.5 : 0,
                        ),
                      ),
                      child: isSel
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final label = titleCtrl.text.trim();
                if (label.isEmpty) return;
                final updatedItem = item.copyWith(
                  label: label,
                  colorValue: selectedColor,
                  bgValue: selectedBg,
                );
                final updated = _quickSubtitles.map((s) {
                  return s.id == item.id ? updatedItem : s;
                }).toList();
                await _service.saveQuickSubtitles(updated);
                setState(() => _quickSubtitles = updated);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                _contentFocusNode.requestFocus();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordFormatBtn({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? const Color(0xFF6366F1)
                : const Color(0xFFCBD5E1),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration:
                isUnderline ? TextDecoration.underline : TextDecoration.none,
            decorationColor:
                isActive ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
            color:
                isActive ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildChipPrompt({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
