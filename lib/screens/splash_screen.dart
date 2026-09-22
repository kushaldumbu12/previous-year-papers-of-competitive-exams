import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/user_preferences_service.dart';
import '../theme/app_theme.dart';
import 'exam_selection_screen.dart';
import 'year_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flip1Animation;
  late Animation<double> _flip2Animation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Page 1 Flip (0.12 to 0.52)
    _flip1Animation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.52, curve: Curves.easeInOutCubic),
      ),
    );

    // Page 2 Flip (0.52 to 0.92)
    _flip2Animation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.92, curve: Curves.easeInOutCubic),
      ),
    );

    // Text Fade & Slide
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Check user preference and navigate after animation completes
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final startTime = DateTime.now();
    Exam? preferredExam;

    try {
      preferredExam = await UserPreferencesService.getPreferredExam();
    } catch (e) {
      debugPrint('Error retrieving user preferred exam: $e');
    }

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remainingDelay = 2400 - elapsed;
    if (remainingDelay > 0) {
      await Future.delayed(Duration(milliseconds: remainingDelay));
    }

    if (mounted) {
      final Widget nextScreen = preferredExam != null
          ? YearSelectionScreen(exam: preferredExam)
          : const ExamSelectionScreen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Papers Turning Animation (Pure Paper Flip, No Icons)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return _PaperFlipWidget(
                  flip1Angle: _flip1Animation.value,
                  flip2Angle: _flip2Animation.value,
                );
              },
            ),

            const SizedBox(height: 36),

            // Title & Tagline with smooth entrance
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Exam Paper Collection',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All Competitive Question Papers',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated 3D Paper Flip Widget showing turning question paper pages
class _PaperFlipWidget extends StatelessWidget {
  final double flip1Angle;
  final double flip2Angle;

  const _PaperFlipWidget({
    required this.flip1Angle,
    required this.flip2Angle,
  });

  @override
  Widget build(BuildContext context) {
    const double pageWidth = 94.0;
    const double pageHeight = 126.0;

    return SizedBox(
      width: pageWidth * 2 + 16,
      height: pageHeight + 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Spine / Paper Stack Background Left Side
          Positioned(
            left: 8,
            child: _buildStaticPage(
              width: pageWidth,
              height: pageHeight,
              bgColor: const Color(0xFFF1F5F9),
              borderColor: const Color(0xFFCBD5E1),
              lineColor: const Color(0xFF94A3B8),
              isLeft: true,
            ),
          ),

          // Paper Stack Right Side (Base Page)
          Positioned(
            right: 8,
            child: _buildStaticPage(
              width: pageWidth,
              height: pageHeight,
              bgColor: const Color(0xFFEEF2FF),
              borderColor: const Color(0xFFC7D2FE),
              lineColor: const Color(0xFF818CF8),
              isLeft: false,
            ),
          ),

          // Under-page 2 (Revealed when Page 1 turns)
          Positioned(
            right: 8,
            child: _buildStaticPage(
              width: pageWidth,
              height: pageHeight,
              bgColor: const Color(0xFFFEF3C7),
              borderColor: const Color(0xFFFDE68A),
              lineColor: const Color(0xFFF59E0B),
              isLeft: false,
            ),
          ),

          // Turning Page 2
          Positioned(
            left: pageWidth + 8,
            child: _buildFlippingPage(
              width: pageWidth,
              height: pageHeight,
              angle: flip2Angle,
              frontBgColor: const Color(0xFFFEF3C7),
              frontBorderColor: const Color(0xFFFDE68A),
              frontLineColor: const Color(0xFFF59E0B),
              backBgColor: const Color(0xFFECFDF5),
              backBorderColor: const Color(0xFFA7F3D0),
              backLineColor: const Color(0xFF10B981),
            ),
          ),

          // Turning Page 1
          Positioned(
            left: pageWidth + 8,
            child: _buildFlippingPage(
              width: pageWidth,
              height: pageHeight,
              angle: flip1Angle,
              frontBgColor: Colors.white,
              frontBorderColor: const Color(0xFFE2E8F0),
              frontLineColor: const Color(0xFF6366F1),
              backBgColor: const Color(0xFFFAF5FF),
              backBorderColor: const Color(0xFFE9D5FF),
              backLineColor: const Color(0xFFA855F7),
            ),
          ),

          // Spine Clip / Binding Stitch
          Positioned(
            left: pageWidth + 5,
            top: 10,
            bottom: 10,
            child: Container(
              width: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF64748B),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticPage({
    required double width,
    required double height,
    required Color bgColor,
    required Color borderColor,
    required Color lineColor,
    required bool isLeft,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(10) : const Radius.circular(4),
          right: isLeft ? const Radius.circular(4) : const Radius.circular(10),
        ),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: _buildPaperLines(lineColor),
    );
  }

  Widget _buildFlippingPage({
    required double width,
    required double height,
    required double angle,
    required Color frontBgColor,
    required Color frontBorderColor,
    required Color frontLineColor,
    required Color backBgColor,
    required Color backBorderColor,
    required Color backLineColor,
  }) {
    final isBack = angle > (math.pi / 2);

    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0024) // 3D perspective depth
        ..rotateY(-angle),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isBack ? backBgColor : frontBgColor,
          borderRadius: BorderRadius.horizontal(
            left: isBack ? const Radius.circular(10) : const Radius.circular(4),
            right: isBack ? const Radius.circular(4) : const Radius.circular(10),
          ),
          border: Border.all(
            color: isBack ? backBorderColor : frontBorderColor,
            width: 1.6,
          ),
        ),
        child: isBack
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(math.pi),
                child: _buildPaperLines(backLineColor),
              )
            : _buildPaperLines(frontLineColor),
      ),
    );
  }

  Widget _buildPaperLines(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Header Bar
        Container(
          width: 32,
          height: 5,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 8),
        // Paper Line 1
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        // Paper Line 2
        Container(
          width: 58,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 10),
        // Option Line 1
        Container(
          width: 46,
          height: 3.5,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 5),
        // Option Line 2
        Container(
          width: 50,
          height: 3.5,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Spacer(),
        // Bottom Page Number Bar
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF94A3B8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
