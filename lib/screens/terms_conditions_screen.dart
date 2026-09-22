import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF64748B).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: const Icon(Icons.gavel_rounded, color: Color(0xFF4F46E5), size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms of Service & Usage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Last updated: September 2026',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildSection(
                number: '1',
                title: 'Educational & Fair-Use Purpose',
                content:
                    'Govt Exam Papers is an independent, non-commercial educational resource application designed to assist aspirants in preparing for competitive and recruitment examinations in India. All question papers, answer keys, and syllabus documents provided herein are collected from publicly accessible government exam portals and educational repositories solely for study, reference, and mock practice.',
              ),
              const SizedBox(height: 14),

              _buildSection(
                number: '2',
                title: 'No Government Affiliation',
                content:
                    'Govt Exam Papers is NOT affiliated with, sponsored by, authorized by, or associated with the Government of India, UPSC, SSC, IBPS, State Public Service Commissions (PSCs), NTA, or any other government examination conducting body. All official trademarks, examination names, logos, and emblems belong to their respective statutory boards and government authorities.',
              ),
              const SizedBox(height: 14),

              _buildSection(
                number: '3',
                title: 'Accuracy of Content & Solutions',
                content:
                    'While utmost diligence is exercised in compiling past question sets, official answer keys, and model solutions, errors or variations between provisional and final answer keys may occur. Candidates are strongly encouraged to cross-reference with official gazette notifications and official board portals for final confirmation.',
              ),
              const SizedBox(height: 14),

              _buildSection(
                number: '4',
                title: 'Local User Data & Notes',
                content:
                    'User-created study notes, bookmarks, and locally downloaded examination documents are stored directly on the user’s local device storage. You retain complete ownership of any personal study notes created inside the app.',
              ),
              const SizedBox(height: 14),

              _buildSection(
                number: '5',
                title: 'Prohibited Use',
                content:
                    'Users may not use automated web crawlers, scrapers, or reverse-engineering tools against the application infrastructure, nor republish mass archives for commercial monetization.',
              ),
              const SizedBox(height: 14),

              _buildSection(
                number: '6',
                title: 'Changes to Terms',
                content:
                    'We reserve the right to revise these Terms & Conditions from time to time to align with legal guidelines and evolving app features. Continued use of the application indicates acceptance of the amended terms.',
              ),
              const SizedBox(height: 24),

              // Contact note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Questions regarding our terms? Reach out via the in-app Feedback & Requests section.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
