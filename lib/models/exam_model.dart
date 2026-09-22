import 'package:cloud_firestore/cloud_firestore.dart';

class Exam {
  final String id;
  final String name;
  final String categoryId;
  final bool isHidden;
  final String title;
  final String shortCode;
  final String category;
  final String conductingBody;
  final String description;
  final String iconName;
  final int totalPapersCount;
  final List<String> availableYears;
  final String badgeText;
  final int order;

  const Exam({
    required this.id,
    String? name,
    String? categoryId,
    this.isHidden = false,
    String? title,
    String? shortCode,
    String? category,
    this.conductingBody = '',
    this.description = '',
    this.iconName = 'school',
    this.totalPapersCount = 0,
    this.availableYears = const [],
    this.badgeText = '',
    this.order = 0,
  })  : name = name ?? title ?? id,
        categoryId = categoryId ?? category ?? 'general',
        title = title ?? name ?? id,
        shortCode = shortCode ?? name ?? id,
        category = category ?? categoryId ?? 'General';

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'categoryId': categoryId,
      'isHidden': isHidden,
      'title': title,
      'shortCode': shortCode,
      'category': category,
      'conductingBody': conductingBody,
      'description': description,
      'iconName': iconName,
      'totalPapersCount': totalPapersCount,
      'availableYears': availableYears,
      'badgeText': badgeText,
      'order': order,
    };
  }

  factory Exam.fromFirestore(Map<String, dynamic> data, [String docId = '']) {
    final name = (data['name'] ?? data['title'] ?? docId).toString();
    final id = docId.isNotEmpty ? docId : (data['id'] ?? name.toLowerCase());
    final categoryId = (data['categoryId'] ?? data['category'] ?? 'General').toString();
    final isHidden = data['isHidden'] == true;

    return Exam(
      id: id,
      name: name,
      categoryId: categoryId,
      isHidden: isHidden,
      title: data['title'] ?? name,
      shortCode: data['shortCode'] ?? name,
      category: data['category'] ?? categoryId,
      conductingBody: data['conductingBody'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'school',
      totalPapersCount: (data['totalPapersCount'] is num)
          ? (data['totalPapersCount'] as num).toInt()
          : 0,
      availableYears: data['availableYears'] != null
          ? List<String>.from(data['availableYears'].map((e) => e.toString()))
          : [],
      badgeText: data['badgeText'] ?? '',
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
    );
  }

  Exam copyWith({
    String? id,
    String? name,
    String? categoryId,
    bool? isHidden,
    String? title,
    String? shortCode,
    String? category,
    String? conductingBody,
    String? description,
    String? iconName,
    int? totalPapersCount,
    List<String>? availableYears,
    String? badgeText,
    int? order,
  }) {
    return Exam(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      isHidden: isHidden ?? this.isHidden,
      title: title ?? this.title,
      shortCode: shortCode ?? this.shortCode,
      category: category ?? this.category,
      conductingBody: conductingBody ?? this.conductingBody,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      totalPapersCount: totalPapersCount ?? this.totalPapersCount,
      availableYears: availableYears ?? this.availableYears,
      badgeText: badgeText ?? this.badgeText,
      order: order ?? this.order,
    );
  }
}

class ExamYearInfo {
  final String id;
  final dynamic year; // int or String (e.g. 2025 or "2025")
  final bool isHidden;
  final int papersCount;
  final bool hasAnswerKey;
  final bool hasSolutions;
  final String difficultyLevel;
  final String notificationDate;

  const ExamYearInfo({
    required this.id,
    required this.year,
    this.isHidden = false,
    this.papersCount = 0,
    this.hasAnswerKey = true,
    this.hasSolutions = true,
    this.difficultyLevel = 'Moderate',
    this.notificationDate = '',
  });

  String get yearString => year.toString();

  Map<String, dynamic> toFirestore() {
    return {
      'year': year is int ? year : int.tryParse(year.toString()) ?? year,
      'isHidden': isHidden,
      'papersCount': papersCount,
      'hasAnswerKey': hasAnswerKey,
      'hasSolutions': hasSolutions,
      'difficultyLevel': difficultyLevel,
      'notificationDate': notificationDate,
    };
  }

  factory ExamYearInfo.fromFirestore(Map<String, dynamic> data, [String docId = '']) {
    final rawYear = data['year'] ?? docId;
    return ExamYearInfo(
      id: docId.isNotEmpty ? docId : rawYear.toString(),
      year: rawYear,
      isHidden: data['isHidden'] == true,
      papersCount: (data['papersCount'] is num) ? (data['papersCount'] as num).toInt() : 0,
      hasAnswerKey: data['hasAnswerKey'] ?? true,
      hasSolutions: data['hasSolutions'] ?? true,
      difficultyLevel: data['difficultyLevel'] ?? 'Moderate',
      notificationDate: data['notificationDate'] ?? '',
    );
  }

