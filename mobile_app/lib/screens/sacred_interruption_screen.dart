import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/tts_service.dart';
import '../services/stats_service.dart';
import '../services/memory_service.dart';

class SacredInterruptionScreen extends StatefulWidget {
  final String scriptureText;
  final String scriptureRef;

  const SacredInterruptionScreen({
    super.key,
    required this.scriptureText,
    required this.scriptureRef,
  });

  @override
  State<SacredInterruptionScreen> createState() =>
      _SacredInterruptionScreenState();
}

class _SacredInterruptionScreenState extends State<SacredInterruptionScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _fadeInController;
  late AnimationController _orbController;
  late AnimationController _breathController;
  late AnimationController _ambientController;
  late AnimationController _particleController;

  // State
  bool _wordsRevealed = false;
  bool _showReference = false;
  bool _showWhisper = false;
  bool _showActions = false;
  bool _breathActive = false;
  bool _feedbackShown = false;
  bool _showEmergency = false;
  bool _isSaved = false;

  // Word reveal
  List<String> _words = [];
  int _revealedCount = 0;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Sacred palette — deep dusky midnight base, warm gold accents
  static const Color _bgBase = Color(0xFF0A0E1A);        // deep midnight
  static const Color _bgAurora = Color(0xFF1E293B);      // slate mist
  static const Color _accent = Color(0xFFE9D08C);        // sacred gold
  static const Color _accentSoft = Color(0xFFF4E4B8);    // soft gold
  static const Color _accentDeep = Color(0xFF8B6F2E);    // deep amber

  Timer? _revealTimer;
  Timer? _sequenceTimer;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Slow fade-in over 2 seconds
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Orb slow breath
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // 4-7-8 breath cycle: 4s inhale + 7s hold + 8s exhale = 19s total
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19),
    );

    // Ambient drifting aurora
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Slow-rising particles (incense)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _startAmbientAudio();
    _startSequence();
    _recordInterruption();
  }

  Future<void> _recordInterruption() async {
    StatsService.sacredInterruptions++;
  }

  Future<void> _startAmbientAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.15);
      await _audioPlayer.play(AssetSource('audio/ambient.mp3'));
    } catch (_) {}
  }

  void _startSequence() {
    // After fade-in (2s), start revealing words
    _sequenceTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _revealWords();
    });
  }

  void _revealWords() {
    _words = widget.scriptureText.split(' ');
    _revealedCount = 0;

    // Word every 380ms for a total of ~6-8 seconds
    _revealTimer = Timer.periodic(const Duration(milliseconds: 380), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _revealedCount++);
      if (_revealedCount >= _words.length) {
        timer.cancel();
        setState(() => _wordsRevealed = true);
        // After all words: show reference (800ms), then whisper (1600ms), then actions (2400ms)
        Timer(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _showReference = true);
        });
        Timer(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _showWhisper = true);
        });
        Timer(const Duration(milliseconds: 2600), () {
          if (mounted) setState(() => _showActions = true);
        });
        Timer(const Duration(milliseconds: 3400), () {
          if (mounted) setState(() => _showEmergency = true);
        });
      }
    });
  }

  void _startBreath() {
    setState(() => _breathActive = true);
    _breathController.forward(from: 0);
    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Loop breath
        _breathController.forward(from: 0);
      }
    });
  }

  void _stopBreath() {
    setState(() => _breathActive = false);
    _breathController.stop();
    _breathController.reset();
  }

  Future<void> _listenAgain() async {
    await TtsService.stop();
    await TtsService.speakSynced(widget.scriptureText, 0.32);
  }

  Future<void> _saveVerse() async {
    if (_isSaved) return;
    StatsService.saveVerse(widget.scriptureText, widget.scriptureRef);
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved to your Verses Vault',
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: _accentDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _requestMoreVerses() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'More verses like this — coming soon',
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: _accentDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _snoozeGracefully() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "That's okay. I'll return when you're ready.",
          style: GoogleFonts.plusJakartaSans(fontStyle: FontStyle.italic),
        ),
        backgroundColor: _accentDeep,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) _exit();
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFFE9D08C), size: 40),
              const SizedBox(height: 16),
              Text(
                "You matter.",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "If you're in crisis, please reach out. You don't have to carry this alone.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9D08C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_rounded, color: Color(0xFF1A0A0A), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '988 · Suicide & Crisis Lifeline',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A0A0A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Available 24/7 · Free · Confidential",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFeedback(String feeling) async {
    setState(() => _feedbackShown = true);
    // Save feedback silently to memory
    await MemoryService.saveUserNote(
      'last_intervention_feedback',
      {
        'feeling': feeling,
        'verse': widget.scriptureRef,
        'at': DateTime.now().toIso8601String(),
      },
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Noted. Lumíne is learning what helps you.",
          style: GoogleFonts.plusJakartaSans(fontStyle: FontStyle.italic),
        ),
        backgroundColor: _accentDeep,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) _exit();
  }

  void _exit() {
    // Reverse fade before pop
    _fadeInController.reverse().then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _confirmExit() async {
    // If no feedback yet, show feedback prompt
    if (!_feedbackShown && _showActions) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (_) => _buildFeedbackSheet(),
      );
      return;
    }
    _exit();
  }

  Widget _buildFeedbackSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141826),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'How do you feel now?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _feedbackChip('Better', '🌿', const Color(0xFF4ADE80))),
              const SizedBox(width: 10),
              Expanded(child: _feedbackChip('Same', '🌊', const Color(0xFF60A5FA))),
              const SizedBox(width: 10),
              Expanded(child: _feedbackChip('Worse', '🌫', const Color(0xFFB07FE0))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feedbackChip(String label, String emoji, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showFeedback(label.toLowerCase());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _whyThisVerse() {
    final now = DateTime.now();
    final elapsed = _startTime != null
        ? now.difference(_startTime!).inMinutes
        : 0;
    return elapsed <= 1
        ? "Your body signaled stress right now.\nThis came for that."
        : "Your body has been holding weight for $elapsed minute${elapsed == 1 ? '' : 's'}.\nThis came for that.";
  }

  String _timeStamp() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '$hour:$minute $period · ${days[now.weekday - 1]}';
  }

  // ── Breath phase computation for 4-7-8 ──
  // 0-4s: inhale (scale 0.7 → 1.15)
  // 4-11s: hold (stay at 1.15)
  // 11-19s: exhale (1.15 → 0.7)
  Map<String, dynamic> _breathState() {
    if (!_breathActive) return {'scale': 1.0, 'label': ''};
    final t = _breathController.value * 19; // 0-19 seconds
    if (t < 4) {
      // Inhale
      final progress = t / 4;
      final scale = 0.7 + Curves.easeInOut.transform(progress) * 0.45;
      return {'scale': scale, 'label': 'Breathe in'};
    } else if (t < 11) {
      // Hold
      return {'scale': 1.15, 'label': 'Hold'};
    } else {
      // Exhale
      final progress = (t - 11) / 8;
      final scale = 1.15 - Curves.easeInOut.transform(progress) * 0.45;
      return {'scale': scale, 'label': 'Breathe out'};
    }
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _sequenceTimer?.cancel();
    _fadeInController.dispose();
    _orbController.dispose();
    _breathController.dispose();
    _ambientController.dispose();
    _particleController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    TtsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _confirmExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: _bgBase,
        body: AnimatedBuilder(
          animation: _fadeInController,
          builder: (context, _) {
            final fadeIn = Curves.easeInOut.transform(_fadeInController.value);

            return Stack(
              children: [
                // ── Ambient aurora background ──
                Positioned.fill(
                  child: Opacity(
                    opacity: fadeIn,
                    child: AnimatedBuilder(
                      animation: _ambientController,
                      builder: (_, __) {
                        return CustomPaint(
                          painter: _SacredAuroraPainter(
                            t: _ambientController.value * 2 * pi,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Slow-rising particles (incense) ──
                Positioned.fill(
                  child: Opacity(
                    opacity: fadeIn * 0.6,
                    child: AnimatedBuilder(
                      animation: _particleController,
                      builder: (_, __) {
                        return CustomPaint(
                          painter: _ParticlePainter(
                            t: _particleController.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Content ──
                SafeArea(
                  child: Opacity(
                    opacity: fadeIn,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),

                            // Close button top-right
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _confirmExit,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Timestamp
                            Text(
                              _timeStamp(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: _accent.withOpacity(0.55),
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Pause. heading
                            Text(
                              'Pause.',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 46,
                                fontWeight: FontWeight.bold,
                                color: _accentSoft,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Let this moment soften.',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ── Orb with breath ring ──
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                _orbController,
                                _breathController,
                              ]),
                              builder: (_, __) {
                                final breath = _breathState();
                                final breathScale = breath['scale'] as double;
                                final orbBreath = 0.95 + sin(_orbController.value * pi) * 0.05;

                                return SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer breath ring — only when breath active
                                      if (_breathActive)
                                        Transform.scale(
                                          scale: breathScale,
                                          child: Container(
                                            width: 260,
                                            height: 260,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: _accent.withOpacity(0.5),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _accent.withOpacity(0.25),
                                                  blurRadius: 30,
                                                  spreadRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                      // The orb
                                      GestureDetector(
                                        onTap: _breathActive ? _stopBreath : _startBreath,
                                        child: CustomPaint(
                                          size: const Size(200, 200),
                                          painter: _SacredOrbPainter(
                                            breath: orbBreath,
                                            active: _breathActive,
                                          ),
                                        ),
                                      ),

                                      // Breath label
                                      if (_breathActive)
                                        Positioned(
                                          bottom: 12,
                                          child: Text(
                                            breath['label'] as String,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _accent,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 6),

                            // Tap hint
                            if (!_breathActive && _showActions)
                              Text(
                                'Tap orb to breathe with me',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.45),
                                  letterSpacing: 1.2,
                                ),
                              ).animate().fadeIn(duration: 600.ms),

                            const SizedBox(height: 44),

                            // ── Verse — word by word reveal ──
                            _buildWordReveal(),

                            const SizedBox(height: 22),

                            // Reference (appears after verse)
                            AnimatedOpacity(
                              opacity: _showReference ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                '— ${widget.scriptureRef}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: _accent.withOpacity(0.75),
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // "Why this verse" whisper
                            AnimatedOpacity(
                              opacity: _showWhisper ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 1000),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: Text(
                                  _whyThisVerse(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    height: 1.6,
                                    color: Colors.white.withOpacity(0.55),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Action row ──
                            AnimatedOpacity(
                              opacity: _showActions ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 800),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  _actionButton(
                                    icon: _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    label: _isSaved ? 'Saved' : 'Save',
                                    onTap: _saveVerse,
                                    primary: false,
                                  ),
                                  _actionButton(
                                    icon: Icons.volume_up_rounded,
                                    label: 'Listen',
                                    onTap: _listenAgain,
                                    primary: false,
                                  ),
                                  _actionButton(
                                    icon: Icons.more_horiz_rounded,
                                    label: '3 more',
                                    onTap: _requestMoreVerses,
                                    primary: false,
                                  ),
                                  _actionButton(
                                    icon: Icons.access_time_rounded,
                                    label: 'Not now',
                                    onTap: _snoozeGracefully,
                                    primary: false,
                                  ),
                                  _actionButton(
                                    icon: Icons.check_rounded,
                                    label: 'I am here',
                                    onTap: _confirmExit,
                                    primary: true,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ── Emergency escape at bottom ──
                            AnimatedOpacity(
                              opacity: _showEmergency ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 600),
                              child: GestureDetector(
                                onTap: _showEmergencyDialog,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.support_rounded,
                                      size: 12,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Need to talk to someone? Tap for help.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.35),
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWordReveal() {
    if (_words.isEmpty) {
      return const SizedBox(height: 60);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 10,
        children: List.generate(_words.length, (i) {
          final visible = i < _revealedCount;
          return AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: Text(
              _words[i],
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: primary ? _accent : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary ? Colors.transparent : Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: _accent.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: primary ? _bgBase : Colors.white.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary ? _bgBase : Colors.white.withOpacity(0.85),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SACRED AURORA BACKGROUND
// ══════════════════════════════════════════════════════════════════
class _SacredAuroraPainter extends CustomPainter {
  final double t;
  _SacredAuroraPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep midnight base
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0E1A));

    // Drifting slate mist blob 1
    final blob1Center = Offset(
      size.width * (0.2 + sin(t * 0.3) * 0.1),
      size.height * (0.3 + cos(t * 0.25) * 0.08),
    );
    final blob1 = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    canvas.drawCircle(blob1Center, size.width * 0.6, blob1);

    // Drifting slate mist blob 2 (bluer)
    final blob2Center = Offset(
      size.width * (0.8 + cos(t * 0.2) * 0.1),
      size.height * (0.7 + sin(t * 0.3) * 0.08),
    );
    final blob2 = Paint()
      ..color = const Color(0xFF2C3E5C).withOpacity(0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(blob2Center, size.width * 0.55, blob2);

    // Subtle warm gold accent glow (center-top)
    final blob3Center = Offset(
      size.width * 0.5,
      size.height * (0.4 + sin(t * 0.4) * 0.05),
    );
    final blob3 = Paint()
      ..color = const Color(0xFFE9D08C).withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(blob3Center, size.width * 0.5, blob3);
  }

  @override
  bool shouldRepaint(covariant _SacredAuroraPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════
// PARTICLE PAINTER — incense rising
// ══════════════════════════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    const count = 25;
    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final startY = size.height + rng.nextDouble() * 200;
      final rise = (t * 800 + i * 40) % (size.height + 200);
      final y = startY - rise;
      if (y < -20) continue;

      final drift = sin((t * 2 * pi) + i) * 20;
      final finalX = x + drift;

      // Fade at top and bottom
      double opacity = 1.0;
      if (y < 100) opacity = y / 100;
      if (y > size.height - 100) opacity = (size.height - y) / 100;
      opacity = opacity.clamp(0.0, 1.0) * 0.35;

      final radius = 1.0 + rng.nextDouble() * 1.2;
      canvas.drawCircle(
        Offset(finalX, y),
        radius,
        Paint()..color = const Color(0xFFE9D08C).withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════
// SACRED ORB — cloudy misty gold
// ══════════════════════════════════════════════════════════════════
class _SacredOrbPainter extends CustomPainter {
  final double breath;
  final bool active;

  _SacredOrbPainter({required this.breath, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * breath;

    const gold = Color(0xFFE9D08C);
    const softGold = Color(0xFFF4E4B8);
    const deepAmber = Color(0xFF8B6F2E);

    // Outer big soft glow
    final outerGlow = Paint()
      ..color = gold.withOpacity(active ? 0.55 : 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, active ? 55 : 45);
    canvas.drawCircle(center, radius * 0.95, outerGlow);

    // Second glow ring
    final glow2 = Paint()
      ..color = softGold.withOpacity(active ? 0.35 : 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(center, radius, glow2);

    // Clip orb
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // Base sphere
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [softGold, gold, deepAmber],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, basePaint);

    // Bright core near top-left
    final coreCenter = Offset(center.dx - radius * 0.15, center.dy - radius * 0.2);
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.95),
          Colors.white.withOpacity(0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: coreCenter, radius: radius * 0.4));
    canvas.drawCircle(coreCenter, radius * 0.4, corePaint);

    // Tiny sparkle core
    canvas.drawCircle(coreCenter, radius * 0.05, Paint()..color = Colors.white);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SacredOrbPainter old) =>
      old.breath != breath || old.active != active;
}