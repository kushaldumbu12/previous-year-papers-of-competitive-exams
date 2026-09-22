import 'package:equatable/equatable.dart';
import '../../models/exam_model.dart';

abstract class PaperState extends Equatable {
  const PaperState();

  @override
  List<Object?> get props => [];
}

class PaperInitial extends PaperState {
  const PaperInitial();
}

class PaperLoading extends PaperState {
  const PaperLoading();
}

class PaperLoaded extends PaperState {
  final String examId;
  final String year;
  final List<ExamPaper> papers;
  final Set<String> downloadedPaperIds;
  final String? downloadingPaperId;
  final double downloadProgress;

  const PaperLoaded({
    required this.examId,
    required this.year,
    required this.papers,
    this.downloadedPaperIds = const {},
    this.downloadingPaperId,
    this.downloadProgress = 0.0,
  });

  PaperLoaded copyWith({
    String? examId,
    String? year,
    List<ExamPaper>? papers,
    Set<String>? downloadedPaperIds,
    String? downloadingPaperId,
    double? downloadProgress,
    bool clearDownloading = false,
  }) {
    return PaperLoaded(
      examId: examId ?? this.examId,
      year: year ?? this.year,
      papers: papers ?? this.papers,
      downloadedPaperIds: downloadedPaperIds ?? this.downloadedPaperIds,
      downloadingPaperId: clearDownloading
          ? null
          : (downloadingPaperId ?? this.downloadingPaperId),
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  @override
  List<Object?> get props => [
        examId,
        year,
        papers,
        downloadedPaperIds,
        downloadingPaperId,
        downloadProgress,
      ];
}

class PaperError extends PaperState {
  final String message;
  const PaperError(this.message);

  @override
  List<Object?> get props => [message];
}
