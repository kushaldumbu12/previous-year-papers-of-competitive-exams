import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/exam_model.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/firestore_service.dart';
import 'admin_dialogs.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _firestoreService = FirestoreService();
  final _storageService = FirebaseStorageService();
  final _authService = AuthService();

  static const _allCategory = CategoryModel(
    id: 'all',
    name: 'All',
    description: 'All Categories',
    iconName: 'apps',
    order: -999,
  );

  // Navigation Drilldown State
  CategoryModel? _selectedCategory = _allCategory;
  Exam? _selectedExam;
  ExamYearInfo? _selectedYear;

  // Modify mode toggles
  bool _isModifyingCategories = false;
  bool _isModifyingExams = false;
  bool _isModifyingYears = false;
  bool _isModifyingMaterials = false;

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/admin/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isInExamDetailView = _selectedExam != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildTopAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Clickable Breadcrumb Path: 🏠 Home > Category > Exam > Year
            _buildClickableBreadcrumbPath(),
            const SizedBox(height: 24),

            // If an Exam is selected, show the Full Screen Exam Drilldown (Years & Materials)
            if (isInExamDetailView)
              _buildExamDetailFullView()
            else ...[
              // Main Categories & Exams Catalog Overview
              _buildCategoriesSection(),
              const SizedBox(height: 28),

              if (_selectedCategory != null)
                _buildExamsSection(),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP APP BAR
  // ==========================================
  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      toolbarHeight: 72,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Administration Console',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Signed in: ${_authService.currentAdminEmail}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Sign Out',
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
          onPressed: _handleLogout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ==========================================
  // CLICKABLE BREADCRUMB PATH (🏠 Home > Category > Exam > Year)
  // ==========================================
  Widget _buildClickableBreadcrumbPath() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 🏠 Home Icon Button
            _BreadcrumbItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: (_selectedCategory == null || _selectedCategory!.id == 'all') &&
                  _selectedExam == null &&
                  _selectedYear == null,
              onTap: () {
                setState(() {
                  _selectedCategory = _allCategory;
                  _selectedExam = null;
                  _selectedYear = null;
                });
              },
            ),

            // Category segment
            if (_selectedCategory != null && _selectedCategory!.id != 'all') ...[
              _buildBreadcrumbChevron(),
              _BreadcrumbItem(
                label: _selectedCategory!.name,
                isActive: _selectedExam == null,
                onTap: () {
                  setState(() {
                    _selectedExam = null;
                    _selectedYear = null;
                  });
                },
              ),
            ],

            // Exam segment (only exam_name, NOT <year> at once!)
            if (_selectedExam != null) ...[
              _buildBreadcrumbChevron(),
              _BreadcrumbItem(
                label: _selectedExam!.name,
                isActive: _selectedYear == null,
                onTap: () {
                  setState(() {
                    _selectedYear = null;
                  });
                },
              ),
            ],

            // Year segment (Only displayed AFTER selecting a specific year!)
            if (_selectedYear != null) ...[
              _buildBreadcrumbChevron(),
              _BreadcrumbItem(
                label: _selectedYear!.yearString,
                isActive: true,
                onTap: () {},
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbChevron() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF94A3B8),
        size: 20,
      ),
    );
  }

  // ==========================================
  // LEVEL 1: CATEGORIES OVERVIEW
  // ==========================================
  Widget _buildCategoriesSection() {
    return StreamBuilder<List<CategoryModel>>(
      stream: _firestoreService.streamCategories(includeHidden: true),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.category_rounded, color: Color(0xFF4F46E5), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${categories.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isModifyingCategories ? const Color(0xFFEEF2FF) : Colors.white,
                    side: BorderSide(
                      color: _isModifyingCategories ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() => _isModifyingCategories = !_isModifyingCategories);
                  },
                  icon: Icon(
                    _isModifyingCategories ? Icons.done_all_rounded : Icons.edit_note_rounded,
                    size: 16,
                    color: _isModifyingCategories ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                  ),
                  label: Text(
                    _isModifyingCategories ? 'Done Modifying' : 'Modify Categories',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _isModifyingCategories ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a category to filter exams, or manage category visibility and ordering',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            if (_isModifyingCategories)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drag_indicator_rounded, size: 16, color: Color(0xFF4F46E5)),
                    SizedBox(width: 6),
                    Text(
                      'Drag and drop categories to re-arrange their order',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ],
                ),
              ),

            // Categories horizontal wrap (Add Category is at the LAST position)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // "All" Master Category Pill (Always present first)
                _CategoryPillCard(
                  category: _allCategory,
                  isSelected: _isModifyingCategories ? false : (_selectedCategory?.id == 'all'),
                  isModifying: false,
                  onSelect: () {
                    setState(() {
                      _selectedCategory = _allCategory;
                      _selectedExam = null;
                      _selectedYear = null;
                    });
                  },
                  onEdit: () {},
                  onToggleHidden: () {},
                  onDelete: () {},
                ),
                ...categories.map((cat) {
                  final isSelected = _isModifyingCategories ? false : (_selectedCategory?.id == cat.id);
                  final card = _CategoryPillCard(
                    category: cat,
                    isSelected: isSelected,
                    isModifying: _isModifyingCategories,
                    onSelect: _isModifyingCategories
                        ? null
                        : () {
                            setState(() {
                              _selectedCategory = cat;
                              _selectedExam = null;
                              _selectedYear = null;
                            });
                          },
                    onEdit: () {
                      AdminDialogs.showCategoryDialog(
                        context: context,
                        firestoreService: _firestoreService,
                        existingCategory: cat,
                      );
                    },
                    onToggleHidden: () {
                      _firestoreService.toggleCategoryVisibility(cat.id, !cat.isHidden);
                    },
                    onDelete: () async {
                      final confirm = await AdminDialogs.confirmDelete(
                        context: context,
                        title: 'Delete Category',
                        message: 'Are you sure you want to delete "${cat.name}"?',
                      );
                      if (confirm) {
                        await _firestoreService.deleteCategory(cat.id);
                        if (_selectedCategory?.id == cat.id) {
                          setState(() {
                            _selectedCategory = _allCategory;
                            _selectedExam = null;
                            _selectedYear = null;
                          });
                        }
                      }
                    },
                  );

                  if (!_isModifyingCategories) {
                    return card;
                  }

                  return DragTarget<CategoryModel>(
                    onWillAcceptWithDetails: (details) => details.data.id != cat.id,
                    onAcceptWithDetails: (details) async {
                      final dragged = details.data;
                      final list = List<CategoryModel>.from(categories);
                      final oldIndex = list.indexWhere((c) => c.id == dragged.id);
                      final newIndex = list.indexWhere((c) => c.id == cat.id);
                      if (oldIndex != -1 && newIndex != -1) {
                        final item = list.removeAt(oldIndex);
                        list.insert(newIndex, item);
                        await _firestoreService.reorderCategories(list);
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isTargeted = candidateData.isNotEmpty;
                      return Draggable<CategoryModel>(
                        data: cat,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: 0.9,
                            child: _CategoryPillCard(
                              category: cat,
                              isSelected: false,
                              isModifying: true,
                              onSelect: null,
                              onEdit: () {},
                              onToggleHidden: () {},
                              onDelete: () {},
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.25,
                          child: card,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: isTargeted
                                ? Border.all(color: const Color(0xFF4F46E5), width: 2)
                                : null,
                          ),
                          child: card,
                        ),
                      );
                    },
                  );
                }),
                if (_isModifyingCategories)
                  _AddCategoryPill(
                    onTap: () {
                      AdminDialogs.showCategoryDialog(
                        context: context,
                        firestoreService: _firestoreService,
                      );
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // LEVEL 2: EXAMS OVERVIEW (Under Selected Category or All)
  // ==========================================
  Widget _buildExamsSection() {
    final cat = _selectedCategory ?? _allCategory;
    final isAll = cat.id == 'all';

    return StreamBuilder<List<Exam>>(
      stream: _firestoreService.streamExams(
        categoryId: isAll ? null : cat.id,
        includeHidden: true,
      ),
      builder: (context, snapshot) {
        final exams = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          isAll ? 'All Exams' : 'Exams in ${cat.name}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${exams.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _isModifyingExams ? const Color(0xFFEEF2FF) : Colors.white,
                      side: BorderSide(
                        color: _isModifyingExams ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() => _isModifyingExams = !_isModifyingExams);
                    },
                    icon: Icon(
                      _isModifyingExams ? Icons.done_all_rounded : Icons.edit_note_rounded,
                      size: 16,
                      color: _isModifyingExams ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                    ),
                    label: Text(
                      _isModifyingExams ? 'Done Modifying' : 'Modify Exams',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isModifyingExams ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Click any exam to open its examination years and materials',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              if (_isModifyingExams)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drag_indicator_rounded, size: 16, color: Color(0xFF4F46E5)),
                      SizedBox(width: 6),
                      Text(
                        'Drag and drop exam cards to re-arrange their order',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                    ],
                  ),
                ),

              // Exams Grid (Add Exam is at the LAST position)
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  if (exams.isEmpty && !_isModifyingExams)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.school_outlined, size: 36, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 8),
                            Text(
                              isAll
                                  ? 'No exams added yet.'
                                  : 'No exams added under ${cat.name} yet.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                final allCats = await _firestoreService.getCategories(includeHidden: true);
                                if (context.mounted) {
                                  AdminDialogs.showExamDialog(
                                    context: context,
                                    firestoreService: _firestoreService,
                                    categories: allCats,
                                    defaultCategoryId: isAll
                                        ? (allCats.isNotEmpty ? allCats.first.id : null)
                                        : cat.id,
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add First Exam'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    ...exams.map((exam) {
                      final card = _ExamCard(
                        exam: exam,
                        isSelected: false,
                        isModifying: _isModifyingExams,
                        onSelect: _isModifyingExams
                            ? null
                            : () {
                                // Drilldown into Full Screen Exam View
                                setState(() {
                                  _selectedExam = exam;
                                  _selectedYear = null;
                                });
                              },
                        onEdit: () async {
                          final allCats = await _firestoreService.getCategories(includeHidden: true);
                          if (context.mounted) {
                            AdminDialogs.showExamDialog(
                              context: context,
                              firestoreService: _firestoreService,
                              categories: allCats,
                              existingExam: exam,
                            );
                          }
                        },
                        onToggleHidden: () {
                          _firestoreService.toggleExamVisibility(exam.id, !exam.isHidden);
                        },
                        onDelete: () async {
                          final confirm = await AdminDialogs.confirmDelete(
                            context: context,
                            title: 'Delete Exam',
                            message: 'Are you sure you want to delete exam "${exam.name}"?',
                          );
                          if (confirm) {
                            await _firestoreService.deleteExam(exam.id);
                          }
                        },
                      );

                      if (!_isModifyingExams) {
                        return card;
                      }

                      return DragTarget<Exam>(
                        onWillAcceptWithDetails: (details) => details.data.id != exam.id,
                        onAcceptWithDetails: (details) async {
                          final dragged = details.data;
                          final list = List<Exam>.from(exams);
                          final oldIndex = list.indexWhere((e) => e.id == dragged.id);
                          final newIndex = list.indexWhere((e) => e.id == exam.id);
                          if (oldIndex != -1 && newIndex != -1) {
                            final item = list.removeAt(oldIndex);
                            list.insert(newIndex, item);
                            await _firestoreService.reorderExams(list);
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isTargeted = candidateData.isNotEmpty;
                          return Draggable<Exam>(
                            data: exam,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: 260,
                                child: Opacity(
                                  opacity: 0.9,
                                  child: _ExamCard(
                                    exam: exam,
                                    isSelected: false,
                                    isModifying: true,
                                    onSelect: null,
                                    onEdit: () {},
                                    onToggleHidden: () {},
                                    onDelete: () {},
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.25,
                              child: card,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: isTargeted
                                    ? Border.all(color: const Color(0xFF4F46E5), width: 2.5)
                                    : null,
                              ),
                              child: card,
                            ),
                          );
                        },
                      );
                    }),
                    if (_isModifyingExams)
                      _AddPlaceholderCard(
                        title: 'Add New Exam',
                        subtitle: isAll ? 'Add new exam' : 'Add exam under ${cat.name}',
                        icon: Icons.add_rounded,
                        onTap: () async {
                          final allCats = await _firestoreService.getCategories(includeHidden: true);
                          if (context.mounted) {
                            AdminDialogs.showExamDialog(
                              context: context,
                              firestoreService: _firestoreService,
                              categories: allCats,
                              defaultCategoryId: isAll
                                  ? (allCats.isNotEmpty ? allCats.first.id : null)
                                  : cat.id,
                            );
                          }
                        },
                      ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // FULL SCREEN EXAM DRILLDOWN VIEW (YEARS & MATERIALS)
  // ==========================================
  Widget _buildExamDetailFullView() {
    final exam = _selectedExam!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exam Banner Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E1B4B).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 14,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            exam.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exam.description.isNotEmpty
                                ? exam.description
                                : 'Manage question paper years and study materials for ${exam.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFC7D2FE),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF818CF8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() {
                    _selectedExam = null;
                    _selectedYear = null;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Catalog'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Years Section
        _buildYearsSection(),
        const SizedBox(height: 28),

        // Materials Section (If Year selected)
        if (_selectedYear != null)
          _buildMaterialsSection(),
      ],
    );
  }

  // ==========================================
  // LEVEL 3: YEARS SECTION
  // ==========================================
  Widget _buildYearsSection() {
    final exam = _selectedExam!;

    return StreamBuilder<List<ExamYearInfo>>(
      stream: _firestoreService.streamYears(exam.id, includeHidden: true),
      builder: (context, snapshot) {
        final years = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF4F46E5), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Examination Years (${exam.name})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${years.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _isModifyingYears ? const Color(0xFFEEF2FF) : Colors.white,
                      side: BorderSide(
                        color: _isModifyingYears ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() => _isModifyingYears = !_isModifyingYears);
                    },
                    icon: Icon(
                      _isModifyingYears ? Icons.done_all_rounded : Icons.edit_note_rounded,
                      size: 16,
                      color: _isModifyingYears ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                    ),
                    label: Text(
                      _isModifyingYears ? 'Done Modifying' : 'Modify Years',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isModifyingYears ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a year below to view and upload its question papers and answer keys',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // Years Grid (Add Year is at the LAST position)
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  if (years.isEmpty && !_isModifyingYears)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 36, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 8),
                            Text(
                              'No examination years created for ${exam.name} yet.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                AdminDialogs.showYearDialog(
                                  context: context,
                                  firestoreService: _firestoreService,
                                  examId: exam.id,
                                );
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add First Year'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    ...years.map((y) {
                      final isSelected = _isModifyingYears ? false : (_selectedYear?.id == y.id);
                      return _YearCard(
                        yearInfo: y,
                        isSelected: isSelected,
                        isModifying: _isModifyingYears,
                        onSelect: _isModifyingYears
                            ? null
                            : () {
                                setState(() => _selectedYear = y);
                              },
                        onEdit: () {
                          AdminDialogs.showYearDialog(
                            context: context,
                            firestoreService: _firestoreService,
                            examId: exam.id,
                            existingYear: y,
                          );
                        },
                        onToggleHidden: () {
                          _firestoreService.toggleYearVisibility(exam.id, y.id, !y.isHidden);
                        },
                        onDelete: () async {
                          final confirm = await AdminDialogs.confirmDelete(
                            context: context,
                            title: 'Delete Year',
                            message: 'Are you sure you want to delete year ${y.yearString}?',
                          );
                          if (confirm) {
                            await _firestoreService.deleteYear(exam.id, y.id);
                            if (_selectedYear?.id == y.id) {
                              setState(() => _selectedYear = null);
                            }
                          }
                        },
                      );
                    }),
                    if (_isModifyingYears)
                      _AddPlaceholderCard(
                        title: 'Add Year',
                        subtitle: 'Add year under ${exam.name}',
                        icon: Icons.add_rounded,
                        onTap: () {
                          AdminDialogs.showYearDialog(
                            context: context,
                            firestoreService: _firestoreService,
                            examId: exam.id,
                          );
                        },
                      ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // LEVEL 4: MATERIALS SECTION
  // ==========================================
  Widget _buildMaterialsSection() {
    final exam = _selectedExam!;
    final year = _selectedYear!;

    return StreamBuilder<List<ExamPaper>>(
      stream: _firestoreService.streamMaterials(exam.id, year.id, includeHidden: true),
      builder: (context, snapshot) {
        final materials = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF4F46E5), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Materials & Papers (${exam.name} • ${year.yearString})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${materials.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _isModifyingMaterials ? const Color(0xFFEEF2FF) : Colors.white,
                      side: BorderSide(
                        color: _isModifyingMaterials ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() => _isModifyingMaterials = !_isModifyingMaterials);
                    },
                    icon: Icon(
                      _isModifyingMaterials ? Icons.done_all_rounded : Icons.edit_note_rounded,
                      size: 16,
                      color: _isModifyingMaterials ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                    ),
                    label: Text(
                      _isModifyingMaterials ? 'Done Modifying' : 'Modify Materials',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isModifyingMaterials ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Materials Grid (Upload Material is at the LAST position)
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  if (materials.isEmpty && !_isModifyingMaterials)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined, size: 36, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 8),
                            Text(
                              'No documents uploaded for ${exam.name} (${year.yearString}) yet.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                AdminDialogs.showMaterialDialog(
                                  context: context,
                                  firestoreService: _firestoreService,
                                  storageService: _storageService,
                                  examId: exam.id,
                                  yearId: year.id,
                                );
                              },
                              icon: const Icon(Icons.upload_file_rounded, size: 16),
                              label: const Text('Upload Document (PDF)'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    ...materials.map((mat) {
                      return _MaterialCard(
                        material: mat,
                        isModifying: _isModifyingMaterials,
                        onEdit: () {
                          AdminDialogs.showMaterialDialog(
                            context: context,
                            firestoreService: _firestoreService,
                            storageService: _storageService,
                            examId: exam.id,
                            yearId: year.id,
                            existingMaterial: mat,
                          );
                        },
                        onToggleHidden: () {
                          _firestoreService.toggleMaterialVisibility(
                            examId: exam.id,
                            yearId: year.id,
                            materialId: mat.id,
                            isHidden: !mat.isHidden,
                          );
                        },
                        onDelete: () async {
                          final confirm = await AdminDialogs.confirmDelete(
                            context: context,
                            title: 'Delete Document',
                            message: 'Are you sure you want to delete "${mat.title}"?',
                          );
                          if (confirm) {
                            await _firestoreService.deleteMaterial(
                              examId: exam.id,
                              yearId: year.id,
                              materialId: mat.id,
                              fileUrl: mat.fileUrl,
                            );
                          }
                        },
                      );
                    }),
                    if (_isModifyingMaterials)
                      _AddPlaceholderCard(
                        title: 'Upload Material',
                        subtitle: 'Attach PDF document or empty file',
                        icon: Icons.upload_file_rounded,
                        onTap: () {
                          AdminDialogs.showMaterialDialog(
                            context: context,
                            firestoreService: _firestoreService,
                            storageService: _storageService,
                            examId: exam.id,
                            yearId: year.id,
                          );
                        },
                      ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// BREADCRUMB ITEM
// ==========================================
class _BreadcrumbItem extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _BreadcrumbItem({
    required this.label,
    this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_BreadcrumbItem> createState() => _BreadcrumbItemState();
}

class _BreadcrumbItemState extends State<_BreadcrumbItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isActive ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered && !widget.isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isActive ? const Color(0xFF0F172A) : const Color(0xFF4F46E5),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: widget.isActive ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 14,
                  color: widget.isActive
                      ? const Color(0xFF0F172A)
                      : _isHovered
                          ? const Color(0xFF4338CA)
                          : const Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// INTERACTIVE ADD CATEGORY PILL (Matches Category Pill Height)
// ==========================================
class _AddCategoryPill extends StatefulWidget {
  final VoidCallback onTap;

  const _AddCategoryPill({required this.onTap});

  @override
  State<_AddCategoryPill> createState() => _AddCategoryPillState();
}

class _AddCategoryPillState extends State<_AddCategoryPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: _isHovered ? Matrix4.translationValues(0.0, -2.0, 0.0) : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
              width: 1.4,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 16,
                color: _isHovered ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                'Add Category',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: _isHovered ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// INTERACTIVE ADD PLACEHOLDER CARD
// ==========================================
class _AddPlaceholderCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AddPlaceholderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_AddPlaceholderCard> createState() => _AddPlaceholderCardState();
}

class _AddPlaceholderCardState extends State<_AddPlaceholderCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 220,
          height: 120,
          transform: _isHovered ? Matrix4.translationValues(0.0, -3.0, 0.0) : Matrix4.identity(),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
              width: 1.8,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isHovered ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: _isHovered ? Colors.white : const Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: _isHovered ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                ),
              ),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CATEGORY PILL CARD
// ==========================================
class _CategoryPillCard extends StatefulWidget {
  final CategoryModel category;
  final bool isSelected;
  final bool isModifying;
  final VoidCallback? onSelect;
  final VoidCallback onEdit;
  final VoidCallback onToggleHidden;
  final VoidCallback onDelete;

  const _CategoryPillCard({
    required this.category,
    required this.isSelected,
    required this.isModifying,
    required this.onSelect,
    required this.onEdit,
    required this.onToggleHidden,
    required this.onDelete,
  });

  @override
  State<_CategoryPillCard> createState() => _CategoryPillCardState();
}

class _CategoryPillCardState extends State<_CategoryPillCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool effectiveSelected = widget.isSelected && !widget.isModifying;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isModifying ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isModifying ? null : widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: (_isHovered && !effectiveSelected && !widget.isModifying)
              ? Matrix4.translationValues(0.0, -2.0, 0.0)
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: effectiveSelected
                ? const Color(0xFF4F46E5)
                : widget.category.isHidden
                    ? const Color(0xFFF1F5F9)
                    : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: effectiveSelected
                  ? const Color(0xFF4F46E5)
                  : (_isHovered && !widget.isModifying)
                      ? const Color(0xFF818CF8)
                      : const Color(0xFFE2E8F0),
              width: effectiveSelected ? 2 : 1.2,
            ),
            boxShadow: effectiveSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isModifying) ...[
                const MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                widget.category.id == 'all'
                    ? Icons.apps_rounded
                    : Icons.folder_rounded,
                size: 16,
                color: effectiveSelected ? Colors.white : const Color(0xFF4F46E5),
              ),
              const SizedBox(width: 8),
              Text(
                widget.category.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: effectiveSelected
                      ? Colors.white
                      : widget.category.isHidden
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                ),
              ),
              if (widget.category.isHidden) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: effectiveSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hidden',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: effectiveSelected ? Colors.white : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
              if (widget.isModifying) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: widget.onToggleHidden,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Tooltip(
                      message: widget.category.isHidden ? 'Make Visible to Students' : 'Hide from Students',
                      child: Icon(
                        widget.category.isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 17,
                        color: widget.category.isHidden ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: widget.onEdit,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Tooltip(
                      message: 'Edit Category',
                      child: Icon(
                        Icons.edit_rounded,
                        size: 17,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: widget.onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Tooltip(
                      message: 'Delete Category',
                      child: Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// EXAM CARD
// ==========================================
class _ExamCard extends StatefulWidget {
  final Exam exam;
  final bool isSelected;
  final bool isModifying;
  final VoidCallback? onSelect;
  final VoidCallback onEdit;
  final VoidCallback onToggleHidden;
  final VoidCallback onDelete;

  const _ExamCard({
    required this.exam,
    required this.isSelected,
    required this.isModifying,
    required this.onSelect,
    required this.onEdit,
    required this.onToggleHidden,
    required this.onDelete,
  });

  @override
  State<_ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<_ExamCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool effectiveSelected = widget.isSelected && !widget.isModifying;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isModifying ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isModifying ? null : widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: (_isHovered && !effectiveSelected && !widget.isModifying)
              ? Matrix4.translationValues(0.0, -3.0, 0.0)
              : Matrix4.identity(),
          width: 260,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: effectiveSelected
                ? const Color(0xFFEEF2FF)
                : widget.exam.isHidden
                    ? const Color(0xFFF8FAFC)
                    : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: effectiveSelected
                  ? const Color(0xFF4F46E5)
                  : (_isHovered && !widget.isModifying)
                      ? const Color(0xFF818CF8)
                      : const Color(0xFFE2E8F0),
              width: effectiveSelected ? 2 : 1.2,
            ),
            boxShadow: effectiveSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : (_isHovered && !widget.isModifying)
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.isModifying) ...[
                        const MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 20,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  if (widget.isModifying)
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            widget.exam.isHidden ? Icons.visibility_off : Icons.visibility,
                            size: 16,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: widget.onToggleHidden,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF4F46E5)),
                          onPressed: widget.onEdit,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                          onPressed: widget.onDelete,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        if (widget.exam.isHidden)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Hidden',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.exam.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.exam.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.exam.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// YEAR CARD
// ==========================================
class _YearCard extends StatefulWidget {
  final ExamYearInfo yearInfo;
  final bool isSelected;
  final bool isModifying;
  final VoidCallback? onSelect;
  final VoidCallback onEdit;
  final VoidCallback onToggleHidden;
  final VoidCallback onDelete;

  const _YearCard({
    required this.yearInfo,
    required this.isSelected,
    required this.isModifying,
    required this.onSelect,
    required this.onEdit,
    required this.onToggleHidden,
    required this.onDelete,
  });

  @override
  State<_YearCard> createState() => _YearCardState();
}

class _YearCardState extends State<_YearCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool effectiveSelected = widget.isSelected && !widget.isModifying;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isModifying ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isModifying ? null : widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: (_isHovered && !effectiveSelected && !widget.isModifying)
              ? Matrix4.translationValues(0.0, -3.0, 0.0)
              : Matrix4.identity(),
          width: 170,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: effectiveSelected
                ? const Color(0xFF4F46E5)
                : widget.yearInfo.isHidden
                    ? const Color(0xFFF8FAFC)
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: effectiveSelected
                  ? const Color(0xFF4F46E5)
                  : (_isHovered && !widget.isModifying)
                      ? const Color(0xFF818CF8)
                      : const Color(0xFFE2E8F0),
              width: effectiveSelected ? 2 : 1.2,
            ),
            boxShadow: effectiveSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.yearInfo.yearString,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5,
                      color: effectiveSelected ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (widget.isModifying)
                    Row(
                      children: [
                        InkWell(
                          onTap: widget.onToggleHidden,
                          child: Icon(
                            widget.yearInfo.isHidden ? Icons.visibility_off : Icons.visibility,
                            size: 15,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: widget.onEdit,
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 15,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: widget.onDelete,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (widget.yearInfo.isHidden) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: effectiveSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Hidden',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: effectiveSelected ? Colors.white : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MATERIAL CARD
// ==========================================
class _MaterialCard extends StatefulWidget {
  final ExamPaper material;
  final bool isModifying;
  final VoidCallback onEdit;
  final VoidCallback onToggleHidden;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.material,
    required this.isModifying,
    required this.onEdit,
    required this.onToggleHidden,
    required this.onDelete,
  });

  @override
  State<_MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<_MaterialCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: _isHovered ? Matrix4.translationValues(0.0, -3.0, 0.0) : Matrix4.identity(),
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.material.isHidden ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 20),
                ),
                Row(
                  children: [
                    if (widget.material.isHidden)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Hidden',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    if (widget.isModifying) ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          widget.material.isHidden ? Icons.visibility_off : Icons.visibility,
                          size: 16,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: widget.onToggleHidden,
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF4F46E5)),
                        onPressed: widget.onEdit,
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.material.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.material.stage,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Marks: ${widget.material.totalMarks}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
