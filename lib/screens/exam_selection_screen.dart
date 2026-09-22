import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/exam_bloc/exam_bloc.dart';
import '../blocs/exam_bloc/exam_event.dart';
import '../blocs/exam_bloc/exam_state.dart';
import '../models/exam_model.dart';
import '../services/user_preferences_service.dart';
import '../theme/app_theme.dart';
import 'year_selection_screen.dart';

class ExamSelectionScreen extends StatefulWidget {
  const ExamSelectionScreen({super.key});

  @override
  State<ExamSelectionScreen> createState() => _ExamSelectionScreenState();
}

class _ExamSelectionScreenState extends State<ExamSelectionScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onConfirmExam(BuildContext context, Exam selectedExam) {
    // Save user's target exam preference
    UserPreferencesService.savePreferredExam(selectedExam);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            YearSelectionScreen(exam: selectedExam),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            Navigator.of(context).pushNamed('/admin');
          },
          child: const Text('Choose Your Exam'),
        ),
      ),
      body: BlocBuilder<ExamBloc, ExamState>(
        builder: (context, state) {
          if (state is ExamLoading || state is ExamInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (state is ExamError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ExamBloc>().add(const LoadExamsEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final loadedState = state as ExamLoaded;
          final categories = loadedState.categories;
          final selectedCategory = loadedState.selectedCategory;
          final exams = loadedState.filteredExams;
          final selectedExam = loadedState.selectedExam;
          final isSearching = loadedState.searchQuery.trim().isNotEmpty;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _focusNode.unfocus(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                  child: GestureDetector(
                    onTap: () => _focusNode.requestFocus(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF64748B).withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        enableInteractiveSelection: true,
                        autofocus: false,
                        onChanged: (val) {
                          context.read<ExamBloc>().add(SearchExamsEvent(val));
                          setState(() {});
                        },
                        onSubmitted: (_) => _focusNode.unfocus(),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search exam name, acronym, or full form...',
                          hintStyle: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF6366F1),
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<ExamBloc>()
                                        .add(const SearchExamsEvent(''));
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Categories in Multi-line Flex Wrap (No horizontal scroll)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Builder(
                  builder: (context) {
                    final width = MediaQuery.sizeOf(context).width;
                    final isSmall = width < 380;

                    return Wrap(
                      spacing: isSmall ? 6 : 8,
                      runSpacing: isSmall ? 6 : 8,
                      children: categories.map((cat) {
                        final isSelected = !isSearching && cat == selectedCategory;

                        return GestureDetector(
                          onTap: () {
                            if (_searchController.text.isNotEmpty) {
                              _searchController.clear();
                              context
                                  .read<ExamBloc>()
                                  .add(const SearchExamsEvent(''));
                            }
                            context.read<ExamBloc>().add(SelectCategoryEvent(cat));
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 10 : 13,
                              vertical: isSmall ? 6 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4F46E5)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF334155),
                                fontSize: isSmall ? 11.5 : 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Line Break / Divider
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Divider(
                  height: 1,
                  thickness: 1.2,
                  color: Color(0xFFE2E8F0),
                ),
              ),

              const SizedBox(height: 12),

              // Grid of Solid Flat Rounded Exam Cards (No Glow)
              Expanded(
                child: exams.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isSearching
                                    ? 'No exams matching "${loadedState.searchQuery}"'
                                    : 'No exams available in this category',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final width = MediaQuery.sizeOf(context).width;
                          final isCompact = width < 380;
                          final isWebWide = width >= 600;

                          final int crossAxisCount = width >= 1100
                              ? 5
                              : width >= 850
                                  ? 4
                                  : width >= 600
                                      ? 3
                                      : 2;

                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: isCompact ? 8 : 12,
                                  mainAxisSpacing: isCompact ? 8 : 12,
                                  childAspectRatio: isWebWide
                                      ? 1.9
                                      : isCompact
                                          ? 1.55
                                          : 1.65,
                                ),
                                itemCount: exams.length,
                                itemBuilder: (context, index) {
                                  final exam = exams[index];
                                  final isSelected = selectedExam?.id == exam.id;

                                  final bgColor = AppTheme.balloonCardColors[
                                      index % AppTheme.balloonCardColors.length];
                                  final accentColor = AppTheme.balloonAccentColors[
                                      index % AppTheme.balloonAccentColors.length];

                                  // Only show description if provided and not just repeating the exam name/code
                                  final rawDesc = exam.description.trim();
                                  final examName = exam.name.trim();
                                  final examShort = exam.shortCode.trim();
                                  final examTitle = exam.title.trim();
                                  final hasValidDesc = rawDesc.isNotEmpty &&
                                      rawDesc.toLowerCase() != examName.toLowerCase() &&
                                      rawDesc.toLowerCase() != examShort.toLowerCase() &&
                                      rawDesc.toLowerCase() != examTitle.toLowerCase();

                                  return GestureDetector(
                                    onTap: () {
                                      context
                                          .read<ExamBloc>()
                                          .add(SelectExamEvent(exam));
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isCompact ? 8 : 12,
                                        vertical: isCompact ? 8 : 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected ? accentColor : bgColor,
                                        borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
                                        border: Border.all(
                                          color: accentColor.withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: accentColor
                                                      .withValues(alpha: 0.38),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : const [],
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Bold Exam Name / Short Code
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                exam.shortCode.isNotEmpty ? exam.shortCode : exam.name,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : accentColor,
                                                  fontSize: isCompact ? 15 : 17,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ),
                                            if (hasValidDesc) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                rawDesc,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                          .withValues(alpha: 0.88)
                                                      : const Color(0xFF64748B),
                                                  fontSize: isCompact ? 10 : 11,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    ),

      // Bottom Confirm Floating Button
      bottomSheet: BlocBuilder<ExamBloc, ExamState>(
        builder: (context, state) {
          final selectedExam =
              state is ExamLoaded ? state.selectedExam : null;

          return Container(
            color: AppTheme.background,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedExam != null
                      ? () => _onConfirmExam(context, selectedExam)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF94A3B8).withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.grey.shade500,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    selectedExam != null
                        ? 'Continue with ${selectedExam.shortCode}'
                        : 'Choose an Exam to Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
