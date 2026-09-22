import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/mock_data.dart';
import '../../models/exam_model.dart';
import '../../services/bookmark_notes_service.dart';
import '../../services/firestore_service.dart';
import 'paper_event.dart';
import 'paper_state.dart';

class PaperBloc extends Bloc<PaperEvent, PaperState> {
  final FirestoreService _firestoreService;
  final BookmarkNotesService _bookmarkNotesService;
  final Set<String> _cachedDownloadedIds = {};

  PaperBloc({
    FirestoreService? firestoreService,
    BookmarkNotesService? bookmarkNotesService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _bookmarkNotesService = bookmarkNotesService ?? BookmarkNotesService(),
        super(const PaperInitial()) {
    on<LoadPapersForYearEvent>(_onLoadPapersForYear);
    on<DownloadPaperEvent>(_onDownloadPaper);
  }

  void _onLoadPapersForYear(
      LoadPapersForYearEvent event, Emitter<PaperState> emit) async {
    emit(const PaperLoading());
    try {
      List<ExamPaper> papers = [];

      // Fetch live materials from Firestore subcollection: exams/{examId}/years/{year}/materials
      try {
        papers = await _firestoreService.getMaterials(
          event.examId,
          event.year,
          includeHidden: false,
        );
      } catch (e) {
        // Fallback if offline / empty
      }

      if (papers.isEmpty) {
        papers = MockExamRepository.getPapersForYear(event.examId, event.year);
      }

      // Load stored local in-app downloaded IDs
      final savedDownloads = await _bookmarkNotesService.getDownloadedPaperIds(event.examId, event.year);
      _cachedDownloadedIds.addAll(savedDownloads);

      emit(PaperLoaded(
        examId: event.examId,
        year: event.year,
        papers: papers,
        downloadedPaperIds: Set.from(_cachedDownloadedIds),
      ));
    } catch (e) {
      emit(PaperError('Failed to load papers: ${e.toString()}'));
    }
  }

  void _onDownloadPaper(
      DownloadPaperEvent event, Emitter<PaperState> emit) async {
    if (state is PaperLoaded) {
      final current = state as PaperLoaded;
      final paperId = event.paper.id;

      // Simulate fast local app storage download progress steps
      emit(current.copyWith(
        downloadingPaperId: paperId,
        downloadProgress: 0.25,
      ));

      await Future.delayed(const Duration(milliseconds: 250));
      emit(current.copyWith(
        downloadingPaperId: paperId,
        downloadProgress: 0.75,
      ));

      await Future.delayed(const Duration(milliseconds: 250));
      emit(current.copyWith(
        downloadingPaperId: paperId,
        downloadProgress: 1.0,
      ));

      await Future.delayed(const Duration(milliseconds: 150));
      _cachedDownloadedIds.add(paperId);

      // Persist in app local storage
      await _bookmarkNotesService.toggleDownloadMaterial(current.examId, current.year, paperId);

      emit(current.copyWith(
        downloadedPaperIds: Set.from(_cachedDownloadedIds),
        clearDownloading: true,
        downloadProgress: 0.0,
      ));
    }
  }
}
