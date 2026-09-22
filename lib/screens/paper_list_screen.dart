import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/paper_bloc/paper_bloc.dart';
import '../blocs/paper_bloc/paper_event.dart';
import '../blocs/paper_bloc/paper_state.dart';
import '../models/exam_model.dart';
import '../services/bookmark_notes_service.dart';
import '../theme/app_theme.dart';
import '../widgets/year_notes_modal.dart';
import 'paper_viewer_screen.dart';

class PaperListScreen extends StatelessWidget {
  final Exam exam;
  final String year;
  final BookmarkNotesService _bookmarkService = BookmarkNotesService();

  PaperListScreen({
    super.key,
    required this.exam,
    required this.year,
  });

  void _openViewer(BuildContext context, ExamPaper paper) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaperViewerScreen(paper: paper, exam: exam),
      ),
    );
  }

  void _openNotes(BuildContext context) {
    YearNotesModal.show(
      context,
      examId: exam.id,
      examTitle: exam.title,
      year: year,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('${exam.shortCode} $year'),
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _bookmarkService.updatesNotifier,
        builder: (context, _, __) {
          return FutureBuilder<List<NoteItem>>(
            future: _bookmarkService.getNotesList(exam.id, year),
            builder: (context, snapshot) {
              final notes = snapshot.data ?? [];
              final notesCount = notes.length;
              final hasStarred = notes.any((n) => n.isStarred);

              return GestureDetector(
                onTap: () => _openNotes(context),
                onVerticalDragUpdate: (details) {
                  // Detect upward pull/drag
                  if (details.delta.dy < -3) {
                    _openNotes(context);
                  }
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                    _openNotes(context);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 16, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Subtle pull handle indicator
                          Container(
                            width: 36,
                            height: 3.5,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sticky_note_2_rounded,
                                  color: Color(0xFF4F46E5),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Notes',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              if (notesCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$notesCount',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                              if (hasStarred) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 17,
                                  color: Color(0xFFF59E0B),
                                ),
                              ],
                              const Spacer(),
                              // Plus icon instead of up arrow
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFC7D2FE)),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      body: BlocConsumer<PaperBloc, PaperState>(
        listener: (context, state) {
          if (state is PaperLoaded &&
              state.downloadingPaperId == null &&
              state.downloadProgress == 0.0 &&
              state.downloadedPaperIds.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF1E293B),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Downloaded to app successfully!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaperLoading || state is PaperInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (state is PaperError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PaperBloc>().add(
                            LoadPapersForYearEvent(
                              examId: exam.id,
                              year: year,
                            ),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final loaded = state as PaperLoaded;
          final papers = loaded.papers;

          if (papers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.folder_off_outlined,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Materials Available for $year',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Question papers and solutions have not been uploaded for this year yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _openNotes(context),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Add Notes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ValueListenableBuilder<int>(
            valueListenable: _bookmarkService.updatesNotifier,
            builder: (context, _, __) {
              return FutureBuilder<List<String>>(
                future: _bookmarkService.getBookmarkedPaperIds(exam.id, year),
                builder: (context, bookmarkSnapshot) {
                  final bookmarkedIds = bookmarkSnapshot.data ?? [];

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 85),
                        itemCount: papers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final paper = papers[index];
                          final isDownloaded =
                              loaded.downloadedPaperIds.contains(paper.id);
                          final isDownloading =
                              loaded.downloadingPaperId == paper.id;
                          final isBookmarked = bookmarkedIds.contains(paper.id);

                          final bgColor = AppTheme.balloonCardColors[
                              index % AppTheme.balloonCardColors.length];
                          final accentColor = AppTheme.balloonAccentColors[
                              index % AppTheme.balloonAccentColors.length];

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.35),
                                width: 1.4,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row with Stage tag, Green Downloaded icon, and Bookmark button
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        paper.stage.isNotEmpty
                                            ? paper.stage.toUpperCase()
                                            : 'OFFICIAL PAPER',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: accentColor,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    if (isDownloaded) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFFA7F3D0),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF10B981),
                                              size: 13,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Downloaded',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF047857),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    // Bookmark Button
                                    InkWell(
                                      onTap: () async {
                                        final nowBookmarked = await _bookmarkService
                                            .toggleBookmark(exam.id, year, paper.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: const Color(0xFF0F172A),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              duration: const Duration(seconds: 1),
                                              content: Row(
                                                children: [
                                                  Icon(
                                                    nowBookmarked
                                                        ? Icons.bookmark_added_rounded
                                                        : Icons.bookmark_remove_rounded,
                                                    color: nowBookmarked
                                                        ? const Color(0xFFF59E0B)
                                                        : Colors.white70,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    nowBookmarked
                                                        ? 'Bookmarked paper!'
                                                        : 'Bookmark removed',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: isBookmarked
                                              ? const Color(0xFFFEF3C7)
                                              : Colors.white.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isBookmarked
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Icon(
                                          isBookmarked
                                              ? Icons.bookmark_rounded
                                              : Icons.bookmark_border_rounded,
                                          size: 16,
                                          color: isBookmarked
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Paper Title
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        paper.title,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                    if (isDownloaded) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF10B981),
                                        size: 17,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),

                                if (isDownloading) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: loaded.downloadProgress,
                                      backgroundColor: Colors.white,
                                      color: accentColor,
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                // Compact Action Buttons: Open & Download
                                Row(
                                  children: [
                                    // Open Button
                                    Expanded(
                                      child: SizedBox(
                                        height: 34,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _openViewer(context, paper),
                                          icon: const Icon(Icons.visibility_outlined, size: 15),
                                          label: const Text(
                                            'Open',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accentColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Download Button
                                    Expanded(
                                      child: SizedBox(
                                        height: 34,
                                        child: isDownloading
                                            ? OutlinedButton.icon(
                                                onPressed: null,
                                                icon: SizedBox(
                                                  width: 13,
                                                  height: 13,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: accentColor,
                                                  ),
                                                ),
                                                label: const Text(
                                                  'Saving...',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              )
                                            : isDownloaded
                                                ? ElevatedButton.icon(
                                                    onPressed: () {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          backgroundColor: const Color(0xFF065F46),
                                                          behavior: SnackBarBehavior.floating,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          duration: const Duration(seconds: 1),
                                                          content: const Row(
                                                            children: [
                                                              Icon(
                                                                Icons.check_circle_rounded,
                                                                color: Color(0xFF34D399),
                                                                size: 18,
                                                              ),
                                                              SizedBox(width: 8),
                                                              Text(
                                                                'Stored locally in app',
                                                                style: TextStyle(
                                                                    fontWeight: FontWeight.w600),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.check_circle_rounded,
                                                      size: 15,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                    label: const Text(
                                                      'Downloaded',
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF047857),
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFFECFDF5),
                                                      foregroundColor: const Color(0xFF047857),
                                                      elevation: 0,
                                                      side: const BorderSide(
                                                        color: Color(0xFFA7F3D0),
                                                        width: 1.2,
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                  )
                                                : ElevatedButton.icon(
                                                    onPressed: () {
                                                      context.read<PaperBloc>().add(
                                                            DownloadPaperEvent(paper),
                                                          );
                                                    },
                                                    icon: Icon(
                                                      Icons.download_rounded,
                                                      size: 15,
                                                      color: accentColor,
                                                    ),
                                                    label: Text(
                                                      'Download',
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: accentColor,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.white,
                                                      foregroundColor: accentColor,
                                                      elevation: 0,
                                                      side: BorderSide(
                                                        color: accentColor.withValues(alpha: 0.6),
                                                        width: 1.2,
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                  ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
