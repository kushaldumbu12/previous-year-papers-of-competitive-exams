import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/exam_model.dart';
import '../data/mock_data.dart';
import 'firebase_storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _db;
  final FirebaseStorageService _storageService;

  FirestoreService({
    FirebaseFirestore? db,
    FirebaseStorageService? storageService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _storageService = storageService ?? FirebaseStorageService();

  // ==========================================
  // CATEGORIES CRUD
  // ==========================================

  Stream<List<CategoryModel>> streamCategories({bool includeHidden = false}) {
    Query query = _db.collection('categories');
    if (!includeHidden) {
      query = query.where('isHidden', isEqualTo: false);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return CategoryModel.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Future<List<CategoryModel>> getCategories({bool includeHidden = false}) async {
    Query query = _db.collection('categories');
    if (!includeHidden) {
      query = query.where('isHidden', isEqualTo: false);
    }
    final snapshot = await query.get();
    final list = snapshot.docs.map((doc) {
      return CategoryModel.fromFirestore(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    }).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<void> saveCategory(CategoryModel category) async {
    final docId = category.id.trim().toLowerCase();
    await _db.collection('categories').doc(docId).set(
          category.toFirestore(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.collection('categories').doc(categoryId).delete();
  }

  Future<void> toggleCategoryVisibility(String categoryId, bool isHidden) async {
    await _db.collection('categories').doc(categoryId).update({'isHidden': isHidden});
  }

  Future<void> reorderCategories(List<CategoryModel> categories) async {
    final batch = _db.batch();
    for (int i = 0; i < categories.length; i++) {
      final docRef = _db.collection('categories').doc(categories[i].id.toLowerCase());
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  // ==========================================
  // EXAMS CRUD
  // ==========================================

  bool _matchesCategory(Exam exam, String categoryId) {
    if (categoryId.isEmpty || categoryId.toLowerCase() == 'all') return true;
    final cleanTarget = categoryId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanExamCatId = exam.categoryId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanExamCat = exam.category.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    return cleanExamCatId == cleanTarget ||
        cleanExamCat == cleanTarget ||
        cleanExamCatId.contains(cleanTarget) ||
        cleanTarget.contains(cleanExamCatId) ||
        cleanExamCat.contains(cleanTarget) ||
        cleanTarget.contains(cleanExamCat);
  }

  Stream<List<Exam>> streamExams({String? categoryId, bool includeHidden = false}) {
    Query query = _db.collection('exams');
    if (!includeHidden) {
      query = query.where('isHidden', isEqualTo: false);
    }
    return query.snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) {
        return Exam.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      if (categoryId != null && categoryId.isNotEmpty && categoryId.toLowerCase() != 'all') {
        list = list.where((exam) => _matchesCategory(exam, categoryId)).toList();
      }

      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Future<List<Exam>> getExams({String? categoryId, bool includeHidden = false}) async {
    Query query = _db.collection('exams');
    if (!includeHidden) {
      query = query.where('isHidden', isEqualTo: false);
    }
    final snapshot = await query.get();
    var list = snapshot.docs.map((doc) {
      return Exam.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();

    if (categoryId != null && categoryId.isNotEmpty && categoryId.toLowerCase() != 'all') {
      list = list.where((exam) => _matchesCategory(exam, categoryId)).toList();
    }

    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<void> saveExam(Exam exam) async {
    final docId = exam.id.trim().toLowerCase();
    await _db.collection('exams').doc(docId).set(
          exam.toFirestore(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteExam(String examId) async {
    final examRef = _db.collection('exams').doc(examId);

    // Delete years subcollection docs
    final yearsSnapshot = await examRef.collection('years').get();
    for (final yearDoc in yearsSnapshot.docs) {
      // Delete materials subcollection docs
      final materialsSnapshot = await yearDoc.reference.collection('materials').get();
      for (final materialDoc in materialsSnapshot.docs) {
        final data = materialDoc.data();
        if (data['fileUrl'] != null) {
          await _storageService.deleteFileByUrl(data['fileUrl']);
        }
        await materialDoc.reference.delete();
      }
      await yearDoc.reference.delete();
    }

    await examRef.delete();
  }

  Future<void> toggleExamVisibility(String examId, bool isHidden) async {
    await _db.collection('exams').doc(examId).update({'isHidden': isHidden});
  }

  Future<void> reorderExams(List<Exam> exams) async {
    final batch = _db.batch();
    for (int i = 0; i < exams.length; i++) {
      final docRef = _db.collection('exams').doc(exams[i].id.toLowerCase());
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  // ==========================================
  // YEARS SUBCOLLECTION CRUD
  // ==========================================

  Stream<List<ExamYearInfo>> streamYears(String examId, {bool includeHidden = false}) {
    Query query = _db.collection('exams').doc(examId.toLowerCase()).collection('years');
    if (!includeHidden) {
      query = query.where('isHidden', isEqualTo: false);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExamYearInfo.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<List<ExamYearInfo>> getYears(String examId, {bool includeHidden = false}) async {
    Query query = _db.collection('exams').doc(examId.toLowerCase()).collection('years');
    if (!includeHidden) {
      query = query.where('isHidden', isEqualTo: false);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return ExamYearInfo.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  Future<void> saveYear(String examId, ExamYearInfo yearInfo) async {
    final yearDocId = yearInfo.id.trim();
    await _db
        .collection('exams')
        .doc(examId.toLowerCase())
        .collection('years')
        .doc(yearDocId)
        .set(yearInfo.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteYear(String examId, String yearId) async {
    final yearRef = _db
        .collection('exams')
        .doc(examId.toLowerCase())
        .collection('years')
        .doc(yearId);

    // Clean up materials inside this year
    final materialsSnapshot = await yearRef.collection('materials').get();
    for (final materialDoc in materialsSnapshot.docs) {
      final data = materialDoc.data();
      if (data['fileUrl'] != null) {
        await _storageService.deleteFileByUrl(data['fileUrl']);
      }
      await materialDoc.reference.delete();
    }

    await yearRef.delete();
  }

  Future<void> toggleYearVisibility(String examId, String yearId, bool isHidden) async {
    await _db
        .collection('exams')
        .doc(examId.toLowerCase())
        .collection('years')
        .doc(yearId)
        .update({'isHidden': isHidden});
  }

  // ==========================================
  // MATERIALS SUBCOLLECTION CRUD
  // ==========================================

  Stream<List<ExamPaper>> streamMaterials(
    String examId,
    String yearId, {
    bool includeHidden = false,
  }) {
    Query query = _db
        .collection('exams')
        .doc(examId.toLowerCase())
        .collection('years')
        .doc(yearId)
        .collection('materials');

    if (!includeHidden) {
      query = query.where('isHidden', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExamPaper.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
          examId,
          yearId,
        );
      }).toList();
    });
  }

  Future<List<ExamPaper>> getMaterials(
    String examId,
    String yearId, {
    bool includeHidden = false,
  }) async {
    Query query = _db
        .collection('exams')
        .doc(examId.toLowerCase())
        .collection('years')
        .doc(yearId)
        .collection('materials');

    if (!includeHidden) {
      query = query.where('isHidden', isEqualTo: false);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return ExamPaper.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
        examId,
        yearId,
      );
    }).toList();
  }

  Future<String> saveMaterial({
    required String examId,
    required String yearId,
    required ExamPaper material,
  }) async {
    final materialsRef = _db
        .collection('exams')
        .doc(examId.toLowerCase())
        .collection('years')
        .doc(yearId)
        .collection('materials');

    if (material.id.isEmpty) {
      final newDoc = await materialsRef.add(material.toFirestore());
      return newDoc.id;
    } else {
      await materialsRef.doc(material.id).set(
            material.toFirestore(),
            SetOptions(merge: true),
          );
      return material.id;
    }
  }

  Future<void> deleteMaterial({
    required String examId,
    required String yearId,
    required String materialId,
    String? fileUrl,
  }) async {
    if (fileUrl != null && fileUrl.isNotEmpty) {
      await _storageService.deleteFileByUrl(fileUrl);
    }
    await _db
        .collection('exams')
        .doc(examId.toLowerCase())
        .collection('years')
        .doc(yearId)
        .collection('materials')
        .doc(materialId)
        .delete();
  }

  Future<void> toggleMaterialVisibility({
    required String examId,
    required String yearId,
    required String materialId,
    required bool isHidden,
  }) async {
    await _db
        .collection('exams')
        .doc(examId.toLowerCase())
        .collection('years')
        .doc(yearId)
        .collection('materials')
        .doc(materialId)
        .update({'isHidden': isHidden});
  }

  // ==========================================
  // DATABASE SEEDER (PROMPT SCHEMA & PRESETS)
  // ==========================================

  /// Seeds the exact schema requested in the user prompt:
  /// 1. categories/mba
  /// 2. exams/cat (linked to 'mba')
  /// 3. exams/cat/years/2025
  /// 4. exams/cat/years/2025/materials (CAT 2025 Quant Paper)
  Future<void> seedUserPromptSchema({bool uploadRealEmptyPdf = true}) async {
    // 1. Create a Category
    await _db.collection('categories').doc('mba').set({
      'name': 'MBA',
      'isHidden': false,
      'description': 'Management Aptitude & Business School Entrance Tests',
      'iconName': 'business_center',
      'order': 1,
    });

    // 2. Create a root Exam (linked to 'mba' category ID)
    await _db.collection('exams').doc('cat').set({
      'name': 'CAT',
      'categoryId': 'mba',
      'isHidden': false,
      'title': 'Common Admission Test (CAT)',
      'shortCode': 'CAT',
      'conductingBody': 'IIM Bangalore / CAT Committee',
      'description': 'National-level entrance exam for admission into premier IIMs and top B-schools in India.',
      'iconName': 'analytics',
      'badgeText': 'Top Tier',
      'totalPapersCount': 1,
      'availableYears': ['2025'],
    });

    // 3. Create a Year subcollection inside the CAT Exam
    final yearRef = _db.collection('exams').doc('cat').collection('years').doc('2025');
    await yearRef.set({
      'year': 2025,
      'isHidden': false,
      'papersCount': 1,
      'hasAnswerKey': true,
      'hasSolutions': true,
      'difficultyLevel': 'High',
      'notificationDate': 'Aug 2024',
    });

    // Generate or prepare file download URL
    String fileUrl = 'placeholder_for_storage_download_url';
    if (uploadRealEmptyPdf) {
      try {
        fileUrl = await _storageService.uploadEmptyPdfPlaceholder(
          examId: 'cat',
          year: '2025',
          title: 'CAT 2025 Quant Paper',
        );
      } catch (e) {
        // Fallback to placeholder if storage is not yet initialized or fails
        fileUrl = 'placeholder_for_storage_download_url';
      }
    }

    // 4. Create a Material subcollection inside the 2025 Year
    await yearRef.collection('materials').add({
      'title': 'CAT 2025 Quant Paper',
      'fileUrl': fileUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
      'isHidden': false,
      'fileName': 'CAT_2025_Quant_Paper.pdf',
      'stage': 'Quantitative Aptitude',
      'paperCode': 'CAT-2025-QA',
      'language': 'English',
      'totalMarks': 66,
      'durationMinutes': 40,
      'totalQuestions': 22,
      'fileSizeMb': 1.8,
      'isOfficial': true,
      'topicsCovered': ['Arithmetic', 'Algebra', 'Geometry', 'Number Systems'],
    });
  }

  /// Seeds mock categories, exams, years, and materials
  Future<void> seedFullCatalog() async {
    await seedUserPromptSchema(uploadRealEmptyPdf: false);

    // Seed other standard categories
    final categories = [
      CategoryModel(
        id: 'upsc',
        name: 'Civil Services (UPSC)',
        isHidden: false,
        description: 'Union Public Service Commission exams including IAS, IPS, and IFS.',
        iconName: 'account_balance',
        order: 2,
      ),
      CategoryModel(
        id: 'ssc',
        name: 'SSC & Staff Selection',
        isHidden: false,
        description: 'Staff Selection Commission CGL, CHSL, and MTS examinations.',
        iconName: 'work',
        order: 3,
      ),
      CategoryModel(
        id: 'banking',
        name: 'Banking & Insurance',
        isHidden: false,
        description: 'IBPS PO, SBI PO, RBI Grade B and Clerk examination papers.',
        iconName: 'savings',
        order: 4,
      ),
      CategoryModel(
        id: 'railways',
        name: 'Railways (RRB)',
        isHidden: false,
        description: 'Railway Recruitment Board NTPC, Group D, and ALP examinations.',
        iconName: 'train',
        order: 5,
      ),
      CategoryModel(
        id: 'defence',
        name: 'Defence Services',
        isHidden: false,
        description: 'NDA, CDS, AFCAT, and CAPF military recruitment exams.',
        iconName: 'military_tech',
        order: 6,
      ),
    ];

    for (final cat in categories) {
      await saveCategory(cat);
    }

    // Seed mock exams from MockExamRepository
    for (final exam in MockExamRepository.exams) {
      final categoryId = exam.category.toLowerCase().contains('upsc')
          ? 'upsc'
          : exam.category.toLowerCase().contains('ssc')
              ? 'ssc'
              : exam.category.toLowerCase().contains('banking')
                  ? 'banking'
                  : exam.category.toLowerCase().contains('railway')
                      ? 'railways'
                      : exam.category.toLowerCase().contains('defence')
                          ? 'defence'
                          : 'mba';

      final examModel = exam.copyWith(categoryId: categoryId);
      await saveExam(examModel);

      // Seed years
      for (final year in exam.availableYears) {
        final yearInfo = ExamYearInfo(
          id: year,
          year: int.tryParse(year) ?? year,
          isHidden: false,
          papersCount: 3,
          hasAnswerKey: true,
          hasSolutions: true,
          difficultyLevel: 'Moderate',
          notificationDate: 'Jan $year',
        );
        await saveYear(exam.id, yearInfo);

        // Seed materials
        final mockPapers = MockExamRepository.getPapersForYear(exam.id, year);
        for (final paper in mockPapers) {
          final examPaper = ExamPaper(
            id: '',
            examId: exam.id,
            year: year,
            title: paper.title,
            fileUrl: 'placeholder_for_storage_download_url',
            uploadedAt: FieldValue.serverTimestamp(),
            isHidden: false,
            fileName: '${paper.paperCode}.pdf',
            stage: paper.stage,
            paperCode: paper.paperCode,
            language: paper.language,
            totalMarks: paper.totalMarks,
            durationMinutes: paper.durationMinutes,
            totalQuestions: paper.totalQuestions,
            fileSizeMb: paper.fileSizeMb,
            isOfficial: paper.isOfficial,
            topicsCovered: paper.topicsCovered,
          );
          await saveMaterial(
            examId: exam.id,
            yearId: year,
            material: examPaper,
          );
        }
      }
    }
  }
}
