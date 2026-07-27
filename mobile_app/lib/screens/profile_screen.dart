import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_controller.dart';
import '../services/stats_service.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../services/calendar_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
    late AnimationController _bgController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late AnimationController _petalRotateController;
  // Settings state
  String _preferredTone = 'warm';
  String _translation = 'NIV';
  bool _voiceEnabled = true;
  String _responseLength = 'medium';
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  // Sacred practices
  bool _morningVerse = true;
  bool _eveningReflection = false;
  bool _sundayReview = true;
  bool _sacredInterruptions = true;
  bool _zenReminder = false;

  bool _calendarConnected = false;

    @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _petalRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

    @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    _petalRotateController.dispose();
    super.dispose();
  }

  // Determine identity based on top emotion
  Map<String, dynamic> _getIdentity() {
    final emotion = StatsService.getMostFrequentEmotion();
    switch (emotion) {
      case 'calm':
        return {'label': 'SEEKER OF STILLNESS', 'emoji': '🕊', 'color': const Color(0xFF7B2CBF)};
      case 'happy':
      case 'optimistic':
        return {'label': 'BEARER OF LIGHT', 'emoji': '☀', 'color': const Color(0xFFF77F00)};
      case 'sad':
      case 'depressed':
        return {'label': 'GENTLE HEART', 'emoji': '🌙', 'color': const Color(0xFF3A0CA3)};
      case 'angry':
        return {'label': 'WARRIOR OF PEACE', 'emoji': '🔥', 'color': const Color(0xFFD62828)};
      case 'grateful':
        return {'label': 'STEADY WALKER', 'emoji': '🌿', 'color': const Color(0xFF006D77)};
      case 'stressed':
      case 'anxious':
        return {'label': 'STORM RIDER', 'emoji': '⛈', 'color': const Color(0xFF264653)};
      case 'hopeful':
        return {'label': 'BRIGHT SOUL', 'emoji': '✨', 'color': const Color(0xFF7209B7)};
      default:
        return {'label': 'SEEKER OF STILLNESS', 'emoji': '🕊', 'color': const Color(0xFF7B2CBF)};
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController(),
      builder: (_, __) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF6E8),
          body: Stack(
            children: [
              Positioned.fill(
                child: _BlobBackground(
                  bgController: _bgController,
                  tint: ThemeService.getEmotionColor(),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 10),
                      _buildSoulSignatureCard()
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.15, curve: Curves.easeOutBack),
                      const SizedBox(height: 14),
                      _padded(_buildMilestonesCard())
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 500.ms)
                          .slideX(begin: -0.15, curve: Curves.easeOut),
                      const SizedBox(height: 14),
                      _padded(_buildInterventionHistoryCard())
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
                      const SizedBox(height: 14),
                      _padded(_buildSacredPracticesCard())
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 500.ms)
                          .slideX(begin: 0.15, curve: Curves.easeOut),
                      const SizedBox(height: 14),
                      _padded(_buildWeeklyReportCard())
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms)
                          .slideY(begin: 0.15, curve: Curves.easeOut),
                      const SizedBox(height: 14),
                      _padded(_buildVersesVaultCard())
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 600.ms)
                          .slideX(begin: -0.15, curve: Curves.easeOut),
                      const SizedBox(height: 14),
                      _padded(_buildRhythmsNoticedCard())
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 500.ms)
                          .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut),
                      const SizedBox(height: 14),
                      _padded(_buildCalendarCard())
                          .animate()
                          .fadeIn(delay: 700.ms, duration: 500.ms)
                          .slideX(begin: 0.15, curve: Curves.easeOut),
                      const SizedBox(height: 14),
                      _padded(_buildSettingsCard())
                          .animate()
                          .fadeIn(delay: 800.ms, duration: 500.ms)
                          .slideY(begin: 0.15, curve: Curves.easeOut),
                      const SizedBox(height: 14),
                      _padded(_buildExportCard())
                          .animate()
                          .fadeIn(delay: 900.ms, duration: 500.ms)
                          .slideY(begin: 0.15, curve: Curves.easeOut),
                      const SizedBox(height: 14),
                      _padded(_buildAboutCard())
                          .animate()
                          .fadeIn(delay: 1000.ms, duration: 600.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _padded(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      );

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F0F0F), size: 22),
            ),
          ),
          const Spacer(),
          Text(
            'You',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F0F0F),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 1. SOUL SIGNATURE HERO (violet)
  // ══════════════════════════════════════════════════════════════
    Widget _buildSoulSignatureCard() {
    final identity = _getIdentity();
    final daysActive = StatsService.streakDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _BentoBox(
        color: const Color(0xFF7B2CBF),
        patternPainter: _FlourishPattern(t: _shimmerController.value * 2 * pi),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3 + sin(_pulseController.value * pi) * 0.15),
                          blurRadius: 30,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: _AvatarFacePainter(
                        pulse: _pulseController.value,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Naren Rakesh',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 180,
                height: 20,
                child: CustomPaint(
                  painter: _FlourishLinePainter(t: _shimmerController.value),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Walking since July 2025 · $daysActive days',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _floatController,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, sin(_floatController.value * pi) * 3),
                        child: Text(
                          identity['emoji'] as String,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      identity['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.white,
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
  // ══════════════════════════════════════════════════════════════
  // 2. GROWTH MILESTONES (ruby red)
  // ══════════════════════════════════════════════════════════════
  Widget _buildMilestonesCard() {
    final streak = StatsService.streakDays;
    final verses = StatsService.versesReceived;
    final interruptions = StatsService.sacredInterruptions;
    final savedCount = StatsService.savedVerses.length;
    final interactions = StatsService.emotionHistory.length;
    final fingerprintReady = StatsService.glooFingerprint.isNotEmpty;

    final milestones = [
      {'label': 'First Week', 'icon': '🌱', 'unlocked': streak >= 7, 'req': '7 days'},
      {'label': '30 Days', 'icon': '🕊', 'unlocked': streak >= 30, 'req': '30 days'},
      {'label': '100 Verses', 'icon': '📖', 'unlocked': verses >= 100, 'req': '100 verses'},
      {'label': 'First Pause', 'icon': '🌙', 'unlocked': interruptions >= 1, 'req': 'First interruption'},
      {'label': 'Fingerprint', 'icon': '✨', 'unlocked': fingerprintReady, 'req': '5+ interactions'},
      {'label': '7-Day Streak', 'icon': '🔥', 'unlocked': streak >= 7, 'req': '7-day streak'},
      {'label': '30-Day Streak', 'icon': '💫', 'unlocked': streak >= 30, 'req': '30-day streak'},
      {'label': 'First Verse', 'icon': '📿', 'unlocked': savedCount >= 1, 'req': 'Save 1 verse'},
      {'label': 'Soul Map', 'icon': '🎯', 'unlocked': interactions >= 5, 'req': 'First soul map'},
      {'label': 'First Zen', 'icon': '🌊', 'unlocked': verses >= 3, 'req': 'Zen session'},
    ];

    return _BentoBox(
      color: const Color(0xFFD62828),
      patternPainter: _DiagonalStarburstPattern(t: _shimmerController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GROWTH MILESTONES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: milestones.length,
              itemBuilder: (context, i) {
                final m = milestones[i];
                final unlocked = m['unlocked'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      final glow = unlocked
                          ? 0.4 + sin(_pulseController.value * pi) * 0.2
                          : 0.0;
                      return Container(
                        width: 82,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        decoration: BoxDecoration(
                          color: unlocked
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(unlocked ? 0.4 : 0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            if (unlocked)
                              BoxShadow(
                                color: Colors.white.withOpacity(glow),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: unlocked ? 1.0 : 0.4,
                              child: Text(
                                m['icon'] as String,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              m['label'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(unlocked ? 0.95 : 0.5),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 3. INTERVENTION HISTORY (saffron)
  // ══════════════════════════════════════════════════════════════
  Widget _buildInterventionHistoryCard() {
    return _BentoBox(
      color: const Color(0xFFF77F00),
      patternPainter: _GridDotsPattern(t: _shimmerController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INTERVENTION HISTORY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          // 2x2 grid — spacious, big icons, big numbers
          Row(
            children: [
              Expanded(child: _statBox(
                Icons.pause_circle_outline_rounded,
                'Interruptions',
                StatsService.sacredInterruptions,
                const Color(0xFFFFCFA1),
              )),
              const SizedBox(width: 12),
              Expanded(child: _statBox(
                Icons.auto_stories_rounded,
                'Delivered',
                StatsService.versesReceived,
                const Color(0xFFFFDEBA),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statBox(
                Icons.insights_rounded,
                'Patterns',
                StatsService.habitsChecked,
                const Color(0xFFFFEACB),
              )),
              const SizedBox(width: 12),
              Expanded(child: _statBox(
                Icons.favorite_rounded,
                'Saved',
                StatsService.savedVerses.length,
                const Color(0xFFFFBB88),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String label, int count, Color chipColor) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: chipColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: chipColor.withOpacity(0.5),
                      blurRadius: 10 + sin(_pulseController.value * pi) * 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: const Color(0xFF7A3600), size: 22),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: count.toDouble()),
                builder: (context, v, __) {
                  return Text(
                    v.round().toString(),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 4. SACRED PRACTICES (teal)
  // ══════════════════════════════════════════════════════════════
  Widget _buildSacredPracticesCard() {
    return _BentoBox(
      color: const Color(0xFF006D77),
      patternPainter: _ConcentricArcsPattern(t: _shimmerController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SACRED PRACTICES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commit to the rhythms that hold you.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 18),
          _practiceRow(Icons.wb_sunny_rounded, 'Morning Verse', _morningVerse,
              (v) => setState(() => _morningVerse = v)),
          _practiceRow(Icons.nights_stay_rounded, 'Evening Reflection', _eveningReflection,
              (v) => setState(() => _eveningReflection = v)),
          _practiceRow(Icons.calendar_today_rounded, 'Sunday Soul Review', _sundayReview,
              (v) => setState(() => _sundayReview = v)),
          _practiceRow(Icons.pause_circle_outline_rounded, 'Sacred Interruptions', _sacredInterruptions,
              (v) => setState(() => _sacredInterruptions = v)),
          _practiceRow(Icons.spa_rounded, 'Zen Mode Reminder', _zenReminder,
              (v) => setState(() => _zenReminder = v)),
        ],
      ),
    );
  }

  Widget _practiceRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          _MiniToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 5. WEEKLY SOUL REPORT (slate)
  // ══════════════════════════════════════════════════════════════
  Widget _buildWeeklyReportCard() {
    final topEmotion = StatsService.getMostFrequentEmotion();
    final versesWeek = StatsService.versesReceived;
    final interruptsWeek = StatsService.sacredInterruptions;

    return _BentoBox(
      color: const Color(0xFF264653),
      patternPainter: _WaveLinesPattern(t: _shimmerController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _floatController,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, sin(_floatController.value * pi) * 2),
                  child: const Icon(Icons.summarize_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'THIS WEEK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You carried ${_capitalize(topEmotion)} most often.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _reportStat('Verses', versesWeek, Icons.menu_book_rounded)),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
              Expanded(child: _reportStat('Pauses', interruptsWeek, Icons.pause_rounded)),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
              Expanded(child: _reportStat('Days', StatsService.streakDays, Icons.today_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportStat(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: value.toDouble()),
          builder: (context, v, __) => Text(
            v.round().toString(),
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 6. VERSES VAULT (magenta)
  // ══════════════════════════════════════════════════════════════
  Widget _buildVersesVaultCard() {
    final saved = StatsService.savedVerses;

    return _BentoBox(
      color: const Color(0xFF7209B7),
      patternPainter: _SparkleScatterPattern(t: _shimmerController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'VERSES VAULT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              Text(
                '${saved.length} collected',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: saved.isEmpty
                ? Center(
                    child: Text(
                      'Your saved verses will appear here.\nSwipe right on any verse to save.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.6,
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: PageController(viewportFraction: 0.85),
                    itemCount: saved.length,
                    itemBuilder: (context, i) {
                      final v = saved[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '"${v['text']}"',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    height: 1.5,
                                    color: Colors.white,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '— ${v['ref']}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                  GestureDetector(
                                                                        onTap: () {
                                      StatsService.savedVerses.removeAt(i);
                                      setState(() {});
                                    },
                                    child: Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 7. RHYTHMS NOTICED — CIRCULAR PETALS (clay)
  // ══════════════════════════════════════════════════════════════
   Widget _buildRhythmsNoticedCard() {
    final pattern = StatsService.getTimeOfDayPattern();
    final counts = <String, int>{};
    for (final e in StatsService.emotionHistory) {
      final emotion = e['emotion'] as String;
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    final topEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = topEntries.take(6).toList();

    return _BentoBox(
      color: const Color(0xFFBC4749),
      patternPainter: _VerticalBarsPattern(t: _shimmerController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RHYTHMS NOTICED',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The emotions blooming most in you.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: AnimatedBuilder(
                animation: _petalRotateController,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _PetalsPainter(
                      entries: top,
                      t: _petalRotateController.value * 2 * pi,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: top.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: _emotionColor(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _capitalize(e.key),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  Color _emotionColor(String e) {
    switch (e) {
      case 'calm': return const Color(0xFFB8D8FF);
      case 'happy': return const Color(0xFFFFE066);
      case 'sad': return const Color(0xFFD8CCEF);
      case 'angry': return const Color(0xFFFF9B85);
      case 'hopeful': return const Color(0xFFBEE7FF);
      case 'anxious': return const Color(0xFFE8CFFF);
      case 'grateful': return const Color(0xFFCFF0D0);
      case 'stressed': return const Color(0xFFFFD9B0);
      case 'optimistic': return const Color(0xFFFFF0A8);
      case 'depressed': return const Color(0xFFC7CDDA);
      default: return const Color(0xFFFFFFFF);
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ══════════════════════════════════════════════════════════════
  // 8. CALENDAR (ocean)
  // ══════════════════════════════════════════════════════════════
  Widget _buildCalendarCard() {
    return _BentoBox(
      color: const Color(0xFF0077B6),
      patternPainter: _GridLinesPattern(t: _shimmerController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'CALENDAR CONNECTION',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _calendarConnected
                ? 'Connected. Lumíne walks with your day.'
                : 'Connect Google Calendar to receive verses timed to your events.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              // simple simulated toggle for now
              setState(() => _calendarConnected = !_calendarConnected);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _calendarConnected ? Icons.check_circle_rounded : Icons.link_rounded,
                    color: const Color(0xFF0077B6),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _calendarConnected ? 'Connected' : 'Connect',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0077B6),
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

  // ══════════════════════════════════════════════════════════════
  // 9. LUMÍNE SETTINGS (indigo)
  // ══════════════════════════════════════════════════════════════
  Widget _buildSettingsCard() {
    return _BentoBox(
      color: const Color(0xFF3A0CA3),
      patternPainter: _DotMeshPattern(t: _shimmerController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'LUMÍNE SETTINGS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _segmentRow(
            'Tone',
            ['warm', 'direct', 'gentle'],
            _preferredTone,
            (v) => setState(() => _preferredTone = v),
          ),
          const SizedBox(height: 14),
          _segmentRow(
            'Translation',
            ['KJV', 'NIV', 'ESV', 'MSG'],
            _translation,
            (v) => setState(() => _translation = v),
          ),
          const SizedBox(height: 14),
          _segmentRow(
            'Response length',
            ['short', 'medium', 'long'],
            _responseLength,
            (v) => setState(() => _responseLength = v),
          ),
          const SizedBox(height: 16),

          // Voice toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Voice output',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              _MiniToggle(
                value: _voiceEnabled,
                onChanged: (v) => setState(() => _voiceEnabled = v),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quiet hours
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.nights_stay_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Quiet hours',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              _timePill(_quietStart, (t) => setState(() => _quietStart = t)),
              Text(' → ', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withOpacity(0.7))),
              _timePill(_quietEnd, (t) => setState(() => _quietEnd = t)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segmentRow(String label, List<String> options, String current, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: options.map((opt) {
            final selected = opt == current;
            return GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? const Color(0xFF3A0CA3) : Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _timePill(TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          time.format(context),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 10. EXPORT SOUL MAP
  // ══════════════════════════════════════════════════════════════
  Widget _buildExportCard() {
    return _BentoBox(
      color: const Color(0xFFE85D75),
      patternPainter: _SparkleScatterPattern(t: _shimmerController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.share_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'EXPORT SOUL MAP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Save a beautiful image of your soul map — share it, keep it, remember it.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Soul map saved to gallery.',
                      style: GoogleFonts.plusJakartaSans()),
                  backgroundColor: const Color(0xFFE85D75),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_rounded, color: Color(0xFFE85D75), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Save as Image',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE85D75),
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

  // ══════════════════════════════════════════════════════════════
  // 11. ABOUT LUMÍNE (midnight)
  // ══════════════════════════════════════════════════════════════
  Widget _buildAboutCard() {
    return _BentoBox(
      color: const Color(0xFF1A1A2E),
      patternPainter: _StarScatterPattern(t: _shimmerController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + sin(_pulseController.value * pi) * 0.1,
                  child: const Text('✨', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ABOUT LUMÍNE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Lumíne is an ambient spiritual companion — Scripture that reads you. It listens deeply, notices your patterns, and delivers the right word at the right moment.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.6,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Powered by',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _creditChip('YouVersion Platform'),
              const SizedBox(width: 6),
              _creditChip('Gloo AI'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Your soul data stays on your device.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withOpacity(0.55),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'v1.0',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
              const Spacer(),
              Text('made with ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                  )),
              const Icon(Icons.favorite_rounded, color: Color(0xFFE85D75), size: 12),
              Text(' by Naren',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _creditChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// AVATAR FACE PAINTER — abstract painted face
// ══════════════════════════════════════════════════════════════════
class _AvatarFacePainter extends CustomPainter {
  final double pulse;
  _AvatarFacePainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Face circle — warm cream color
    canvas.drawCircle(center, w / 2, Paint()..color = const Color(0xFFFCE4B7));

    // Soft blush cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8FA3).withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(center.dx - w * 0.22, center.dy + h * 0.08), w * 0.08, blushPaint);
    canvas.drawCircle(Offset(center.dx + w * 0.22, center.dy + h * 0.08), w * 0.08, blushPaint);

    // Eyes — closed peaceful arcs
    final eyeY = center.dy - h * 0.05;
    final eyeSpacing = w * 0.16;
    final eyePaint = Paint()
      ..color = const Color(0xFF3A2618)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leftEye = Path();
    leftEye.moveTo(center.dx - eyeSpacing - w * 0.05, eyeY);
    leftEye.quadraticBezierTo(
      center.dx - eyeSpacing, eyeY - w * 0.035,
      center.dx - eyeSpacing + w * 0.05, eyeY,
    );
    canvas.drawPath(leftEye, eyePaint);

    final rightEye = Path();
    rightEye.moveTo(center.dx + eyeSpacing - w * 0.05, eyeY);
    rightEye.quadraticBezierTo(
      center.dx + eyeSpacing, eyeY - w * 0.035,
      center.dx + eyeSpacing + w * 0.05, eyeY,
    );
    canvas.drawPath(rightEye, eyePaint);

    // Small smile
    final mouthPath = Path();
    mouthPath.moveTo(center.dx - w * 0.08, center.dy + h * 0.18);
    mouthPath.quadraticBezierTo(
      center.dx, center.dy + h * 0.24,
      center.dx + w * 0.08, center.dy + h * 0.18,
    );
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFF3A2618)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarFacePainter old) => old.pulse != pulse;
}

// ══════════════════════════════════════════════════════════════════
// HANDWRITTEN FLOURISH LINE PAINTER
// ══════════════════════════════════════════════════════════════════
class _FlourishLinePainter extends CustomPainter {
  final double t;
  _FlourishLinePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(10, size.height * 0.5);
    for (double x = 10; x < size.width - 10; x += 4) {
      final progress = x / size.width;
      final wave = sin(progress * pi * 3) * 6 + sin(progress * pi * 7) * 3;
      path.lineTo(x, size.height * 0.5 + wave);
    }
    canvas.drawPath(path, paint);

    // small end swirl
    canvas.drawCircle(
      Offset(size.width - 8, size.height * 0.5),
      3,
      Paint()..color = Colors.white.withOpacity(0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _FlourishLinePainter old) => false;
}

// ══════════════════════════════════════════════════════════════════
// PETALS PAINTER (Rhythms Noticed)
// ══════════════════════════════════════════════════════════════════
class _PetalsPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final double t;

  _PetalsPainter({required this.entries, required this.t});

  Color _emotionColor(String e) {
    switch (e) {
      case 'calm': return const Color(0xFFB8D8FF);
      case 'happy': return const Color(0xFFFFE066);
      case 'sad': return const Color(0xFFD8CCEF);
      case 'angry': return const Color(0xFFFF9B85);
      case 'hopeful': return const Color(0xFFBEE7FF);
      case 'anxious': return const Color(0xFFE8CFFF);
      case 'grateful': return const Color(0xFFCFF0D0);
      case 'stressed': return const Color(0xFFFFD9B0);
      case 'optimistic': return const Color(0xFFFFF0A8);
      case 'depressed': return const Color(0xFFC7CDDA);
      default: return const Color(0xFFFFFFFF);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    if (entries.isEmpty) {
      canvas.drawCircle(center, 6, Paint()..color = Colors.white.withOpacity(0.4));
      return;
    }

    final maxCount = entries.first.value;
    final count = entries.length;

    for (int i = 0; i < count; i++) {
      final e = entries[i];
      // Continuous smooth rotation — t comes from a 40-second linear controller
      final angle = (i / count) * 2 * pi + t;
      final ratio = e.value / maxCount;
      final petalLen = size.width * 0.32 * (0.5 + ratio * 0.5);
      final petalWidth = size.width * 0.11 * (0.6 + ratio * 0.4);
      final petalCenter = Offset(
        center.dx + cos(angle) * petalLen * 0.6,
        center.dy + sin(angle) * petalLen * 0.6,
      );

      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle + pi / 2);

      final petalPath = Path();
      petalPath.moveTo(0, -petalLen * 0.5);
      petalPath.quadraticBezierTo(petalWidth, 0, 0, petalLen * 0.5);
      petalPath.quadraticBezierTo(-petalWidth, 0, 0, -petalLen * 0.5);
      petalPath.close();

      final petalPaint = Paint()..color = _emotionColor(e.key).withOpacity(0.85);
      canvas.drawPath(petalPath, petalPaint);

      canvas.drawPath(
        petalPath,
        Paint()
          ..color = Colors.white.withOpacity(0.35)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );

      canvas.restore();
    }

    canvas.drawCircle(
      center,
      18,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      10,
      Paint()..color = const Color(0xFFBC4749),
    );
  }

  @override
  bool shouldRepaint(covariant _PetalsPainter old) => old.t != t;
}
// ══════════════════════════════════════════════════════════════════
// MINI TOGGLE
// ══════════════════════════════════════════════════════════════════
class _MiniToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MiniToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 42, height: 24,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: value ? const Color(0xFF0F0F0F) : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// BENTO BOX
// ══════════════════════════════════════════════════════════════════
class _BentoBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final CustomPainter patternPainter;

  const _BentoBox({
    required this.child,
    required this.color,
    required this.patternPainter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: patternPainter)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CORNER BLOB BACKGROUND — like reference image
// ══════════════════════════════════════════════════════════════════
class _BlobBackground extends StatelessWidget {
  final AnimationController bgController;
  final Color tint;

  const _BlobBackground({required this.bgController, required this.tint});

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final w = view.physicalSize.width / view.devicePixelRatio;
    final h = view.physicalSize.height / view.devicePixelRatio;

    return RepaintBoundary(
      child: OverflowBox(
        minWidth: w, maxWidth: w,
        minHeight: h, maxHeight: h,
        alignment: Alignment.topLeft,
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeInOut,
          tween: ColorTween(begin: tint, end: tint),
          builder: (context, animatedTint, _) {
            return AnimatedBuilder(
              animation: bgController,
              builder: (_, __) {
                return CustomPaint(
                  size: Size(w, h),
                  painter: _CornerBlobPainter(
                    t: bgController.value * 2 * pi,
                    blobColor: animatedTint ?? tint,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CornerBlobPainter extends CustomPainter {
  final double t;
  final Color blobColor;

  _CornerBlobPainter({required this.t, required this.blobColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Cream base
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFDF6E8));

    final w = size.width;
    final h = size.height;

    final blobPaint = Paint()..color = blobColor;
    final blobPaintLight = Paint()..color = Color.lerp(blobColor, Colors.white, 0.35)!;
    final linePaint = Paint()
      ..color = const Color(0xFF0F0F0F).withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // ── Top-left blob ──
    _drawCornerBlob(
      canvas,
      Offset(-w * 0.1, -h * 0.05),
      w * 0.7,
      h * 0.28,
      blobPaint,
      linePaint,
      t + 0.5,
    );
    _drawCornerBlob(
      canvas,
      Offset(-w * 0.15, -h * 0.1),
      w * 0.5,
      h * 0.22,
      blobPaintLight,
      null,
      t + 1.5,
    );

    // ── Top-right blob ──
    _drawCornerBlob(
      canvas,
      Offset(w * 1.1, -h * 0.03),
      w * 0.55,
      h * 0.25,
      blobPaintLight,
      linePaint,
      t + 2.0,
    );

    // ── Bottom-left blob ──
    _drawCornerBlob(
      canvas,
      Offset(-w * 0.1, h * 1.05),
      w * 0.6,
      h * 0.25,
      blobPaintLight,
      linePaint,
      t + 3.0,
    );
    _drawCornerBlob(
      canvas,
      Offset(-w * 0.15, h * 1.08),
      w * 0.45,
      h * 0.2,
      blobPaint,
      null,
      t + 3.5,
    );

    // ── Bottom-right blob ──
    _drawCornerBlob(
      canvas,
      Offset(w * 1.1, h * 1.08),
      w * 0.65,
      h * 0.27,
      blobPaint,
      linePaint,
      t + 4.5,
    );
  }

  void _drawCornerBlob(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
    Paint paint,
    Paint? linePaint,
    double phase,
  ) {
    final path = Path();
    const points = 24;
    for (int i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * pi;
      final wobble = sin(angle * 3 + phase) * 20 + cos(angle * 2 + phase * 0.7) * 12;
      final x = center.dx + cos(angle) * (rx + wobble);
      final y = center.dy + sin(angle) * (ry + wobble);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    if (linePaint != null) canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _CornerBlobPainter old) =>
      old.t != t || old.blobColor != blobColor;
}

// ══════════════════════════════════════════════════════════════════
// PATTERN PAINTERS
// ══════════════════════════════════════════════════════════════════

class _FlourishPattern extends CustomPainter {
  final double t;
  _FlourishPattern({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final path = Path();
      final y = size.height * (0.15 + i * 0.18);
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 4) {
        path.lineTo(x, y + sin(x * 0.02 + t + i) * 6);
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _FlourishPattern old) => old.t != t;
}

class _DiagonalStarburstPattern extends CustomPainter {
  final double t;
  _DiagonalStarburstPattern({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.9, size.height * 0.2);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * pi + t * 0.1;
      canvas.drawLine(
        center,
        Offset(center.dx + cos(angle) * 200, center.dy + sin(angle) * 200),
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant _DiagonalStarburstPattern old) => old.t != t;
}

class _GridDotsPattern extends CustomPainter {
  final double t;
  _GridDotsPattern({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.08);
    for (double x = 12; x < size.width; x += 20) {
      for (double y = 12; y < size.height; y += 20) {
        final wave = sin(x * 0.05 + y * 0.05 + t) * 0.5 + 0.5;
        canvas.drawCircle(Offset(x, y), 1.2 * wave, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant _GridDotsPattern old) => old.t != t;
}

class _ConcentricArcsPattern extends CustomPainter {
  final double t;
  _ConcentricArcsPattern({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.1, size.height * 0.9);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 8; i++) {
      canvas.drawCircle(center, i * 30.0 + sin(t + i) * 3, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _ConcentricArcsPattern old) => old.t != t;
}

class _WaveLinesPattern extends CustomPainter {
  final double t;
  _WaveLinesPattern({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.8;
    for (double y = 20; y < size.height; y += 24) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 4) {
        path.lineTo(x, y + sin(x * 0.03 + t + y * 0.02) * 4);
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _WaveLinesPattern old) => old.t != t;
}

class _SparkleScatterPattern extends CustomPainter {
  final double t;
  _SparkleScatterPattern({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final sparkle = 0.5 + sin(t + i) * 0.5;
      canvas.drawCircle(
        Offset(x, y),
        1.5 * sparkle,
        Paint()..color = Colors.white.withOpacity(0.15 * sparkle),
      );
    }
  }
  @override
  bool shouldRepaint(covariant _SparkleScatterPattern old) => old.t != t;
}

class _VerticalBarsPattern extends CustomPainter {
  final double t;
  _VerticalBarsPattern({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.04);
    for (double x = 8; x < size.width; x += 14) {
      final h = size.height * (0.5 + sin(x * 0.05 + t) * 0.2);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - h, 4, h),
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant _VerticalBarsPattern old) => old.t != t;
}

class _GridLinesPattern extends CustomPainter {
  final double t;
  _GridLinesPattern({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _GridLinesPattern old) => old.t != t;
}

class _DotMeshPattern extends CustomPainter {
  final double t;
  _DotMeshPattern({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.08);
    for (double x = 10; x < size.width; x += 16) {
      for (double y = 10; y < size.height; y += 16) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant _DotMeshPattern old) => old.t != t;
}

class _StarScatterPattern extends CustomPainter {
  final double t;
  _StarScatterPattern({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final twinkle = 0.4 + sin(t * 1.5 + i) * 0.4;
      canvas.drawCircle(
        Offset(x, y),
        1.0 + twinkle * 0.5,
        Paint()..color = Colors.white.withOpacity(0.4 * twinkle),
      );
    }
  }
  @override
  bool shouldRepaint(covariant _StarScatterPattern old) => old.t != t;
}