import 'package:equatable/equatable.dart';
import '../../models/exam_model.dart';

abstract class ExamState extends Equatable {
  const ExamState();

  @override
  List<Object?> get props => [];
}

class ExamInitial extends ExamState {
  const ExamInitial();
}

class ExamLoading extends ExamState {
  const ExamLoading();
}

class ExamLoaded extends ExamState {
  final List<Exam> allExams;
  final List<Exam> filteredExams;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final Exam? selectedExam;

  const ExamLoaded({
    required this.allExams,
    required this.filteredExams,
    required this.categories,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.selectedExam,
  });

  ExamLoaded copyWith({
    List<Exam>? allExams,
    List<Exam>? filteredExams,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    Exam? selectedExam,
    bool clearSelectedExam = false,
  }) {
    return ExamLoaded(
      allExams: allExams ?? this.allExams,
      filteredExams: filteredExams ?? this.filteredExams,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedExam: clearSelectedExam ? null : (selectedExam ?? this.selectedExam),
    );
  }

  @override
  List<Object?> get props => [
        allExams,
        filteredExams,
        categories,
        selectedCategory,
        searchQuery,
        selectedExam,
      ];
}

class ExamError extends ExamState {
  final String message;
  const ExamError(this.message);

  @override
  List<Object?> get props => [message];
}
