import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Icon(Icons.security_rounded, color: Color(0xFF059669), size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Privacy & Data Safety',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Zero intrusive tracking • Local-first storage',
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
                icon: Icons.storage_rounded,
                iconColor: const Color(0xFF4F46E5),
                title: '1. Local Device Storage for Notes & Bookmarks',
                content:
                    'All user-generated study notes, formatted bullet points, bookmarks, and saved question paper caches are stored 100% locally on your device (using SharedPreferences and local sandboxed storage). We do not transmit or store your personal notes on our external servers.',
              ),
              const SizedBox(height: 14),

              _buildSection(
                icon: Icons.no_accounts_rounded,
                iconColor: const Color(0xFF0284C7),
                title: '2. Information We Do NOT Collect',
                content:
                    'We do not collect sensitive personal data such as your national ID, banking information, precise GPS location, or contact book. Browsing question papers does not require mandatory account registration or invasive permissions.',
              ),
              const SizedBox(height: 14),

              _buildSection(
                icon: Icons.cloud_done_rounded,
                iconColor: const Color(0xFF10B981),
                title: '3. Cloud & Hosting Services',
                content:
                    'Examination papers and catalog metadata are securely served via Google Cloud / Firebase infrastructure. When you submit feedback or paper requests, only the feedback message, optional name, and exam reference are sent to our review team.',
              ),
              const SizedBox(height: 14),

              _buildSection(
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFE11D48),
                title: '4. Data Deletion & Reset',
                content:
                    'You can remove all saved notes and bookmarks at any time simply by clearing them in the notes editor, un-bookmarking items, or clearing the app storage cache from your system settings.',
              ),
              const SizedBox(height: 14),

              _buildSection(
                icon: Icons.verified_user_outlined,
                iconColor: const Color(0xFF7C3AED),
                title: '5. Children and Student Privacy',
                content:
                    'Our application is suitable for students and aspirants of all ages. We do not knowingly collect personal identifiable information from minors.',
              ),
              const SizedBox(height: 24),

              // Contact / Feedback note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Have privacy questions or feedback? Please use the Feedback section inside the app.',
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
    required IconData icon,
    required Color iconColor,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
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
