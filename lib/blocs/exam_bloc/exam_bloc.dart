import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/mock_data.dart';
import '../../models/exam_model.dart';
import '../../services/firestore_service.dart';
import 'exam_event.dart';
import 'exam_state.dart';

class ExamBloc extends Bloc<ExamEvent, ExamState> {
  final FirestoreService _firestoreService;

  ExamBloc({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService(),
        super(const ExamInitial()) {
    on<LoadExamsEvent>(_onLoadExams);
    on<SelectCategoryEvent>(_onSelectCategory);
    on<SearchExamsEvent>(_onSearchExams);
    on<SelectExamEvent>(_onSelectExam);
  }

  void _onLoadExams(LoadExamsEvent event, Emitter<ExamState> emit) async {
    emit(const ExamLoading());
    try {
      // 1. Try loading live categories and exams from Firestore
      List<String> categories = [];
      List<Exam> exams = [];

      try {
        final firestoreCategories =
            await _firestoreService.getCategories(includeHidden: false);
        final firestoreExams =
            await _firestoreService.getExams(includeHidden: false);

        if (firestoreCategories.isNotEmpty) {
          categories = ['All', ...firestoreCategories.map((c) => c.name)];
        }
        if (firestoreExams.isNotEmpty) {
          exams = firestoreExams;
        }
      } catch (e) {
        // Firestore not reachable / offline fallback
      }

      // 2. Fallback to mock data if Firestore is currently empty
      if (exams.isEmpty) {
        exams = MockExamRepository.exams;
      }
      if (categories.isEmpty) {
        categories = MockExamRepository.categories;
      }

      final defaultCategory = categories.isNotEmpty ? categories.first : 'All';
      final initialFiltered = _filterExams(exams, defaultCategory, '');

      emit(ExamLoaded(
        allExams: exams,
        filteredExams: initialFiltered,
        categories: categories,
        selectedCategory: defaultCategory,
        searchQuery: '',
        selectedExam: null,
      ));
    } catch (e) {
      emit(ExamError('Failed to load exams: ${e.toString()}'));
    }
  }

  void _onSelectCategory(SelectCategoryEvent event, Emitter<ExamState> emit) {
    if (state is ExamLoaded) {
      final current = state as ExamLoaded;
      final filtered = _filterExams(current.allExams, event.category, current.searchQuery);
      emit(current.copyWith(
        selectedCategory: event.category,
        filteredExams: filtered,
      ));
    }
  }

  void _onSearchExams(SearchExamsEvent event, Emitter<ExamState> emit) {
    if (state is ExamLoaded) {
      final current = state as ExamLoaded;
      final filtered = _filterExams(current.allExams, current.selectedCategory, event.query);
      emit(current.copyWith(
        searchQuery: event.query,
        filteredExams: filtered,
      ));
    }
  }

  void _onSelectExam(SelectExamEvent event, Emitter<ExamState> emit) {
    if (state is ExamLoaded) {
      final current = state as ExamLoaded;
      emit(current.copyWith(selectedExam: event.exam));
    }
  }

  List<Exam> _filterExams(List<Exam> exams, String category, String query) {
    final cleanQuery = query.trim().toLowerCase();
    final cleanCat = category.trim().toLowerCase();
    final cleanCatSlug = cleanCat.replaceAll(RegExp(r'[^a-z0-9]'), '');

    return exams.where((exam) {
      // Respect hidden flag for student view
      if (exam.isHidden) return false;

      final examCatSlug = exam.category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final examIdSlug = exam.categoryId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      final matchesCategory = cleanQuery.isNotEmpty ||
          cleanCat.isEmpty ||
          cleanCat == 'all' ||
          cleanCatSlug == 'all' ||
          exam.category.toLowerCase() == cleanCat ||
          exam.categoryId.toLowerCase() == cleanCat ||
          examCatSlug == cleanCatSlug ||
          examIdSlug == cleanCatSlug ||
          cleanCatSlug.contains(examCatSlug) ||
          examCatSlug.contains(cleanCatSlug) ||
          cleanCatSlug.contains(examIdSlug) ||
          examIdSlug.contains(cleanCatSlug);

      final matchesQuery = cleanQuery.isEmpty ||
          exam.name.toLowerCase().contains(cleanQuery) ||
          exam.title.toLowerCase().contains(cleanQuery) ||
          exam.shortCode.toLowerCase().contains(cleanQuery) ||
          exam.description.toLowerCase().contains(cleanQuery) ||
          exam.conductingBody.toLowerCase().contains(cleanQuery) ||
          exam.category.toLowerCase().contains(cleanQuery) ||
          exam.categoryId.toLowerCase().contains(cleanQuery);

      return matchesCategory && matchesQuery;
    }).toList();
  }
}
