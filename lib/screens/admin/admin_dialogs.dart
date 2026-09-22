import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/exam_model.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/firestore_service.dart';

class AdminDialogs {
  // Helper to generate a clean system ID from a string name
  static String generateSlug(String text) {
    final clean = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return clean.isNotEmpty ? clean : 'item_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ==========================================
  // CATEGORY DIALOG (CREATE / EDIT)
  // ==========================================
  static Future<void> showCategoryDialog({
    required BuildContext context,
    required FirestoreService firestoreService,
    CategoryModel? existingCategory,
  }) async {
    final isEdit = existingCategory != null;
    final nameController = TextEditingController(text: existingCategory?.name ?? '');
    if (isEdit && nameController.text.isNotEmpty) {
      nameController.selection =
          TextSelection(baseOffset: 0, extentOffset: nameController.text.length);
    }
    bool isHidden = existingCategory?.isHidden ?? false;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setState(() => isSaving = true);
              try {
                final catName = nameController.text.trim();
                final catId = isEdit
                    ? existingCategory.id
                    : generateSlug(catName);

                final cat = CategoryModel(
                  id: catId,
                  name: catName,
                  description: '',
                  isHidden: isHidden,
                  iconName: existingCategory?.iconName ?? 'category',
                  order: existingCategory?.order ?? 0,
                );
                await firestoreService.saveCategory(cat);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                setState(() => isSaving = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving category: $e')),
                  );
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_rounded : Icons.category_rounded,
                      color: const Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Category' : 'Create Category',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category Name',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameController,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!isSaving) submit();
                          },
                          decoration: InputDecoration(
                            hintText: 'e.g. MBA, Civil Services (UPSC), Banking',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Category name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Hide Category from Students',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Hidden categories are excluded from the public student view',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          value: isHidden,
                          activeThumbColor: const Color(0xFFEF4444),
                          onChanged: (val) => setState(() => isHidden = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving ? null : submit,
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Create Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // EXAM DIALOG (CREATE / EDIT)
  // ==========================================
  static Future<void> showExamDialog({
    required BuildContext context,
    required FirestoreService firestoreService,
    required List<CategoryModel> categories,
    Exam? existingExam,
    String? defaultCategoryId,
  }) async {
    final isEdit = existingExam != null;
    final nameController =
        TextEditingController(text: existingExam?.name ?? existingExam?.title ?? '');
    if (isEdit && nameController.text.isNotEmpty) {
      nameController.selection =
          TextSelection(baseOffset: 0, extentOffset: nameController.text.length);
    }
    final descController = TextEditingController(text: existingExam?.description ?? '');
    String selectedCategory = existingExam?.categoryId ??
        (defaultCategoryId != null && defaultCategoryId.isNotEmpty
            ? defaultCategoryId
            : (categories.isNotEmpty ? categories.first.id : 'mba'));
    bool isHidden = existingExam?.isHidden ?? false;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setState(() => isSaving = true);
              try {
                final examName = nameController.text.trim();
                final examId = isEdit
                    ? existingExam.id
                    : generateSlug(examName);

                final exam = Exam(
                  id: examId,
                  name: examName,
                  categoryId: selectedCategory,
                  isHidden: isHidden,
                  title: examName,
                  shortCode: examName.toUpperCase(),
                  conductingBody: existingExam?.conductingBody ?? '',
                  badgeText: existingExam?.badgeText ?? '',
                  description: descController.text.trim(),
                  iconName: existingExam?.iconName ?? 'school',
                  totalPapersCount: existingExam?.totalPapersCount ?? 0,
                  availableYears: existingExam?.availableYears ?? [],
                );
                await firestoreService.saveExam(exam);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                setState(() => isSaving = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving exam: $e')),
                  );
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_note_rounded : Icons.school_rounded,
                      color: const Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Exam' : 'Create Exam',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: categories.any((c) => c.id == selectedCategory)
                              ? selectedCategory
                              : (categories.isNotEmpty ? categories.first.id : null),
                          items: categories.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedCategory = val);
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Exam Name',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameController,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!isSaving) submit();
                          },
                          decoration: InputDecoration(
                            hintText: 'e.g. CAT, UPSC Civil Services, SSC CGL',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Exam name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Key overview of eligibility, format, or dates...',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Hide Exam from Students',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Hidden exams will not appear in student view',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          value: isHidden,
                          activeThumbColor: const Color(0xFFEF4444),
                          onChanged: (val) => setState(() => isHidden = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving ? null : submit,
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Create Exam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // YEAR SUBCOLLECTION DIALOG (CREATE / EDIT)
  // ==========================================
  static Future<void> showYearDialog({
    required BuildContext context,
    required FirestoreService firestoreService,
    required String examId,
    ExamYearInfo? existingYear,
  }) async {
    final isEdit = existingYear != null;
    final yearController = TextEditingController(
      text: existingYear != null ? existingYear.yearString : DateTime.now().year.toString(),
    );
    if (yearController.text.isNotEmpty) {
      yearController.selection =
          TextSelection(baseOffset: 0, extentOffset: yearController.text.length);
    }
    bool isHidden = existingYear?.isHidden ?? false;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setState(() => isSaving = true);
              try {
                final rawYearStr = yearController.text.trim();
                final parsedYear = int.tryParse(rawYearStr) ?? rawYearStr;
                final yearInfo = ExamYearInfo(
                  id: rawYearStr,
                  year: parsedYear,
                  isHidden: isHidden,
                  difficultyLevel: 'Moderate',
                  notificationDate: '',
                  papersCount: existingYear?.papersCount ?? 0,
                );
                await firestoreService.saveYear(examId, yearInfo);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                setState(() => isSaving = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving year: $e')),
                  );
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_calendar_rounded : Icons.calendar_month_rounded,
                      color: const Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Examination Year' : 'Add Examination Year',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Year Number',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: yearController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!isSaving) submit();
                          },
                          decoration: InputDecoration(
                            hintText: 'e.g. 2025, 2024, 2023',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Year is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Hide Year from Students',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Excludes this year and its materials from student app',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          value: isHidden,
                          activeThumbColor: const Color(0xFFEF4444),
                          onChanged: (val) => setState(() => isHidden = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving ? null : submit,
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Add Year'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // MATERIAL / DOCUMENT DIALOG (CREATE / EDIT / STORAGE UPLOAD)
  // ==========================================
  static Future<void> showMaterialDialog({
    required BuildContext context,
    required FirestoreService firestoreService,
    required FirebaseStorageService storageService,
    required String examId,
    required String yearId,
    ExamPaper? existingMaterial,
  }) async {
    final isEdit = existingMaterial != null;
    final titleController = TextEditingController(
      text: existingMaterial?.title ?? 'Question Paper $yearId',
    );
    final stageController =
        TextEditingController(text: existingMaterial?.stage ?? 'Quantitative Aptitude');
    final codeController = TextEditingController(text: existingMaterial?.paperCode ?? 'SET-A');
    final marksController = TextEditingController(
      text: existingMaterial != null ? existingMaterial.totalMarks.toString() : '100',
    );
    final durationController = TextEditingController(
      text: existingMaterial != null ? existingMaterial.durationMinutes.toString() : '120',
    );
    bool isHidden = existingMaterial?.isHidden ?? false;

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String statusMessage = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_document : Icons.picture_as_pdf_rounded,
                      color: const Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Material / Paper' : 'Upload Material / Paper',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Material Title',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: titleController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'e.g. CAT 2025 Quant Paper, Prelims General Studies',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Material title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Stage / Section',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: stageController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Quant, Prelims, Tier 1',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Paper Code',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: codeController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. SET-A, CAT-QA',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Marks',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: marksController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Duration (Minutes)',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: durationController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Hide Material from Students',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Hidden materials are excluded from public student views',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          value: isHidden,
                          activeThumbColor: const Color(0xFFEF4444),
                          onChanged: (val) => setState(() => isHidden = val),
                        ),
                        if (statusMessage.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            statusMessage,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() {
                            isSaving = true;
                            statusMessage = 'Saving Material...';
                          });

                          try {
                            final paper = ExamPaper(
                              id: existingMaterial?.id ?? '',
                              examId: examId,
                              year: yearId,
                              title: titleController.text.trim(),
                              fileUrl: '',
                              fileName: 'Material_$yearId',
                              stage: stageController.text.trim(),
                              paperCode: codeController.text.trim(),
                              totalMarks: int.tryParse(marksController.text.trim()) ?? 100,
                              durationMinutes:
                                  int.tryParse(durationController.text.trim()) ?? 120,
                              isHidden: isHidden,
                              isOfficial: true,
                            );

                            await firestoreService.saveMaterial(
                              examId: examId,
                              yearId: yearId,
                              material: paper,
                            );

                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setState(() {
                              isSaving = false;
                              statusMessage = 'Error: $e';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Create Material'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // CONFIRM DELETE DIALOG
  // ==========================================
  static Future<bool> confirmDelete({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
