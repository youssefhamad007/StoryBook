import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_stories_screen.dart';
import 'screens/story_editor_screen.dart';
import 'screens/story_viewer_screen.dart';
import 'screens/story_preview_screen.dart';
import 'screens/settings_screen.dart';

class StorybookApp extends StatelessWidget {
  const StorybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Children's Storybook",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.nunito(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.foreground,
          ),
          headlineLarge: GoogleFonts.nunito(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
          headlineMedium: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
          titleLarge: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
          bodyLarge: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.foreground,
          ),
          bodyMedium: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.mutedForeground,
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const HomeScreen(),
        '/stories': (context) => const MyStoriesScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';

        if (name.startsWith('/editor/')) {
          final id = name.replaceFirst('/editor/', '');
          return _fadeRoute(
            StoryEditorScreen(storyId: id == 'new' ? null : id),
          );
        }
        if (name.startsWith('/viewer/')) {
          final id = name.replaceFirst('/viewer/', '');
          return _fadeRoute(StoryViewerScreen(storyId: id));
        }
        if (name.startsWith('/preview/')) {
          final id = name.replaceFirst('/preview/', '');
          return _fadeRoute(StoryPreviewScreen(storyId: id));
        }
        return null;
      },
    );
  }

  PageRoute _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
