import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/app_controller.dart';
import '../services/stats_service.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../services/tts_service.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'habits_screen.dart';
import 'scripture_feed_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _breathController;
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late AnimationController _bookmarkController;
  late AnimationController _weatherController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  late AnimationController _lightningController;
  late AnimationController _timeController;

  // Soul Map controllers
  late AnimationController _profileTapController;
  late AnimationController _refreshSpinController;
  late AnimationController _blobController;
  late AnimationController _fingerprintRevealController;
  late AnimationController _journalRevealController;
  late AnimationController _bentoSlideController;
  late AnimationController _patternIconController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  late Animation<double> _breathAnimation;
  late Animation<double> _glowAnimation;

  final ScrollController _stateScrollController = ScrollController();
  double _scrollOffset = 0;

  int _heartRate = 72;
  double _stressScore = 0.18;
  Timer? _bioTimer;
  Timer? _scriptureTimer;
  Timer? _clockTimer;
  Timer? _lightningTimer;
  int _scriptureIndex = 0;
  final Random _random = Random();

  bool _anchorSaved = false;

  bool _fingerprintVisible = false;
  bool _journalVisible = false;
  bool _profileTapping = false;
  bool _refreshSpinning = false;

    // ─── 5 unique bento colors — bold, not dark ───
  static const Color _colorFingerprint = Color(0xFFC026D3); // bright fuchsia
  static const Color _colorAnchor      = Color(0xFF7C3AED); // bright amethyst
  static const Color _colorPatterns    = Color(0xFF16A34A); // bright kelly green
  static const Color _colorLumineSees  = Color(0xFFDC2626); // bright vermillion
  static const Color _colorJournal     = Color(0xFFEA580C); // bright tangerine
  final Map<String, List<Map<String, String>>> _microVerses = {
    "calm": [
      {"text": "Be still, and know that I am God.", "ref": "Psalm 46:10"},
      {"text": "In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety.", "ref": "Psalm 4:8"},
      {"text": "The Lord is my shepherd, I lack nothing.", "ref": "Psalm 23:1"},
    ],
    "happy": [
      {"text": "This is the day the Lord has made; let us rejoice and be glad in it.", "ref": "Psalm 118:24"},
      {"text": "The joy of the Lord is your strength.", "ref": "Nehemiah 8:10"},
      {"text": "Shout for joy to the Lord, all the earth.", "ref": "Psalm 100:1"},
    ],
    "sad": [
      {"text": "The Lord is close to the brokenhearted.", "ref": "Psalm 34:18"},
      {"text": "He heals the brokenhearted and binds up their wounds.", "ref": "Psalm 147:3"},
      {"text": "Weeping may stay for the night, but rejoicing comes in the morning.", "ref": "Psalm 30:5"},
    ],
    "angry": [
      {"text": "A gentle answer turns away wrath.", "ref": "Proverbs 15:1"},
      {"text": "In your anger do not sin.", "ref": "Ephesians 4:26"},
      {"text": "Everyone should be quick to listen, slow to speak and slow to become angry.", "ref": "James 1:19"},
    ],
    "hopeful": [
      {"text": "For I know the plans I have for you, declares the Lord.", "ref": "Jeremiah 29:11"},
      {"text": "But those who hope in the Lord will renew their strength.", "ref": "Isaiah 40:31"},
      {"text": "May the God of hope fill you with all joy and peace.", "ref": "Romans 15:13"},
    ],
    "anxious": [
      {"text": "Cast all your anxiety on him because he cares for you.", "ref": "1 Peter 5:7"},
      {"text": "Do not be anxious about anything.", "ref": "Philippians 4:6"},
      {"text": "When anxiety was great within me, your consolation brought me joy.", "ref": "Psalm 94:19"},
    ],
    "grateful": [
      {"text": "Give thanks to the Lord, for he is good.", "ref": "Psalm 136:1"},
      {"text": "Every good and perfect gift is from above.", "ref": "James 1:17"},
      {"text": "Give thanks in all circumstances.", "ref": "1 Thessalonians 5:18"},
    ],
    "stressed": [
      {"text": "Come to me, all you who are weary and burdened, and I will give you rest.", "ref": "Matthew 11:28"},
      {"text": "He gives strength to the weary.", "ref": "Isaiah 40:29"},
      {"text": "My grace is sufficient for you.", "ref": "2 Corinthians 12:9"},
    ],
    "optimistic": [
      {"text": "The Lord will fight for you; you need only to be still.", "ref": "Exodus 14:14"},
      {"text": "Commit to the Lord whatever you do.", "ref": "Proverbs 16:3"},
      {"text": "I can do all this through him who gives me strength.", "ref": "Philippians 4:13"},
    ],
    "depressed": [
      {"text": "He lifted me out of the pit of despair.", "ref": "Psalm 40:2"},
      {"text": "The Lord is close to the brokenhearted and saves those who are crushed in spirit.", "ref": "Psalm 34:18"},
      {"text": "I have told you these things, so that in me you may have peace.", "ref": "John 16:33"},
    ],
  };

  // Deeper words
  String _deepWord(String emotion) {
    switch (emotion) {
      case "calm": return "Stillness";
      case "happy": return "Radiance";
      case "sad": return "Tenderness";
      case "angry": return "Fire";
      case "hopeful": return "Rising";
      case "anxious": return "Restlessness";
      case "grateful": return "Openness";
      case "stressed": return "Weight";
      case "optimistic": return "Anticipation";
      case "depressed": return "Heaviness";
      default: return "Presence";
    }
  }

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _breathController, curve: Curves.easeInOut));
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bookmarkController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _weatherController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.9).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _lightningController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _timeController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _profileTapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _refreshSpinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _blobController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _fingerprintRevealController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _journalRevealController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _bentoSlideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _patternIconController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _stateScrollController.addListener(() {
      setState(() => _scrollOffset = _stateScrollController.offset);
    });

    _startBioSimulation();
    _startScriptureRotation();
    _startClock();
    _startLightningTimer();
  }

  void _startBioSimulation() {
    _bioTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _heartRate += _random.nextInt(5) - 2;
        _heartRate = _heartRate.clamp(58, 130);
        _stressScore = ((_heartRate - 60) / 70).clamp(0.0, 1.0);
      });
    });
  }

  void _startScriptureRotation() {
    _scriptureTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _scriptureIndex++;
        _anchorSaved = false;
      });
    });
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _startLightningTimer() {
    _lightningTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final forecast = _getForecast();
      final icon = forecast["icon"] as IconData;
      if (icon == Icons.thunderstorm_rounded) {
        _lightningController.forward().then((_) => _lightningController.reverse());
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _rotationController.dispose();
    _floatController.dispose();
    _bookmarkController.dispose();
    _weatherController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    _lightningController.dispose();
    _timeController.dispose();
    _profileTapController.dispose();
    _refreshSpinController.dispose();
    _blobController.dispose();
    _fingerprintRevealController.dispose();
    _journalRevealController.dispose();
    _bentoSlideController.dispose();
    _patternIconController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _stateScrollController.dispose();
    _bioTimer?.cancel();
    _scriptureTimer?.cancel();
    _clockTimer?.cancel();
    _lightningTimer?.cancel();
    super.dispose();
  }

  String _getState() {
    final c = AppController();
    String chatEmotion = c.currentEmotion;
    if (["happy","sad","angry","grateful","hopeful","anxious","stressed","optimistic","depressed"].contains(chatEmotion)) {
      return chatEmotion;
    }
    if (_stressScore > 0.75) return "anxious";
    if (_stressScore > 0.55) return "stressed";
    if (_heartRate < 62 && _stressScore < 0.15) return "depressed";
    if (_stressScore < 0.2) return "calm";
    return "calm";
  }

  double _getEmotionIntensity(String emotion) {
    switch (emotion) {
      case "happy": return 0.85;
      case "grateful": return 0.75;
      case "hopeful": return 0.70;
      case "optimistic": return 0.80;
      case "calm": return 0.50;
      case "sad": return 0.30;
      case "depressed": return 0.15;
      case "anxious": return 0.90;
      case "stressed": return 0.80;
      case "angry": return 0.95;
      default: return 0.50;
    }
  }

  String _getMessage() {
    switch (_getState()) {
      case "happy": return "There is a brightness in you right now, and it has God's fingerprints all over it.";
      case "sad": return "I'm here. I'm not leaving. The one who counts every tear you've shed is holding you gently right now.";
      case "calm": return "I can feel peace resting on you right now. Stay here a little longer.";
      case "angry": return "I can feel the fire in you. Stay with me before you answer.";
      case "hopeful": return "Something in you is reaching toward the light again. Hold onto that.";
      case "anxious": return "I can feel how tightly this is pressing on you. Give me this moment.";
      case "grateful": return "Your heart is open right now, and that is holy in its own way.";
      case "stressed": return "Your body is asking for rest. Even the Creator rested on the seventh day.";
      case "optimistic": return "I can feel expectation rising in you. Keep walking in it.";
      case "depressed": return "I know everything feels heavy right now. Stay with me here.";
      default: return "I'm here with you. Whatever this moment holds, you don't hold it alone.";
    }
  }

  List<String> _getIndicators() {
    switch (_getState()) {
      case "happy": return ["Share", "Shine", "Receive"];
      case "sad": return ["Stay", "Be Held", "Exhale"];
      case "calm": return ["Stay", "Receive", "Breathe"];
      case "angry": return ["Soften", "Wait", "Breathe"];
      case "hopeful": return ["Hold On", "Trust", "Keep Going"];
      case "anxious": return ["Slow Down", "Trust", "Exhale"];
      case "grateful": return ["Notice", "Receive", "Give Thanks"];
      case "stressed": return ["Pause", "Rest", "Release"];
      case "optimistic": return ["Keep Going", "Trust", "Look Up"];
      case "depressed": return ["Stay", "Rest", "Be Carried"];
      default: return ["Breathe", "Stay", "Trust"];
    }
  }

  List<Color> _getOrbColors() {
    switch (_getState()) {
      case "calm": return [const Color(0xFF6366F1), const Color(0xFFA855F7)];
      case "happy": return [const Color(0xFFFDE047), const Color(0xFFF59E0B)];
      case "sad": return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      case "angry": return [const Color(0xFFEF4444), const Color(0xFFF97316)];
      case "hopeful": return [const Color(0xFF3B82F6), const Color(0xFF06B6D4)];
      case "anxious": return [const Color(0xFF8B5CF6), const Color(0xFFEC4899)];
      case "grateful": return [const Color(0xFFFDE047), const Color(0xFF10B981)];
      case "stressed": return [const Color(0xFFF59E0B), const Color(0xFFEC4899)];
      case "optimistic": return [const Color(0xFFFDE047), const Color(0xFF3B82F6)];
      case "depressed": return [const Color(0xFF64748B), const Color(0xFF475569)];
      default: return [const Color(0xFF6366F1), const Color(0xFFA855F7)];
    }
  }

  Color _getMoodGlowColor() {
    switch (_getState()) {
      case "calm": return const Color(0xFF06B6D4);
      case "happy": return const Color(0xFFFACC15);
      case "sad": return const Color(0xFF8B5CF6);
      case "angry": return const Color(0xFFEF4444);
      case "hopeful": return const Color(0xFF3B82F6);
      case "anxious": return const Color(0xFFEC4899);
      case "grateful": return const Color(0xFF10B981);
      case "stressed": return const Color(0xFFF59E0B);
      case "optimistic": return const Color(0xFFFDE047);
      case "depressed": return const Color(0xFF64748B);
      default: return const Color(0xFF06B6D4);
    }
  }

  Map<String, String> _getCurrentScripture() {
    final state = _getState();
    final verses = _microVerses[state] ?? _microVerses["calm"]!;
    return verses[_scriptureIndex % verses.length];
  }

  Map<String, dynamic> _getGreeting() {
    final hour = DateTime.now().hour;
    final state = _getState();
    String timeGreeting;
    IconData timeIcon;
    Color iconColor;

    if (hour >= 5 && hour < 12) {
      timeGreeting = "Good morning.";
      timeIcon = Icons.wb_sunny_rounded;
      iconColor = const Color(0xFFF59E0B);
    } else if (hour >= 12 && hour < 17) {
      timeGreeting = "Good afternoon.";
      timeIcon = Icons.wb_sunny_outlined;
      iconColor = const Color(0xFFEA580C);
    } else if (hour >= 17 && hour < 21) {
      timeGreeting = "Good evening.";
      timeIcon = Icons.wb_twilight_rounded;
      iconColor = const Color(0xFFDC2626);
    } else {
      timeGreeting = "Peaceful night.";
      timeIcon = Icons.nights_stay_rounded;
      iconColor = const Color(0xFF6366F1);
    }

    String stateMessage;
    switch (state) {
      case "happy": stateMessage = "Your soul feels bright."; break;
      case "sad": stateMessage = "Your soul feels tender."; break;
      case "calm": stateMessage = "Your soul feels calm."; break;
      case "angry": stateMessage = "Your soul feels heated."; break;
      case "hopeful": stateMessage = "Your soul feels hopeful."; break;
      case "anxious": stateMessage = "Your soul feels unsettled."; break;
      case "grateful": stateMessage = "Your soul feels open."; break;
      case "stressed": stateMessage = "Your soul feels weighed down."; break;
      case "optimistic": stateMessage = "Your soul feels forward-leaning."; break;
      case "depressed": stateMessage = "Your soul feels heavy."; break;
      default: stateMessage = "Your soul is with you.";
    }

    return {"greeting": timeGreeting, "message": stateMessage, "icon": timeIcon, "color": iconColor};
  }

  Map<String, dynamic> _getForecast() {
    final state = _getState();
    final pattern = StatsService.getTimeOfDayPattern();
    final spikes = StatsService.getStressSpikesToday();
    String forecast;
    IconData forecastIcon;
    Color forecastColor;

    if (spikes > 3) {
      forecast = "Storm building — take breath breaks throughout the day.";
      forecastIcon = Icons.thunderstorm_rounded;
      forecastColor = const Color(0xFF7C3AED);
    } else if (state == "anxious" || state == "stressed") {
      forecast = "Turbulence detected — Zen mode may help clear the skies.";
      forecastIcon = Icons.cloud_rounded;
      forecastColor = const Color(0xFF6B7280);
    } else if (state == "sad" || state == "depressed") {
      forecast = "Grey skies today — small acts of care matter most now.";
      forecastIcon = Icons.grain_rounded;
      forecastColor = const Color(0xFF64748B);
    } else if (state == "happy" || state == "grateful") {
      forecast = "Clear skies — let this light spread to others.";
      forecastIcon = Icons.wb_sunny_rounded;
      forecastColor = const Color(0xFFF59E0B);
    } else if (state == "hopeful" || state == "optimistic") {
      forecast = "Rising warmth ahead — stay open to what unfolds.";
      forecastIcon = Icons.wb_twilight_rounded;
      forecastColor = const Color(0xFFEA580C);
    } else if (pattern["Evening"] == "stressed" || pattern["Evening"] == "anxious") {
      forecast = "Calm now but watch for stress in the evening.";
      forecastIcon = Icons.wb_cloudy_rounded;
      forecastColor = const Color(0xFF3B82F6);
    } else {
      forecast = "Steady patterns today — your rhythm is holding.";
      forecastIcon = Icons.wb_sunny_outlined;
      forecastColor = const Color(0xFF10B981);
    }

    return {"text": forecast, "icon": forecastIcon, "color": forecastColor};
  }

  String _formatTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  void _expandCard(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.black54)),
                ],
              ),
            ),
            Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 40), child: content)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // STATE TAB — unchanged
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildOrbCard() {
    final orbColors = _getOrbColors();
    final message = _getMessage();
    final state = _getState();
    final indicators = _getIndicators();
    final moodGlow = _getMoodGlowColor();

    return BouncyGlassCard(
      onTap: () => _expandCard("Current State", Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.7, color: Colors.black87))),
      glowColor: moodGlow,
      glowAnimation: _glowAnimation,
      child: Column(
        children: [
          _buildOrb(orbColors),
          const SizedBox(height: 20),
          Text("CURRENT STATE", style: GoogleFonts.plusJakartaSans(letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38)),
          const SizedBox(height: 4),
          Text(state.toUpperCase(), style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.7, color: Colors.black.withOpacity(0.6), fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(indicators.length * 2 - 1, (i) {
              if (i.isEven) {
                return Text(indicators[i ~/ 2], style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1));
              } else {
                return Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("·", style: TextStyle(color: Colors.black.withOpacity(0.25), fontSize: 14)));
              }
            }),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildAnchorCard() {
    final scripture = _getCurrentScripture();
    return BouncyGlassCard(
      onTap: () => _expandCard(
        "Today's Anchor",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${scripture["text"]}"', style: GoogleFonts.playfairDisplay(fontSize: 20, fontStyle: FontStyle.italic, height: 1.6, color: const Color(0xFF422006))),
            const SizedBox(height: 12),
            Text("— ${scripture["ref"]}", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF92400E), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                setState(() => _anchorSaved = !_anchorSaved);
                if (_anchorSaved) {
                  StatsService.saveVerse(scripture["text"] ?? "", scripture["ref"] ?? "");
                  StatsService.recordVerse(scripture["text"] ?? "", scripture["ref"] ?? "");
                }
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_anchorSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(_anchorSaved ? "Saved" : "Save Verse", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      glowColor: const Color(0xFFF59E0B),
      glowAnimation: _glowAnimation,
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _bookmarkController,
            builder: (context, child) {
              return Transform.rotate(
                angle: sin(_bookmarkController.value * pi) * 0.08,
                child: Transform.translate(
                  offset: Offset(0, sin(_bookmarkController.value * pi) * 3),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(_anchorSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded, color: const Color(0xFFF59E0B), size: 24),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: Column(
                key: ValueKey<int>(_scriptureIndex),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TODAY'S ANCHOR", style: GoogleFonts.plusJakartaSans(letterSpacing: 1, fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
                  const SizedBox(height: 8),
                  Text('"${scripture["text"]}"', style: GoogleFonts.playfairDisplay(fontSize: 15, fontStyle: FontStyle.italic, height: 1.5, color: const Color(0xFF422006))),
                  const SizedBox(height: 6),
                  Text("— ${scripture["ref"]}", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideX(begin: 0.15, curve: Curves.easeOut);
  }

  Widget _buildAnimatedWeatherIcon(IconData icon, Color color) {
    if (icon == Icons.nights_stay_rounded) {
      return AnimatedBuilder(
        animation: _weatherController,
        builder: (context, child) {
          final twinkle = 0.7 + (sin(_weatherController.value * 2 * pi) * 0.3);
          return Icon(icon, color: color.withOpacity(twinkle), size: 30);
        },
      );
    }
    if (icon == Icons.thunderstorm_rounded) {
      return AnimatedBuilder(
        animation: _lightningController,
        builder: (context, child) {
          final flash = _lightningController.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              if (flash > 0)
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.yellowAccent.withOpacity(flash * 0.6),
                    boxShadow: [BoxShadow(color: Colors.yellowAccent.withOpacity(flash * 0.8), blurRadius: 20, spreadRadius: 5)],
                  ),
                ),
            ],
          );
        },
      );
    }
    if (icon == Icons.wb_sunny_rounded || icon == Icons.wb_sunny_outlined) {
      return AnimatedBuilder(
        animation: _weatherController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _weatherController.value * 2 * pi * 0.1,
            child: Icon(icon, color: color, size: 30),
          );
        },
      );
    }
    return AnimatedBuilder(
      animation: _weatherController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(sin(_weatherController.value * 2 * pi) * 2, cos(_weatherController.value * 2 * pi) * 2),
          child: Icon(icon, color: color, size: 30),
        );
      },
    );
  }

  Widget _buildGreetingForecastCard() {
    final greeting = _getGreeting();
    final forecast = _getForecast();

    return BouncyGlassCard(
      onTap: () => _expandCard(
        "Today's Forecast",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting["greeting"] as String, style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF14532D))),
            const SizedBox(height: 8),
            Text(greeting["message"] as String, style: GoogleFonts.plusJakartaSans(fontSize: 16, color: const Color(0xFF166534))),
            const SizedBox(height: 20),
            Text(forecast["text"] as String, style: GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.6, color: const Color(0xFF166534))),
          ],
        ),
      ),
      glowColor: forecast["color"] as Color,
      glowAnimation: _glowAnimation,
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [(greeting["color"] as Color).withOpacity(0.2), (forecast["color"] as Color).withOpacity(0.2)],
              ),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildAnimatedWeatherIcon(greeting["icon"] as IconData, (greeting["color"] as Color).withOpacity(0.85)),
                Positioned(
                  bottom: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(forecast["icon"] as IconData, color: forecast["color"] as Color, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting["greeting"] as String, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF14532D))),
                const SizedBox(height: 4),
                Text("${greeting["message"]} ${forecast["text"]}", style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: const Color(0xFF166534))),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.15, curve: Curves.easeOut);
  }

  Widget _buildEmotionWaveCard() {
    final history = StatsService.emotionHistory;
    final recent = history.length > 12 ? history.sublist(history.length - 12) : history;
    final intensityValues = recent.map((e) => _getEmotionIntensity(e["emotion"] as String)).toList();

    return BouncyGlassCard(
      onTap: () => _expandCard(
        "Emotional Journey",
        recent.isEmpty
            ? Text("Your journey will appear as you interact with Lumíne.", style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.black54))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: recent.reversed.map((e) {
                  final hour = e["hour"] as int;
                  final period = hour >= 12 ? "PM" : "AM";
                  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Text("$displayHour:00 $period", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54)),
                        const SizedBox(width: 12),
                        Text((e["emotion"] as String).toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF6B21A8))),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      glowColor: const Color(0xFF8B5CF6),
      glowAnimation: _glowAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, sin(_floatController.value * pi) * 3),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.show_chart_rounded, color: Color(0xFF7C3AED), size: 22),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("EMOTIONAL WAVE", style: GoogleFonts.plusJakartaSans(letterSpacing: 1, fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6B21A8))),
                  const SizedBox(height: 2),
                  Text("Your day in motion", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B21A8).withOpacity(0.7))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 80,
            child: intensityValues.isEmpty
                ? Center(child: Text("Your wave will begin as you interact.", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B21A8).withOpacity(0.6), fontStyle: FontStyle.italic)))
                : AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(double.infinity, 80),
                        painter: EmotionWavePainter(intensities: intensityValues, animation: _waveController.value),
                      );
                    },
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(begin: 0.15, curve: Curves.easeOut);
  }

  Widget _buildStateScreen() {
    final headerCollapsed = _scrollOffset > 40;
    return Stack(
      children: [
        AuroraMeshBackground(baseColor: ThemeService.getEmotionColor(), floatController: _floatController, moodGlow: _getMoodGlowColor()),
        SafeArea(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: headerCollapsed ? 12 : 20),
                child: _buildStateHeader(collapsed: headerCollapsed),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _stateScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildOrbCard(),
                      const SizedBox(height: 20),
                      _buildAnchorCard(),
                      const SizedBox(height: 20),
                      _buildGreetingForecastCard(),
                      const SizedBox(height: 20),
                      _buildEmotionWaveCard(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStateHeader({required bool collapsed}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's State", style: GoogleFonts.playfairDisplay(fontSize: collapsed ? 22 : 34, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                if (!collapsed)
                  Text("Lumíne is with you", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A).withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _timeController,
          builder: (context, child) {
            final pulse = 1.0 + (sin(_timeController.value * pi) * 0.05);
            return Transform.scale(
              scale: pulse,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.3)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.6), blurRadius: 6)]),
                    ),
                    const SizedBox(width: 6),
                    Text(_formatTime(), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrb(List<Color> colors) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathAnimation, _rotationController, _floatController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, sin(_floatController.value * pi) * 6),
          child: Transform.scale(
            scale: _breathAnimation.value,
            child: Transform.rotate(
              angle: _rotationController.value * 2 * pi,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [colors[0], colors[1], colors[0]]),
                  boxShadow: [
                    BoxShadow(color: colors[0].withOpacity(0.4), blurRadius: 50, spreadRadius: 12),
                    BoxShadow(color: colors[1].withOpacity(0.3), blurRadius: 25, spreadRadius: 6),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [Colors.white.withOpacity(0.85), colors[0].withOpacity(0.3)]),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // ════════════════════════════════════════════════════════════════════════
  // SOUL MAP SCREEN
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSoulMapScreen() {
    final topEmotion = StatsService.getMostFrequentEmotion();
    final anchorVerse = StatsService.getAnchorVerse();
    final anchorText = StatsService.getAnchorVerseText();
    final anchorCount = StatsService.getAnchorVerseCount();
    final recovery = StatsService.getAverageRecoveryMinutes();
    final todaySpikes = StatsService.getStressSpikesToday();
    final pattern = StatsService.getTimeOfDayPattern();
    final hasData = StatsService.emotionHistory.isNotEmpty;
    final interactionCount = StatsService.emotionHistory.length;

    return Stack(
      children: [
        _buildSoulMapBackground(),

        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildSoulMapHeader(),
                const SizedBox(height: 32),

                _buildFingerprintCard(hasData, interactionCount, topEmotion, anchorVerse, anchorCount, recovery, todaySpikes, pattern)
                    .animate(controller: _bentoSlideController)
                    .fadeIn(delay: 0.ms, duration: 500.ms)
                    .slideX(begin: -0.15, curve: Curves.easeOut),
                const SizedBox(height: 16),

                if (anchorVerse.isNotEmpty)
                  _buildSoulAnchorCard(anchorVerse, anchorText, anchorCount)
                      .animate(controller: _bentoSlideController)
                      .fadeIn(delay: 150.ms, duration: 600.ms)
                      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut),
                if (anchorVerse.isNotEmpty) const SizedBox(height: 16),

                _buildEmotionalPatternsCard(pattern)
                    .animate(controller: _bentoSlideController)
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideX(begin: 0.15, curve: Curves.easeOut),
                const SizedBox(height: 16),

                if (todaySpikes > 0 || recovery > 0)
                  _buildLumineSees(todaySpikes, recovery)
                      .animate(controller: _bentoSlideController)
                      .fadeIn(delay: 450.ms, duration: 500.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),
                if (todaySpikes > 0 || recovery > 0) const SizedBox(height: 16),

                _buildJournalCard(topEmotion, anchorVerse, anchorCount, recovery, todaySpikes, pattern)
                    .animate(controller: _bentoSlideController)
                    .fadeIn(delay: 600.ms, duration: 500.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Blob wave background ────────────────────────────────────────────────
  Widget _buildSoulMapBackground() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1200),
      color: const Color(0xFFFAF6EF),
      child: AnimatedBuilder(
        animation: _blobController,
        builder: (_, __) {
          return CustomPaint(
            size: Size.infinite,
            painter: _BlobWavePainter(
              animation: _blobController.value,
              blobColor: ThemeService.getEmotionColor(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSoulMapHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Soul Map",
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "A living record of your inner world",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black.withOpacity(0.55),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            setState(() => _profileTapping = true);
            _profileTapController.forward(from: 0);
            await Future.delayed(const Duration(milliseconds: 600));
            if (!mounted) return;
            setState(() => _profileTapping = false);
            Navigator.push(context, PageRouteBuilder(
              pageBuilder: (_, a, __) => const ProfileScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                    child: child,
                  ),
                );
              },
            ));
          },
          child: AnimatedBuilder(
            animation: _profileTapController,
            builder: (_, __) {
              final scale = _profileTapping
                  ? (1.0 + sin(_profileTapController.value * pi) * 0.3)
                  : 1.0;
              final glow = _profileTapController.value;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15 + glow * 0.3),
                        blurRadius: 12 + glow * 20,
                        spreadRadius: glow * 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_profileTapping)
                        AnimatedBuilder(
                          animation: _profileTapController,
                          builder: (_, __) {
                            return Container(
                              width: 48 + _profileTapController.value * 24,
                              height: 48 + _profileTapController.value * 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black.withOpacity((1 - _profileTapController.value) * 0.5),
                                  width: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                      const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Fingerprint Card — DEEP MIDNIGHT #1A1A2E, dot grid pattern ──────────
  Widget _buildFingerprintCard(bool hasData, int interactionCount, String topEmotion, String anchorVerse, int anchorCount, int recovery, int todaySpikes, Map<String, String> pattern) {
    return _SoulBentoCard(
      color: _colorFingerprint,
      patternType: _BentoPattern.dotGrid,
      patternAnimation: _shimmerController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SPIRITUAL FINGERPRINT",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 1.8,
                ),
              ),
              AnimatedBuilder(
                animation: _patternIconController,
                builder: (_, __) {
                  return Transform.scale(
                    scale: 1.0 + sin(_patternIconController.value * pi) * 0.15,
                    child: Icon(
                      Icons.fingerprint_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 22,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () async {
              if (!_fingerprintVisible) {
                setState(() => _fingerprintVisible = true);
                _fingerprintRevealController.forward(from: 0);
                if (hasData && interactionCount >= 5 && StatsService.glooFingerprint.isEmpty) {
                  await _fetchFingerprint(topEmotion, anchorVerse, anchorCount, recovery, todaySpikes, pattern);
                }
              } else {
                _fingerprintRevealController.reverse().then((_) {
                  setState(() => _fingerprintVisible = false);
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_fingerprintVisible ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fingerprintVisible ? "Hide" : "Reveal your fingerprint",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _fingerprintVisible ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.85), size: 16),
                  ),
                ],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _fingerprintRevealController,
            builder: (_, child) {
              final curve = CurvedAnimation(parent: _fingerprintRevealController, curve: Curves.easeOut);
              return ClipRect(
                child: Align(
                  heightFactor: curve.value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildFingerprintContent(hasData, interactionCount, topEmotion, anchorVerse, anchorCount, recovery, todaySpikes, pattern),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFingerprintContent(bool hasData, int interactionCount, String topEmotion, String anchorVerse, int anchorCount, int recovery, int todaySpikes, Map<String, String> pattern) {
    if (!hasData || interactionCount < 5) {
      return Text(
        "Lumíne needs at least 5 interactions to read you. You have $interactionCount so far. Keep sharing.",
        style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.7, color: Colors.white.withOpacity(0.75)),
      );
    }
    if (StatsService.fingerprintLoading) {
      return Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          const SizedBox(width: 12),
          Text("Lumíne is reading your soul...", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withOpacity(0.7))),
        ],
      );
    }
    if (StatsService.glooFingerprint.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StatsService.glooFingerprint,
            style: GoogleFonts.playfairDisplay(fontSize: 15, height: 1.7, color: Colors.white.withOpacity(0.9), fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Written by Lumíne", style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              GestureDetector(
                onTap: () async {
                  setState(() => _refreshSpinning = true);
                  _refreshSpinController.repeat();
                  await _fetchFingerprint(topEmotion, anchorVerse, anchorCount, recovery, todaySpikes, pattern);
                  _refreshSpinController.stop();
                  _refreshSpinController.reset();
                  setState(() => _refreshSpinning = false);
                },
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _refreshSpinController,
                      builder: (_, __) => Transform.rotate(
                        angle: _refreshSpinController.value * 2 * pi,
                        child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.7), size: 14),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text("Refresh", style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Text(
      "Tap 'Reveal your fingerprint' to generate.",
      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withOpacity(0.6), fontStyle: FontStyle.italic),
    );
  }

  // ── Anchor Card — DEEP PURPLE #2D1B4E, quotation blobs ──────────────────
  Widget _buildSoulAnchorCard(String anchorVerse, String anchorText, int anchorCount) {
    return _SoulBentoCard(
      color: _colorAnchor,
      patternType: _BentoPattern.quotationMarks,
      patternAnimation: _pulseController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "YOUR ANCHOR VERSE",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 1.8,
                ),
              ),
              GestureDetector(
                onTap: () => TtsService.speak(anchorText),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15 + sin(_pulseController.value * pi) * 0.05),
                      ),
                      child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 16),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            '"$anchorText"',
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontStyle: FontStyle.italic,
              height: 1.6,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "— $anchorVerse",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Found you $anchorCount ${anchorCount == 1 ? 'time' : 'times'}",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Patterns Card — DEEP FOREST #1B3A2E, sun rays, 2x2 grid, deep words ─
  Widget _buildEmotionalPatternsCard(Map<String, String> pattern) {
    final periods = ["Morning", "Afternoon", "Evening", "Night"];
    final periodIcons = {
      "Morning": Icons.wb_sunny_rounded,
      "Afternoon": Icons.wb_cloudy_rounded,
      "Evening": Icons.wb_twilight_rounded,
      "Night": Icons.nights_stay_rounded,
    };

    return _SoulBentoCard(
      color: _colorPatterns,
      patternType: _BentoPattern.sunRays,
      patternAnimation: _shimmerController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "EMOTIONAL PATTERNS",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: periods.map((period) {
              final rawEmotion = pattern[period] ?? "calm";
              final deepWord = _deepWord(rawEmotion);
              final icon = periodIcons[period]!;
              final chipColor = _emotionChipColor(rawEmotion);

              return GestureDetector(
                onTap: () {
                  _expandCard(
                    "$period — $deepWord",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "During the $period, Lumíne observed $deepWord in you.",
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, height: 1.7, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getMessageForEmotion(rawEmotion),
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.7, color: Colors.black54, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: chipColor.withOpacity(0.35), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _patternIconController,
                            builder: (_, __) {
                              double offsetY = 0;
                              double rotation = 0;
                              if (period == "Morning") {
                                rotation = _patternIconController.value * 0.15;
                              } else if (period == "Night") {
                                offsetY = sin(_patternIconController.value * pi) * 2;
                              } else if (period == "Afternoon") {
                                rotation = sin(_patternIconController.value * pi) * 0.1;
                              } else {
                                offsetY = cos(_patternIconController.value * pi) * 2;
                              }
                              return Transform.translate(
                                offset: Offset(0, offsetY),
                                child: Transform.rotate(
                                  angle: rotation,
                                  child: Icon(icon, color: chipColor, size: 20),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Text(
                            period,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        deepWord,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _emotionChipColor(String emotion) {
    switch (emotion) {
      case "happy": return const Color(0xFFFFD24A);
      case "sad": return const Color(0xFFB8A0D8);
      case "calm": return const Color(0xFF7FB8D9);
      case "angry": return const Color(0xFFE87A5F);
      case "hopeful": return const Color(0xFF6FB8D9);
      case "anxious": return const Color(0xFFB893D4);
      case "grateful": return const Color(0xFF7DC98A);
      case "stressed": return const Color(0xFFF0A55A);
      case "optimistic": return const Color(0xFFFFCC33);
      case "depressed": return const Color(0xFF8590A0);
      default: return const Color(0xFF7FB8D9);
    }
  }

  String _getMessageForEmotion(String emotion) {
    switch (emotion) {
      case "happy": return "Joy visited you during this time. That brightness is a gift worth noticing.";
      case "sad": return "Sadness found you here. It is not weakness — it is the soul asking to be seen.";
      case "calm": return "Peace settled on you during this period. Rest like this is rare and sacred.";
      case "angry": return "Heat rose in you during this time. Anger often points to something that matters deeply.";
      case "hopeful": return "Hope was rising in you. That is the first light before dawn.";
      case "anxious": return "Anxiety visited during this time. Your nervous system was working hard to protect you.";
      case "grateful": return "Gratitude opened your heart here. That is one of the most powerful states to be in.";
      case "stressed": return "Stress pressed against you during this period. Your body was asking for relief.";
      case "optimistic": return "Expectation was alive in you. You were leaning toward something good.";
      case "depressed": return "Heaviness settled here. Even in the dark, something in you kept going.";
      default: return "Lumíne was with you during this time.";
    }
  }

  // ── Lumíne Sees — DEEP BURGUNDY #4A1F1F, concentric rings ───────────────
  Widget _buildLumineSees(int todaySpikes, int recovery) {
    return _SoulBentoCard(
      color: _colorLumineSees,
      patternType: _BentoPattern.concentricRings,
      patternAnimation: _pulseController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  return Transform.scale(
                    scale: 1.0 + sin(_pulseController.value * pi) * 0.1,
                    child: Icon(Icons.remove_red_eye_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                "WHAT LUMÍNE SEES",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            todaySpikes > 2
                ? "You have had $todaySpikes stress spikes today. Something is accumulating beneath the surface."
                : recovery > 0
                    ? "Your body takes about $recovery minutes to return to calm after stress."
                    : "Your signals have been steady. Lumíne is holding space quietly.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.7,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ── Journal — DEEP ESPRESSO #2B2417, horizontal lines, collapsed ────────
  Widget _buildJournalCard(String topEmotion, String anchorVerse, int anchorCount, int recovery, int todaySpikes, Map<String, String> pattern) {
    return _SoulBentoCard(
      color: _colorJournal,
      patternType: _BentoPattern.horizontalLines,
      patternAnimation: _shimmerController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S JOURNAL",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 1.8,
                ),
              ),
              AnimatedBuilder(
                animation: _patternIconController,
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(0, sin(_patternIconController.value * pi) * 2),
                    child: Icon(Icons.auto_stories_rounded, color: Colors.white.withOpacity(0.6), size: 18),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () async {
              if (!_journalVisible) {
                setState(() => _journalVisible = true);
                _journalRevealController.forward(from: 0);
                if (StatsService.todayJournal.isEmpty) {
                  await _fetchJournal();
                }
              } else {
                _journalRevealController.reverse().then((_) {
                  setState(() => _journalVisible = false);
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_journalVisible ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _journalVisible ? "Close journal" : "Open today's journal",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _journalVisible ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.85), size: 16),
                  ),
                ],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _journalRevealController,
            builder: (_, child) {
              final curve = CurvedAnimation(parent: _journalRevealController, curve: Curves.easeOut);
              return ClipRect(
                child: Align(
                  heightFactor: curve.value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatsService.journalLoading
                      ? Row(
                          children: [
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text("Writing your journal...", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                          ],
                        )
                      : Text(
                          StatsService.todayJournal.isEmpty
                              ? "Tap 'Open today's journal' to reflect on your day."
                              : StatsService.todayJournal,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.7,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                  const SizedBox(height: 16),
                  if (StatsService.todayJournal.isNotEmpty && !StatsService.journalLoading)
                    GestureDetector(
                      onTap: () async {
                        setState(() => _refreshSpinning = true);
                        _refreshSpinController.repeat();
                        await _fetchJournal();
                        _refreshSpinController.stop();
                        _refreshSpinController.reset();
                        setState(() => _refreshSpinning = false);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _refreshSpinController,
                            builder: (_, __) => Transform.rotate(
                              angle: _refreshSpinController.value * 2 * pi,
                              child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.7), size: 14),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Refresh",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Future<void> _fetchJournal() async {
    setState(() {
      StatsService.journalLoading = true;
      StatsService.todayJournal = "";
    });
    try {
      final emotions = StatsService.emotionHistory.isNotEmpty
          ? StatsService.emotionHistory
          : [{"emotion": "calm", "hour": DateTime.now().hour}];
      final result = await ApiService.getJournal(
        emotions: emotions,
        interruptions: StatsService.sacredInterruptions,
        spikes: StatsService.getStressSpikesToday(),
      );
      if (mounted) {
        setState(() {
          StatsService.todayJournal = result['journal'] ?? '';
          StatsService.journalLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          StatsService.todayJournal = "Lumíne was quietly present with you today.";
          StatsService.journalLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFingerprint(String topEmotion, String anchorVerse, int anchorCount, int recovery, int todaySpikes, Map<String, String> pattern) async {
    setState(() {
      StatsService.fingerprintLoading = true;
      StatsService.glooFingerprint = "";
    });
    try {
      final recentEmotions = StatsService.emotionHistory.map((e) => e["emotion"] as String).toList();
      final result = await ApiService.getSoulMap(
        topEmotion: topEmotion,
        anchorVerse: anchorVerse,
        anchorCount: anchorCount,
        recoveryMinutes: recovery,
        stressSpikes: todaySpikes,
        pattern: pattern,
        interruptions: StatsService.sacredInterruptions,
        daysActive: StatsService.streakDays,
        recentEmotions: recentEmotions,
      );
      if (mounted) {
        setState(() {
          StatsService.glooFingerprint = result['fingerprint'] ?? '';
          StatsService.fingerprintLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          StatsService.glooFingerprint = "You carry more than most people see — and you keep returning to stillness anyway.";
          StatsService.fingerprintLoading = false;
        });
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController(),
      builder: (context, child) {
        final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
        final screens = [
          _buildStateScreen(),
          const ScriptureFeedScreen(),
          _buildSoulMapScreen(),
          const ChatScreen(),
          const HabitsScreen(),
        ];
        return Scaffold(
          body: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  );
                },
             child: KeyedSubtree(
  key: ValueKey<int>(_selectedIndex),
  child: screens[_selectedIndex],
),
              ),
              if (!keyboardVisible)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        height: 75,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _navIcon(Icons.grid_view_rounded, 0, "State"),
                            _navIcon(Icons.spa_rounded, 1, "Zen"),
                            _navIcon(Icons.auto_awesome_mosaic_rounded, 2, "Soul"),
                            _navIcon(Icons.chat_bubble_outline_rounded, 3, "Reflect"),
                            _navIcon(Icons.insights_rounded, 4, "Patterns"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _navIcon(IconData icon, int index, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.white38, size: 22),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.plusJakartaSans(color: isSelected ? Colors.white : Colors.white38, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SOUL BENTO CARD — colored, animated pattern
// ════════════════════════════════════════════════════════════════════════════
enum _BentoPattern { dotGrid, quotationMarks, sunRays, concentricRings, horizontalLines }

class _SoulBentoCard extends StatefulWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final _BentoPattern patternType;
  final Animation<double> patternAnimation;

  const _SoulBentoCard({
    required this.child,
    required this.color,
    required this.patternType,
    required this.patternAnimation,
    this.onTap,
  });

  @override
  State<_SoulBentoCard> createState() => _SoulBentoCardState();
}

class _SoulBentoCardState extends State<_SoulBentoCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: widget.patternAnimation,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: _BentoPatternPainter(
                          type: widget.patternType,
                          animation: widget.patternAnimation.value,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BENTO PATTERN PAINTER
// ════════════════════════════════════════════════════════════════════════════
class _BentoPatternPainter extends CustomPainter {
  final _BentoPattern type;
  final double animation;

  _BentoPatternPainter({required this.type, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05);

    switch (type) {
      case _BentoPattern.dotGrid:
        for (double x = 15; x < size.width; x += 22) {
          for (double y = 15; y < size.height; y += 22) {
            final wave = sin(animation * 2 * pi + x * 0.05 + y * 0.05) * 0.5 + 0.5;
            canvas.drawCircle(Offset(x, y), 1.5 * wave, paint);
          }
        }
        break;

      case _BentoPattern.quotationMarks:
        final markPaint = Paint()..color = Colors.white.withOpacity(0.04);
        canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.3), 60, markPaint);
        canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.7), 50, markPaint);
        break;

      case _BentoPattern.sunRays:
        final center = Offset(size.width * 0.9, size.height * 0.2);
        final rayPaint = Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        for (int i = 0; i < 12; i++) {
          final angle = (i / 12) * 2 * pi + animation * 0.3;
          canvas.drawLine(
            center,
            Offset(center.dx + cos(angle) * 200, center.dy + sin(angle) * 200),
            rayPaint,
          );
        }
        break;

      case _BentoPattern.concentricRings:
        final ringPaint = Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        final center = Offset(size.width * 0.5, size.height * 0.5);
        for (int i = 1; i <= 8; i++) {
          final radius = i * 25.0 + sin(animation * 2 * pi + i) * 3;
          canvas.drawCircle(center, radius, ringPaint);
        }
        break;

      case _BentoPattern.horizontalLines:
        final linePaint = Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..strokeWidth = 0.8;
        for (double y = 20; y < size.height; y += 14) {
          final shift = sin(animation * 2 * pi + y * 0.1) * 5;
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width + shift, y),
            linePaint,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BentoPatternPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.type != type;
}

// ════════════════════════════════════════════════════════════════════════════
// BLOB WAVE BACKGROUND PAINTER — like your image
// ════════════════════════════════════════════════════════════════════════════
class _BlobWavePainter extends CustomPainter {
  final double animation;
  final Color blobColor;

  _BlobWavePainter({required this.animation, required this.blobColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = blobColor.withOpacity(0.85);

    final t = animation * 2 * pi;

    final blobs = [
      _blob(size, 0.1, 0.1, 90, t * 0.7, 0),
      _blob(size, 0.4, 0.15, 110, t * 0.5, 1),
      _blob(size, 0.75, 0.1, 100, t * 0.8, 2),
      _blob(size, 0.15, 0.4, 130, t * 0.6, 3),
      _blob(size, 0.5, 0.45, 120, t * 0.9, 4),
      _blob(size, 0.85, 0.45, 100, t * 0.5, 5),
      _blob(size, 0.2, 0.75, 110, t * 0.7, 6),
      _blob(size, 0.55, 0.75, 130, t * 0.6, 7),
      _blob(size, 0.85, 0.8, 100, t * 0.8, 8),
      _blob(size, 0.35, 0.95, 90, t * 0.5, 9),
    ];

    for (final blob in blobs) {
      canvas.drawPath(blob, paint);
    }
  }

  Path _blob(Size size, double cxRatio, double cyRatio, double baseRadius, double t, int seed) {
    final cx = size.width * cxRatio;
    final cy = size.height * cyRatio;
    final path = Path();

    const points = 12;
    for (int i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * pi;
      final wobble = sin(t + i * 1.5 + seed * 0.7) * 20 +
          cos(t * 0.5 + i * 2 + seed) * 15;
      final r = baseRadius + wobble;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevAngle = ((i - 1) / points) * 2 * pi;
        final prevWobble = sin(t + (i - 1) * 1.5 + seed * 0.7) * 20 +
            cos(t * 0.5 + (i - 1) * 2 + seed) * 15;
        final prevR = baseRadius + prevWobble;
        final ctrlAngle = (prevAngle + angle) / 2;
        final ctrlR = (prevR + r) / 2 * 1.15;
        final ctrlX = cx + cos(ctrlAngle) * ctrlR;
        final ctrlY = cy + sin(ctrlAngle) * ctrlR;
        path.quadraticBezierTo(ctrlX, ctrlY, x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BlobWavePainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.blobColor != blobColor;
}

// ════════════════════════════════════════════════════════════════════════════
// EXISTING WIDGETS — unchanged
// ════════════════════════════════════════════════════════════════════════════

class BouncyGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color glowColor;
  final Animation<double> glowAnimation;

  const BouncyGlassCard({super.key, required this.child, this.onTap, required this.glowColor, required this.glowAnimation});

  @override
  State<BouncyGlassCard> createState() => _BouncyGlassCardState();
}

class _BouncyGlassCardState extends State<BouncyGlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: widget.glowAnimation,
          builder: (context, child) {
            final glowStrength = widget.glowAnimation.value;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color.lerp(Colors.white, widget.glowColor, 0.08)!.withOpacity(0.92),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: widget.glowColor.withOpacity(glowStrength * 0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(color: widget.glowColor.withOpacity(glowStrength * 0.20), blurRadius: 24, spreadRadius: 2),
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}

class AuroraMeshBackground extends StatelessWidget {
  final Color baseColor;
  final AnimationController floatController;
  final Color moodGlow;

  const AuroraMeshBackground({super.key, required this.baseColor, required this.floatController, required this.moodGlow});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1200),
      color: baseColor,
      child: AnimatedBuilder(
        animation: floatController,
        builder: (context, child) {
          final t = floatController.value * 2 * pi;
          return Stack(
            children: [
              Positioned(
                top: -80 + sin(t) * 30, right: -60 + cos(t) * 30,
                child: Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, color: moodGlow.withOpacity(0.18))),
              ),
              Positioned(
                bottom: 100 + cos(t + 1) * 40, left: -80 + sin(t + 1) * 40,
                child: Container(width: 380, height: 380, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.14))),
              ),
              Positioned(
                top: 250 + sin(t + 2) * 20, left: 80 + cos(t + 2) * 30,
                child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: moodGlow.withOpacity(0.10))),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MeshBackground extends StatelessWidget {
  final Color? overrideColor;
  const MeshBackground({super.key, this.overrideColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      color: overrideColor ?? const Color(0xFFFDFCF0),
    );
  }
}

class BentoCard extends StatelessWidget {
  final Widget child;
  final double? height;

  const BentoCard({super.key, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: child,
    );
  }
}

class EmotionWavePainter extends CustomPainter {
  final List<double> intensities;
  final double animation;

  EmotionWavePainter({required this.intensities, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensities.isEmpty) return;
    final paint = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED), Color(0xFFEC4899)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF8B5CF6).withOpacity(0.3), const Color(0xFF8B5CF6).withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final segmentWidth = size.width / (intensities.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < intensities.length; i++) {
      final x = i * segmentWidth;
      final baseY = size.height - (intensities[i] * size.height * 0.85) - 5;
      final wobble = sin((animation * 2 * pi) + (i * 0.5)) * 3;
      final y = baseY + wobble;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * segmentWidth;
        final prevBaseY = size.height - (intensities[i - 1] * size.height * 0.85) - 5;
        final prevWobble = sin((animation * 2 * pi) + ((i - 1) * 0.5)) * 3;
        final prevY = prevBaseY + prevWobble;
        final controlX = (prevX + x) / 2;
        path.cubicTo(controlX, prevY, controlX, y, x, y);
        fillPath.cubicTo(controlX, prevY, controlX, y, x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    for (int i = 0; i < intensities.length; i++) {
      final x = i * segmentWidth;
      final baseY = size.height - (intensities[i] * size.height * 0.85) - 5;
      final wobble = sin((animation * 2 * pi) + (i * 0.5)) * 3;
      final y = baseY + wobble;
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = const Color(0xFF7C3AED));
    }
  }

  @override
  bool shouldRepaint(covariant EmotionWavePainter oldDelegate) => true;
}