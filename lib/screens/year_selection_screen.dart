import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/paper_bloc/paper_bloc.dart';
import '../blocs/paper_bloc/paper_event.dart';
import '../models/exam_model.dart';
import '../services/bookmark_notes_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'exam_selection_screen.dart';
import 'feedback_screen.dart';
import 'go_ads_free_screen.dart';
import 'paper_list_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class YearSelectionScreen extends StatelessWidget {
  final Exam exam;
  final FirestoreService _firestoreService = FirestoreService();
  final BookmarkNotesService _bookmarkService = BookmarkNotesService();

  YearSelectionScreen({super.key, required this.exam});

  void _showUpdatesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Color(0xFF4F46E5),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '${exam.shortCode} Updates',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildUpdateTile(
                    title: '${exam.shortCode} Solved Papers & Keys Added',
                    time: 'Just now',
                    desc: 'All official question sets with verified solutions are uploaded.',
                    isNew: true,
                  ),
                  const SizedBox(height: 10),
                  _buildUpdateTile(
                    title: 'Answer Key & Analysis Published',
                    time: '2 days ago',
                    desc: 'Detailed section-wise marks analysis and solutions are ready.',
                    isNew: false,
                  ),
                  const SizedBox(height: 10),
                  _buildUpdateTile(
                    title: 'Syllabus & Notification Alert',
                    time: '1 week ago',
                    desc: 'Latest notification circular for upcoming examination cycle.',
                    isNew: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpdateTile({
    required String title,
    required String time,
    required String desc,
    required bool isNew,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNew ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- STREAMLINED LIGHT DRAWER (REDUCED WIDTH, NO SUBTITLES/ARROWS, SIMPLE LIGHT BG) ---

  Widget _buildLeftDrawer(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Drawer(
        backgroundColor: Colors.white,
        elevation: 1,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Business & Selected Exam (Simple Light Header with Divider)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        const Text(
                          'Exam Papers',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFF4F46E5), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              exam.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

              // Navigation Menu Items (Clean: Icon + Title only, no description, no arrow)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.stars_rounded,
                      iconColor: const Color(0xFFD97706),
                      title: 'Go Ads-Free (PRO)',
                      trailingBadge: 'PRO',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GoAdsFreeScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.star_rate_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Rate Us',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackScreen(
                              currentExam: exam,
                              initialCategory: 'General Feedback',
                              initialRating: 5,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.edit_note_rounded,
                      iconColor: const Color(0xFFE11D48),
                      title: 'Write a Correction',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackScreen(
                              currentExam: exam,
                              initialCategory: 'Answer Key / Solution Correction',
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 16, thickness: 1, color: Color(0xFFF1F5F9)),
                    _buildDrawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: const Color(0xFF64748B),
                      title: 'Admin Console',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin');
                      },
                    ),
                  ],
                ),
              ),

              // Bottom Section (Simple light divider, Switch Exam button, Terms, Privacy Policy & Version)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Switch Exam button with switch icon
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExamSelectionScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF4F46E5)),
                            SizedBox(width: 8),
                            Text(
                              'Switch Exam',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Terms and Privacy Policy Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              'Terms',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ),
                        const Text(' • ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              'Privacy',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Light Faded Version Number at Bottom
                    const Text(
                      'v1.0.0+1',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB0BCCB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    Color? iconColor,
    String? trailingBadge,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? (isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569)),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trailingBadge,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: _buildLeftDrawer(context),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 26, color: Color(0xFF1E293B)),
            tooltip: 'Open Menu & Target Exam',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(exam.shortCode),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showUpdatesBottomSheet(context),
              tooltip: 'Updates & Notifications',
              icon: Badge(
                label: const Text(
                  '3',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFFEF4444),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 24,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // Centered Exam Header Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        exam.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select Exam Year to Explore Papers',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Grid of Clean, Sleek Uniform Year Cards with Bookmark and Note badges
              Expanded(
                child: StreamBuilder<List<ExamYearInfo>>(
                  stream: _firestoreService.streamYears(exam.id, includeHidden: false),
                  builder: (context, snapshot) {
                    List<String> yearsList = [];

                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      yearsList = snapshot.data!.map((y) => y.yearString).toList();
                    } else if (exam.availableYears.isNotEmpty) {
                      yearsList = exam.availableYears;
                    }

                    if (yearsList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 48, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            Text(
                              'No papers released yet for ${exam.shortCode}',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      );
                    }

                    return ValueListenableBuilder<int>(
                      valueListenable: _bookmarkService.updatesNotifier,
                      builder: (context, _, __) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 650 ? 3 : 2;

                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: crossAxisCount == 3 ? 2.3 : 2.1,
                              ),
                              itemCount: yearsList.length,
                              itemBuilder: (context, index) {
                                final year = yearsList[index];

                                return FutureBuilder<List<bool>>(
                                  future: Future.wait([
                                    _bookmarkService.hasBookmarksForYear(exam.id, year),
                                    _bookmarkService.hasNotes(exam.id, year),
                                  ]),
                                  builder: (context, statusSnapshot) {
                                    final isBookmarked = statusSnapshot.data != null && statusSnapshot.data!.isNotEmpty
                                        ? statusSnapshot.data![0]
                                        : false;
                                    final hasNotes = statusSnapshot.data != null && statusSnapshot.data!.length > 1
                                        ? statusSnapshot.data![1]
                                        : false;

                                    return GestureDetector(
                                      onTap: () {
                                        context.read<PaperBloc>().add(
                                              LoadPapersForYearEvent(
                                                examId: exam.id,
                                                year: year,
                                              ),
                                            );

                                        Navigator.of(context).push(
                                          PageRouteBuilder(
                                            pageBuilder:
                                                (context, animation, secondaryAnimation) =>
                                                    PaperListScreen(exam: exam, year: year),
                                            transitionsBuilder: (context, animation,
                                                secondaryAnimation, child) {
                                              return SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(1.0, 0.0),
                                                  end: Offset.zero,
                                                ).animate(
                                                  CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeOutCubic,
                                                  ),
                                                ),
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                year,
                                                style: const TextStyle(
                                                  color: Color(0xFF0F172A),
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Bookmark indicator icon on top right (clean, without circle)
                                          if (isBookmarked)
                                            const Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Icon(
                                                Icons.bookmark_rounded,
                                                size: 16,
                                                color: Color(0xFFF59E0B),
                                              ),
                                            ),

                                          // Notes indicator icon on bottom right (clean, without circle)
                                          if (hasNotes)
                                            const Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Icon(
                                                Icons.sticky_note_2_rounded,
                                                size: 15,
                                                color: Color(0xFF4F46E5),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
