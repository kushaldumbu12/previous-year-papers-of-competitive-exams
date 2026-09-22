import 'package:equatable/equatable.dart';
import '../../models/exam_model.dart';

abstract class ExamEvent extends Equatable {
  const ExamEvent();

  @override
  List<Object?> get props => [];
}

class LoadExamsEvent extends ExamEvent {
  const LoadExamsEvent();
}

class SelectCategoryEvent extends ExamEvent {
  final String category;
  const SelectCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchExamsEvent extends ExamEvent {
  final String query;
  const SearchExamsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectExamEvent extends ExamEvent {
  final Exam exam;
  const SelectExamEvent(this.exam);

  @override
  List<Object?> get props => [exam];
}
