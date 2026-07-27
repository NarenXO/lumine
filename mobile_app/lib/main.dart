import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart' hide HabitsScreen;
import 'screens/chat_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/scripture_feed_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sacred_interruption_screen.dart';
import 'services/notification_service.dart';
import 'services/stats_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService.initialize();
  await NotificationService.scheduleDailyScripture(hour: 8, minute: 0);
  await StatsService.loadAll();
  
  runApp(const LumineApp());
}

class LumineApp extends StatelessWidget {
  const LumineApp({super.key});

  static const Color background = Color(0xFFFDFCF0);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentPeach = Color(0xFFFBCFE8);
  static const Color textMain = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumíne',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: background,
        primaryColor: accentIndigo,
          pageTransitionsTheme: PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
),
        
        textTheme: TextTheme(
          displayLarge: GoogleFonts.playfairDisplay(
            color: textMain,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            color: textMain,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            color: textMain,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            color: textSecondary,
            fontSize: 14,
          ),
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: accentPeach.withOpacity(0.5),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        
        // Removed the problematic PageTransitionsTheme block
      ),

      home: const LumineHome(),
      
      routes: {
        '/dashboard': (context) =>  DashboardScreen(),
        '/chat': (context) => const ChatScreen(),
        '/habits': (context) => const HabitsScreen(),
        '/feed': (context) => const ScriptureFeedScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/sacred': (context) => const SacredInterruptionScreen(
              scriptureText: "Be still, and know that I am God.",
              scriptureRef: "Psalm 46:10",
            ),
      },
    );
  }
}