  ExamYearInfo copyWith({
    String? id,
    dynamic year,
    bool? isHidden,
    int? papersCount,
    bool? hasAnswerKey,
    bool? hasSolutions,
    String? difficultyLevel,
    String? notificationDate,
  }) {
    return ExamYearInfo(
      id: id ?? this.id,
      year: year ?? this.year,
      isHidden: isHidden ?? this.isHidden,
      papersCount: papersCount ?? this.papersCount,
      hasAnswerKey: hasAnswerKey ?? this.hasAnswerKey,
      hasSolutions: hasSolutions ?? this.hasSolutions,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      notificationDate: notificationDate ?? this.notificationDate,
    );
  }
}

class ExamPaper {
  final String id;
  final String examId;
  final String year;
  final String title;
  final String fileUrl;
  final dynamic uploadedAt;
  final bool isHidden;
  final String fileName;
  final String stage;
  final String paperCode;
  final String language;
  final int totalMarks;
  final int durationMinutes;
  final int totalQuestions;
  final double fileSizeMb;
  final bool isOfficial;
  final List<String> topicsCovered;

  const ExamPaper({
    required this.id,
    this.examId = '',
    this.year = '',
    required this.title,
    String? fileUrl,
    String? downloadUrl,
    this.uploadedAt,
    this.isHidden = false,
    this.fileName = '',
    this.stage = 'Full Paper',
    this.paperCode = 'SET-A',
    this.language = 'English & Hindi',
    this.totalMarks = 100,
    this.durationMinutes = 120,
    this.totalQuestions = 100,
    this.fileSizeMb = 2.5,
    this.isOfficial = true,
    this.topicsCovered = const [],
  }) : fileUrl = fileUrl ?? downloadUrl ?? '';

  String get downloadUrl => fileUrl;

  DateTime? get uploadedAtDateTime {
    if (uploadedAt is Timestamp) {
      return (uploadedAt as Timestamp).toDate();
    } else if (uploadedAt is DateTime) {
      return uploadedAt as DateTime;
    }
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt ?? FieldValue.serverTimestamp(),
      'isHidden': isHidden,
      'fileName': fileName,
      'stage': stage,
      'paperCode': paperCode,
      'language': language,
      'totalMarks': totalMarks,
      'durationMinutes': durationMinutes,
      'totalQuestions': totalQuestions,
      'fileSizeMb': fileSizeMb,
      'isOfficial': isOfficial,
      'topicsCovered': topicsCovered,
    };
  }

  factory ExamPaper.fromFirestore(
    Map<String, dynamic> data, [
    String docId = '',
    String examId = '',
    String year = '',
  ]) {
    return ExamPaper(
      id: docId.isNotEmpty ? docId : (data['id'] ?? ''),
      examId: examId.isNotEmpty ? examId : (data['examId'] ?? ''),
      year: year.isNotEmpty ? year : (data['year'] ?? '').toString(),
      title: data['title'] ?? 'Question Paper',
      fileUrl: data['fileUrl'] ?? data['downloadUrl'] ?? '',
      uploadedAt: data['uploadedAt'],
      isHidden: data['isHidden'] == true,
      fileName: data['fileName'] ?? '',
      stage: data['stage'] ?? 'Full Paper',
      paperCode: data['paperCode'] ?? 'SET-A',
      language: data['language'] ?? 'English & Hindi',
      totalMarks: (data['totalMarks'] is num) ? (data['totalMarks'] as num).toInt() : 100,
      durationMinutes:
          (data['durationMinutes'] is num) ? (data['durationMinutes'] as num).toInt() : 120,
      totalQuestions:
          (data['totalQuestions'] is num) ? (data['totalQuestions'] as num).toInt() : 100,
      fileSizeMb: (data['fileSizeMb'] is num)
          ? (data['fileSizeMb'] as num).toDouble()
          : 2.5,
      isOfficial: data['isOfficial'] ?? true,
      topicsCovered: data['topicsCovered'] != null
          ? List<String>.from(data['topicsCovered'].map((e) => e.toString()))
          : const [],
    );
  }

  ExamPaper copyWith({
    String? id,
    String? examId,
    String? year,
    String? title,
    String? fileUrl,
    String? downloadUrl,
    dynamic uploadedAt,
    bool? isHidden,
    String? fileName,
    String? stage,
    String? paperCode,
    String? language,
    int? totalMarks,
    int? durationMinutes,
    int? totalQuestions,
    double? fileSizeMb,
    bool? isOfficial,
    List<String>? topicsCovered,
  }) {
    return ExamPaper(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      year: year ?? this.year,
      title: title ?? this.title,
      fileUrl: fileUrl ?? downloadUrl ?? this.fileUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isHidden: isHidden ?? this.isHidden,
      fileName: fileName ?? this.fileName,
      stage: stage ?? this.stage,
      paperCode: paperCode ?? this.paperCode,
      language: language ?? this.language,
      totalMarks: totalMarks ?? this.totalMarks,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      fileSizeMb: fileSizeMb ?? this.fileSizeMb,
      isOfficial: isOfficial ?? this.isOfficial,
      topicsCovered: topicsCovered ?? this.topicsCovered,
    );
  }
}
