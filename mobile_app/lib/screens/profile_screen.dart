import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_controller.dart';
import '../services/stats_service.dart';
import '../services/theme_service.dart';
import '../services/memory_service.dart';
import '../services/app_theme.dart';
import '../widgets/lumine_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late AnimationController _petalRotateController;

  static const Color _calm = Color(0xFF7BA9F0);
  static const Color _happy = Color(0xFFFFD470);
  static const Color _sad = Color(0xFFB8A0E8);
  static const Color _angry = Color(0xFFFF7C6B);
  static const Color _hopeful = Color(0xFF6BC5D9);
  static const Color _anxious = Color(0xFFC688F0);
  static const Color _grateful = Color(0xFF7DD69F);
  static const Color _stressed = Color(0xFFFFA560);
  static const Color _optimistic = Color(0xFFFFDF80);
  static const Color _depressed = Color(0xFF8FA0B8);

  String _preferredTone = 'warm';
  String _translation = 'NIV';
  bool _voiceEnabled = true;
  String _responseLength = 'medium';
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  bool _morningVerse = true;
  bool _eveningReflection = false;
  bool _sundayReview = true;
  bool _sacredInterruptions = true;
  bool _zenReminder = false;

  bool _calendarConnected = false;

  @override
  void initState() {
    super.initState();
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
    _pulseController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    _petalRotateController.dispose();
    super.dispose();
  }

  Color _emotionAccent(String e) {
    switch (e) {
      case 'calm': return _calm;
      case 'happy': return _happy;
      case 'sad': return _sad;
      case 'angry': return _angry;
      case 'hopeful': return _hopeful;
      case 'anxious': return _anxious;
      case 'grateful': return _grateful;
      case 'stressed': return _stressed;
      case 'optimistic': return _optimistic;
      case 'depressed': return _depressed;
      default: return _calm;
    }
  }

  IconData _getIdentityIcon(String emotion) {
    switch (emotion) {
      case 'calm': return Icons.spa;
      case 'happy':
      case 'optimistic': return Icons.wb_sunny;
      case 'sad':
      case 'depressed': return Icons.nights_stay;
      case 'angry': return Icons.shield;
      case 'grateful': return Icons.favorite_border;
      case 'stressed':
      case 'anxious': return Icons.air;
      case 'hopeful': return Icons.star_border;
      default: return Icons.spa;
    }
  }

  String _getIdentityLabel(String emotion) {
    switch (emotion) {
      case 'calm': return 'SEEKER OF STILLNESS';
      case 'happy':
      case 'optimistic': return 'BEARER OF LIGHT';
      case 'sad':
      case 'depressed': return 'GENTLE HEART';
      case 'angry': return 'WARRIOR OF PEACE';
      case 'grateful': return 'STEADY WALKER';
      case 'stressed':
      case 'anxious': return 'STORM RIDER';
      case 'hopeful': return 'BRIGHT SOUL';
      default: return 'SEEKER OF STILLNESS';
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController(),
      builder: (_, __) {
        final emotionColor = ThemeService.getEmotionColor();
        return Scaffold(
          backgroundColor: AppTheme.bgDeep,
          body: Stack(
            children: [
              const Positioned.fill(child: LumineBackground()),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 10),
                      _buildSoulSignatureCard(emotionColor)
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
                      const SizedBox(height: 120),
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
                color: AppTheme.bgSlate,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderSoft),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary, size: 22),
            ),
          ),
          const Spacer(),
          Text(
            'You',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 1. SOUL SIGNATURE
  // ═══════════════════════════════════════════════════════════
  Widget _buildSoulSignatureCard(Color emotionColor) {
    final emotion = StatsService.getMostFrequentEmotion();
    final label = _getIdentityLabel(emotion);
    final icon = _getIdentityIcon(emotion);
    final daysActive = StatsService.streakDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _ProfileBentoBox(
        accentColor: emotionColor,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              // Original warm cream face
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
                          color: emotionColor.withOpacity(
                              0.3 + sin(_pulseController.value * pi) * 0.15),
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
              const SizedBox(height: 20),
              Text(
                'Naren Rakesh',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 180,
                height: 20,
                child: CustomPaint(
                  painter: _ProfileFlourishLinePainter(
                      t: _shimmerController.value),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Walking since July 2025 · $daysActive days',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: emotionColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: emotionColor.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _floatController,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, sin(_floatController.value * pi) * 4),
                        child: Transform.rotate(
                          angle: sin(_floatController.value * pi) * 0.15,
                          child: Icon(icon, color: emotionColor, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: emotionColor,
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

  // ═══════════════════════════════════════════════════════════
  // 2. GROWTH MILESTONES
  // ═══════════════════════════════════════════════════════════
  Widget _buildMilestonesCard() {
    final streak = StatsService.streakDays;
    final verses = StatsService.versesReceived;
    final interruptions = StatsService.sacredInterruptions;
    final savedCount = StatsService.savedVerses.length;
    final interactions = StatsService.emotionHistory.length;
    final fingerprintReady = StatsService.glooFingerprint.isNotEmpty;

    final milestones = [
      {'label': 'First Week', 'icon': Icons.spa, 'unlocked': streak >= 7},
      {'label': '30 Days', 'icon': Icons.self_improvement, 'unlocked': streak >= 30},
      {'label': '100 Verses', 'icon': Icons.menu_book_rounded, 'unlocked': verses >= 100},
      {'label': 'First Pause', 'icon': Icons.pause_circle_outline, 'unlocked': interruptions >= 1},
      {'label': 'Fingerprint', 'icon': Icons.fingerprint, 'unlocked': fingerprintReady},
      {'label': '7-Day Streak', 'icon': Icons.whatshot, 'unlocked': streak >= 7},
      {'label': '30-Day Streak', 'icon': Icons.auto_awesome, 'unlocked': streak >= 30},
      {'label': 'First Verse', 'icon': Icons.bookmark_added, 'unlocked': savedCount >= 1},
      {'label': 'Soul Map', 'icon': Icons.map_outlined, 'unlocked': interactions >= 5},
      {'label': 'First Zen', 'icon': Icons.waves, 'unlocked': verses >= 3},
    ];

    return _ProfileBentoBox(
      accentColor: AppTheme.goldMid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('GROWTH MILESTONES'),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: milestones.length,
              itemBuilder: (context, i) {
                final m = milestones[i];
                final unlocked = m['unlocked'] as bool;
                final icon = m['icon'] as IconData;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      return Container(
                        width: 82,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        decoration: BoxDecoration(
                          color: unlocked
                              ? AppTheme.goldMid.withOpacity(0.1)
                              : AppTheme.bgSlateHigh,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: unlocked
                                ? AppTheme.goldMid.withOpacity(0.4 + _pulseController.value * 0.2)
                                : AppTheme.borderSoft,
                          ),
                          boxShadow: unlocked
                              ? [
                                  BoxShadow(
                                    color: AppTheme.goldMid.withOpacity(0.15 + _pulseController.value * 0.1),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _floatController,
                              builder: (_, __) {
                                final bounce = unlocked
                                    ? sin(_floatController.value * pi + i * 0.5) * 3
                                    : 0.0;
                                return Transform.translate(
                                  offset: Offset(0, bounce),
                                  child: Icon(
                                    icon,
                                    size: 28,
                                    color: unlocked
                                        ? AppTheme.goldMid
                                        : AppTheme.textTertiary,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              m['label'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: unlocked
                                    ? AppTheme.goldMid
                                    : AppTheme.textTertiary,
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

  // ═══════════════════════════════════════════════════════════
  // 3. INTERVENTION HISTORY
  // ═══════════════════════════════════════════════════════════
  Widget _buildInterventionHistoryCard() {
    return _ProfileBentoBox(
      accentColor: _stressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('INTERVENTION HISTORY'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statBox(
                  Icons.pause_circle_outline_rounded, 'Interruptions',
                  StatsService.sacredInterruptions, _calm)),
              const SizedBox(width: 12),
              Expanded(child: _statBox(
                  Icons.auto_stories_rounded, 'Delivered',
                  StatsService.versesReceived, _hopeful)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statBox(
                  Icons.insights_rounded, 'Patterns',
                  StatsService.habitsChecked, _anxious)),
              const SizedBox(width: 12),
              Expanded(child: _statBox(
                  Icons.favorite_rounded, 'Saved',
                  StatsService.savedVerses.length, _grateful)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String label, int count, Color accentColor) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgSlateHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderSoft),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _floatController,
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(0, sin(_floatController.value * pi) * 2),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.2 + _pulseController.value * 0.15),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: count.toDouble()),
                builder: (context, v, __) {
                  return Text(
                    v.round().toString(),
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 4. SACRED PRACTICES
  // ═══════════════════════════════════════════════════════════
  Widget _buildSacredPracticesCard() {
    return _ProfileBentoBox(
      accentColor: _grateful,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SACRED PRACTICES'),
          const SizedBox(height: 6),
          Text(
            'Commit to the rhythms that hold you.',
            style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          _practiceRow(Icons.wb_sunny_rounded, 'Morning Verse',
              _morningVerse, (v) => setState(() => _morningVerse = v)),
          _practiceRow(Icons.nights_stay_rounded, 'Evening Reflection',
              _eveningReflection, (v) => setState(() => _eveningReflection = v)),
          _practiceRow(Icons.calendar_today_rounded, 'Sunday Soul Review',
              _sundayReview, (v) => setState(() => _sundayReview = v)),
          _practiceRow(Icons.pause_circle_outline_rounded, 'Sacred Interruptions',
              _sacredInterruptions, (v) => setState(() => _sacredInterruptions = v)),
          _practiceRow(Icons.spa_rounded, 'Zen Mode Reminder',
              _zenReminder, (v) => setState(() => _zenReminder = v)),
        ],
      ),
    );
  }

  Widget _practiceRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.bgSlateHigh,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSoft),
            ),
            child: Icon(icon, size: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          _ProfileMiniToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 5. WEEKLY SOUL REPORT
  // ═══════════════════════════════════════════════════════════
  Widget _buildWeeklyReportCard() {
    final topEmotion = StatsService.getMostFrequentEmotion();
    final versesWeek = StatsService.versesReceived;
    final interruptsWeek = StatsService.sacredInterruptions;

    return _ProfileBentoBox(
      accentColor: _calm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _floatController,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, sin(_floatController.value * pi) * 2),
                  child: Icon(Icons.summarize_rounded,
                      color: AppTheme.goldMid, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              _sectionLabel('THIS WEEK'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You carried ${_capitalize(topEmotion)} most often.',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _reportStat('Verses', versesWeek, Icons.menu_book_rounded)),
              Container(width: 1, height: 40, color: AppTheme.borderSoft),
              Expanded(child: _reportStat('Pauses', interruptsWeek, Icons.pause_rounded)),
              Container(width: 1, height: 40, color: AppTheme.borderSoft),
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
        AnimatedBuilder(
          animation: _floatController,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, sin(_floatController.value * pi) * 1.5),
            child: Icon(icon, color: AppTheme.textSecondary, size: 16),
          ),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: value.toDouble()),
          builder: (context, v, __) => Text(
            v.round().toString(),
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 6. VERSES VAULT
  // ═══════════════════════════════════════════════════════════
  Widget _buildVersesVaultCard() {
    final saved = StatsService.savedVerses;

    return _ProfileBentoBox(
      accentColor: _hopeful,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('VERSES VAULT'),
              const Spacer(),
              Text(
                '${saved.length} collected',
                style: GoogleFonts.manrope(
                    fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: saved.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _floatController,
                          builder: (_, __) => Transform.translate(
                            offset: Offset(0, sin(_floatController.value * pi) * 4),
                            child: Icon(Icons.bookmark_border_rounded,
                                color: AppTheme.textTertiary, size: 32),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your saved verses will appear here.\nSwipe right on any verse to save.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 12, color: AppTheme.textTertiary, height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  )
                : PageView.builder(
                    controller: PageController(viewportFraction: 0.88),
                    itemCount: saved.length,
                    itemBuilder: (context, i) {
                      final v = saved[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSlateHigh,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.goldMid.withOpacity(0.25)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldMid.withOpacity(0.06),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '"${v['text']}"',
                                  style: GoogleFonts.literata(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    height: 1.6,
                                    color: AppTheme.textPrimary,
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
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.goldMid,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      StatsService.savedVerses.removeAt(i);
                                      setState(() {});
                                    },
                                    child: Icon(Icons.favorite_rounded,
                                        color: AppTheme.goldMid.withOpacity(0.7), size: 18),
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

  // ═══════════════════════════════════════════════════════════
  // 7. RHYTHMS NOTICED
  // ═══════════════════════════════════════════════════════════
  Widget _buildRhythmsNoticedCard() {
    final counts = <String, int>{};
    for (final e in StatsService.emotionHistory) {
      final emotion = e['emotion'] as String;
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    final topEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = topEntries.take(6).toList();

    return _ProfileBentoBox(
      accentColor: _angry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('RHYTHMS NOTICED'),
          const SizedBox(height: 6),
          Text(
            'The emotions blooming most in you.',
            style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: AnimatedBuilder(
                animation: _petalRotateController,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _ProfilePetalsPainter(
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
                      color: _emotionAccent(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _capitalize(e.key),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
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

  // ═══════════════════════════════════════════════════════════
  // 8. CALENDAR
  // ═══════════════════════════════════════════════════════════
  Widget _buildCalendarCard() {
    return _ProfileBentoBox(
      accentColor: _calm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _floatController,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, sin(_floatController.value * pi) * 2),
                  child: Icon(Icons.calendar_month_rounded, color: _calm, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              _sectionLabel('CALENDAR CONNECTION'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _calendarConnected
                ? 'Connected. Lumíne walks with your day.'
                : 'Connect Google Calendar to receive verses timed to your events.',
            style: GoogleFonts.manrope(
              fontSize: 13, color: AppTheme.textSecondary, height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() => _calendarConnected = !_calendarConnected),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: _calm.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _calm.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _calendarConnected ? Icons.check_circle_rounded : Icons.link_rounded,
                    color: _calm, size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _calendarConnected ? 'Connected' : 'Connect',
                    style: GoogleFonts.manrope(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _calm,
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

  // ═══════════════════════════════════════════════════════════
  // 9. SETTINGS
  // ═══════════════════════════════════════════════════════════
  Widget _buildSettingsCard() {
    return _ProfileBentoBox(
      accentColor: _anxious,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _floatController,
                builder: (_, __) => Transform.rotate(
                  angle: sin(_floatController.value * pi) * 0.3,
                  child: Icon(Icons.settings_rounded,
                      color: AppTheme.textSecondary, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              _sectionLabel('LUMÍNE SETTINGS'),
            ],
          ),
          const SizedBox(height: 18),
          _segmentRow('Tone', ['warm', 'direct', 'gentle'], _preferredTone,
              (v) => setState(() => _preferredTone = v)),
          const SizedBox(height: 14),
          _segmentRow('Translation', ['KJV', 'NIV', 'ESV', 'MSG'], _translation,
              (v) => setState(() => _translation = v)),
          const SizedBox(height: 14),
          _segmentRow('Response length', ['short', 'medium', 'long'], _responseLength,
              (v) => setState(() => _responseLength = v)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgSlateHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderSoft),
                ),
                child: Icon(Icons.volume_up_rounded, color: AppTheme.textSecondary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Voice output',
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              ),
              _ProfileMiniToggle(
                value: _voiceEnabled,
                onChanged: (v) => setState(() => _voiceEnabled = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgSlateHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderSoft),
                ),
                child: Icon(Icons.nights_stay_rounded, color: AppTheme.textSecondary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Quiet hours',
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              ),
              _timePill(_quietStart, (t) => setState(() => _quietStart = t)),
              Text(' → ', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textTertiary)),
              _timePill(_quietEnd, (t) => setState(() => _quietEnd = t)),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: AppTheme.borderSoft),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _showResetConfirmation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE85D5D).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE85D5D).withOpacity(0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded, color: Color(0xFFE85D5D), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Begin Again',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE85D5D),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This will clear all your data and start fresh.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 11, color: AppTheme.textTertiary, fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => Dialog(
        backgroundColor: AppTheme.bgSlate,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.bgSlateGlow),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.spa_rounded, color: AppTheme.goldMid, size: 40),
              const SizedBox(height: 16),
              Text(
                'Begin Again?',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will clear all your conversations, saved verses, emotion history, soul map, and memory.\n\nLumíne will meet you as if for the first time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSlateHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.bgSlateGlow),
                        ),
                        child: Center(
                          child: Text('Stay',
                              style: GoogleFonts.manrope(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await _performReset();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE85D5D).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE85D5D).withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text('Begin Again',
                              style: GoogleFonts.manrope(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFE85D5D))),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performReset() async {
    await MemoryService.clearChatHistory();
    await MemoryService.saveMemoryProfile({
      'themes': [],
      'recurring_struggles': [],
      'milestones': [],
      'preferred_tone': 'warm',
      'spiritual_focus_areas': [],
      'last_summarized_at': null,
      'message_count_at_last_summary': 0,
    });

    StatsService.sacredInterruptions = 0;
    StatsService.versesReceived = 0;
    StatsService.habitsChecked = 0;
    StatsService.streakDays = 0;
    StatsService.savedVerses.clear();
    StatsService.emotionHistory.clear();
    StatsService.verseHistory.clear();
    StatsService.stressSpikes.clear();
    StatsService.recoveryTimesMinutes.clear();
    StatsService.todayJournal = '';
    StatsService.glooFingerprint = '';

    AppController().setEmotion('calm');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lumíne has been reset. Welcome back.',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.white)),
        backgroundColor: const Color(0xFFE85D5D),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    setState(() {});
  }

  Widget _segmentRow(String label, List<String> options, String current,
      ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.manrope(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
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
                  color: selected
                      ? AppTheme.goldMid.withOpacity(0.15)
                      : AppTheme.bgSlateHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppTheme.goldMid.withOpacity(0.5)
                        : AppTheme.borderSoft,
                  ),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.goldMid : AppTheme.textSecondary,
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
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgSlateHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSoft),
        ),
        child: Text(
          time.format(context),
          style: GoogleFonts.manrope(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 10. EXPORT
  // ═══════════════════════════════════════════════════════════
  Widget _buildExportCard() {
    return _ProfileBentoBox(
      accentColor: AppTheme.goldMid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _floatController,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, sin(_floatController.value * pi) * 2),
                  child: Icon(Icons.share_rounded, color: AppTheme.goldMid, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              _sectionLabel('EXPORT SOUL MAP'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Save a beautiful image of your soul map — share it, keep it, remember it.',
            style: GoogleFonts.manrope(
              fontSize: 13, color: AppTheme.textSecondary, height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Soul map saved to gallery.',
                      style: GoogleFonts.manrope(color: Colors.white)),
                  backgroundColor: AppTheme.bgSlateHigh,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.goldMid.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.goldMid.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_rounded, color: AppTheme.goldMid, size: 16),
                  const SizedBox(width: 6),
                  Text('Save as Image',
                      style: GoogleFonts.manrope(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.goldMid)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 11. ABOUT
  // ═══════════════════════════════════════════════════════════
  Widget _buildAboutCard() {
    return _ProfileBentoBox(
      accentColor: AppTheme.textTertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + sin(_pulseController.value * pi) * 0.15,
                  child: Icon(Icons.auto_awesome, color: AppTheme.goldMid, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              _sectionLabel('ABOUT LUMÍNE'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Lumíne is an ambient spiritual companion — Scripture that reads you. It listens deeply, notices your patterns, and delivers the right word at the right moment.',
            style: GoogleFonts.literata(
              fontSize: 14, fontStyle: FontStyle.italic, height: 1.7, color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Powered by',
              style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textTertiary, letterSpacing: 1)),
          const SizedBox(height: 6),
          Row(
            children: [
              _creditChip('YouVersion Platform'),
              const SizedBox(width: 6),
              _creditChip('Gloo AI'),
            ],
          ),
          const SizedBox(height: 14),
          Text('Your soul data stays on your device.',
              style: GoogleFonts.manrope(
                  fontSize: 11, color: AppTheme.textTertiary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('v1.0',
                  style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textTertiary)),
              const Spacer(),
              Text('made with ',
                  style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textTertiary)),
              const Icon(Icons.favorite_rounded, color: Color(0xFFE85D75), size: 12),
              Text(' by Naren',
                  style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textTertiary)),
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
        color: AppTheme.bgSlateHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSoft),
      ),
      child: Text(label,
          style: GoogleFonts.manrope(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: AppTheme.textTertiary,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ORIGINAL AVATAR FACE PAINTER — warm cream, closed eyes, blush, smile
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
// FLOURISH LINE PAINTER
// ══════════════════════════════════════════════════════════════════
class _ProfileFlourishLinePainter extends CustomPainter {
  final double t;
  _ProfileFlourishLinePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF1D98A).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(10, size.height * 0.5);
    for (double x = 10; x < size.width - 10; x += 4) {
      final progress = x / size.width;
      final wave = sin(progress * pi * 3) * 4 + sin(progress * pi * 7) * 2;
      path.lineTo(x, size.height * 0.5 + wave);
    }
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width - 8, size.height * 0.5),
      2,
      Paint()..color = const Color(0xFFF1D98A).withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _ProfileFlourishLinePainter old) => false;
}

// ══════════════════════════════════════════════════════════════════
// PETALS PAINTER
// ══════════════════════════════════════════════════════════════════
class _ProfilePetalsPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final double t;

  _ProfilePetalsPainter({required this.entries, required this.t});

  Color _emotionColor(String e) {
    switch (e) {
      case 'calm': return const Color(0xFF7BA9F0);
      case 'happy': return const Color(0xFFFFD470);
      case 'sad': return const Color(0xFFB8A0E8);
      case 'angry': return const Color(0xFFFF7C6B);
      case 'hopeful': return const Color(0xFF6BC5D9);
      case 'anxious': return const Color(0xFFC688F0);
      case 'grateful': return const Color(0xFF7DD69F);
      case 'stressed': return const Color(0xFFFFA560);
      case 'optimistic': return const Color(0xFFFFDF80);
      case 'depressed': return const Color(0xFF8FA0B8);
      default: return const Color(0xFF8C8579);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    if (entries.isEmpty) {
      canvas.drawCircle(center, 6, Paint()..color = const Color(0xFF5A554D));
      return;
    }

    final maxCount = entries.first.value;
    final count = entries.length;

    for (int i = 0; i < count; i++) {
      final e = entries[i];
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

      canvas.drawPath(petalPath, Paint()..color = _emotionColor(e.key).withOpacity(0.7));
      canvas.drawPath(
        petalPath,
        Paint()
          ..color = _emotionColor(e.key).withOpacity(0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );

      canvas.restore();
    }

    canvas.drawCircle(center, 14, Paint()..color = const Color(0xFF1A1D21));
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFFF1D98A).withOpacity(0.8));
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFFFF8E5));
  }

  @override
  bool shouldRepaint(covariant _ProfilePetalsPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════
// PROFILE BENTO BOX
// ══════════════════════════════════════════════════════════════════
class _ProfileBentoBox extends StatelessWidget {
  final Widget child;
  final Color accentColor;

  const _ProfileBentoBox({required this.child, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgSlate,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.bgSlateGlow.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0.03), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24, bottom: 24, left: 0,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
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
// MINI TOGGLE
// ══════════════════════════════════════════════════════════════════
class _ProfileMiniToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ProfileMiniToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 42, height: 24,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppTheme.goldMid.withOpacity(0.25) : AppTheme.bgSlateHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? AppTheme.goldMid.withOpacity(0.5) : AppTheme.borderSoft,
          ),
        ),
        child: AnimatedAlign(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: value ? AppTheme.goldMid : AppTheme.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}