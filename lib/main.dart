import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/exam_bloc/exam_bloc.dart';
import 'blocs/exam_bloc/exam_event.dart';
import 'blocs/paper_bloc/paper_bloc.dart';
import 'firebase_options.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const ExamPapersApp());
}

class ExamPapersApp extends StatelessWidget {
  const ExamPapersApp({super.key});

  static Route<dynamic> _buildRoute(RouteSettings settings) {
    final rawName = (settings.name ?? '').toLowerCase();
    final uri = Uri.tryParse(settings.name ?? '/') ?? Uri.parse('/');
    final path = uri.path.toLowerCase();
    final fragment = uri.fragment.toLowerCase();

    final isAdmin = rawName.contains('admin') ||
        path.contains('admin') ||
        fragment.contains('admin');

    if (isAdmin) {
      final authService = AuthService();
      return MaterialPageRoute(
        builder: (context) => authService.isAuthenticated
            ? const AdminDashboardScreen()
            : const AdminLoginScreen(),
        settings: settings,
      );
    }

    // Default / Student App Entry Point
    return MaterialPageRoute(
      builder: (context) => const SplashScreen(),
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ExamBloc>(
          create: (context) => ExamBloc()..add(const LoadExamsEvent()),
        ),
        BlocProvider<PaperBloc>(
          create: (context) => PaperBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Exam Paper Collection',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          final width = MediaQuery.sizeOf(context).width;
          final double fontScale = width < 360
              ? 0.84
              : width < 400
                  ? 0.90
                  : width < 480
                      ? 0.95
                      : 1.0;

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(fontScale),
            ),
            child: child ?? const SizedBox(),
          );
        },
        onGenerateInitialRoutes: (initialRouteName) {
          // Detect current browser URL on startup, refresh, or hot restart
          String route = initialRouteName;
          final fragment = Uri.base.fragment;
          if (fragment.isNotEmpty) {
            final clean = fragment.startsWith('/') ? fragment : '/$fragment';
            if (clean.contains('admin')) {
              route = clean;
            }
          } else if (Uri.base.path.contains('admin')) {
            route = Uri.base.path;
          }

          return [
            _buildRoute(RouteSettings(name: route)),
          ];
        },
        onGenerateRoute: (settings) => _buildRoute(settings),
      ),
    );
  }
}
