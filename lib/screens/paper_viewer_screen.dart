import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../theme/app_theme.dart';

class PaperViewerScreen extends StatefulWidget {
  final ExamPaper paper;
  final Exam exam;

  const PaperViewerScreen({
    super.key,
    required this.paper,
    required this.exam,
  });

  @override
  State<PaperViewerScreen> createState() => _PaperViewerScreenState();
}

class _PaperViewerScreenState extends State<PaperViewerScreen> {
  int _currentPage = 1;
  final int _totalPages = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.paper.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${widget.exam.shortCode} • ${widget.paper.year}',
                              style: const TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.paper.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 18),

                    _buildQuestion(
                      qNum: (_currentPage - 1) * 3 + 1,
                      question:
                          'Which of the following bodies is responsible for conducting the Civil Services Examination in India?',
                      options: [
                        'A) Staff Selection Commission (SSC)',
                        'B) Union Public Service Commission (UPSC)',
                        'C) National Testing Agency (NTA)',
                        'D) Election Commission of India (ECI)',
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),

                    _buildQuestion(
                      qNum: (_currentPage - 1) * 3 + 2,
                      question:
                          'The Monetary Policy Committee (MPC) is constituted under which of the following institutions?',
                      options: [
                        'A) Ministry of Finance',
                        'B) NITI Aayog',
                        'C) Reserve Bank of India (RBI)',
                        'D) Securities and Exchange Board of India (SEBI)',
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),

                    _buildQuestion(
                      qNum: (_currentPage - 1) * 3 + 3,
                      question:
                          'Which river is traditionally called the "Granary of South India"?',
                      options: [
                        'A) Godavari',
                        'B) Kaveri (Cauvery)',
                        'C) Krishna',
                        'D) Mahanadi',
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    label: const Text('Prev'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Page $_currentPage of $_totalPages',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _currentPage < _totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion({
    required int qNum,
    required String question,
    required List<String> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Q$qNum. $question',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        ...options.map(
          (opt) => Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text(
              opt,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
