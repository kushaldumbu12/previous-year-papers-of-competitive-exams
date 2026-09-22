import 'package:equatable/equatable.dart';
import '../../models/exam_model.dart';

abstract class PaperEvent extends Equatable {
  const PaperEvent();

  @override
  List<Object?> get props => [];
}

class LoadPapersForYearEvent extends PaperEvent {
  final String examId;
  final String year;

  const LoadPapersForYearEvent({required this.examId, required this.year});

  @override
  List<Object?> get props => [examId, year];
}

class DownloadPaperEvent extends PaperEvent {
  final ExamPaper paper;

  const DownloadPaperEvent(this.paper);

  @override
  List<Object?> get props => [paper];
}
