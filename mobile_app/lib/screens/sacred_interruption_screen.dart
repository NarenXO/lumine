import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/tts_service.dart';
import '../services/stats_service.dart';
import '../services/memory_service.dart';
import '../services/app_theme.dart';

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
  late AnimationController _fadeInController;
  late AnimationController _orbController;
  late AnimationController _breathController;
  late AnimationController _ambientController;
  late AnimationController _particleController;
  late AnimationController _constellationController;

  bool _wordsRevealed = false;
  bool _showReference = false;
  bool _showWhisper = false;
  bool _showActions = false;
  bool _breathActive = false;
  bool _feedbackShown = false;
  bool _showEmergency = false;
  bool _isSaved = false;
  bool _showConstellationMessage = false;

  late String _displayVerse;
  late String _displayRef;

  List<String> _words = [];
  int _revealedCount = 0;

  // 3 more verses
  int _extraVersesLeft = 3;
  int _extraVerseIndex = 0;
  bool _loadingExtra = false;

  final List<Map<String, String>> _extraVerseBank = [
    {'text': 'The Lord is my light and my salvation — whom shall I fear?', 'ref': 'Psalm 27:1'},
    {'text': 'Do not be anxious about anything, but in every situation, by prayer and petition, present your requests to God.', 'ref': 'Philippians 4:6'},
    {'text': 'God is our refuge and strength, an ever-present help in trouble.', 'ref': 'Psalm 46:1'},
    {'text': 'Even though I walk through the darkest valley, I will fear no evil, for you are with me.', 'ref': 'Psalm 23:4'},
    {'text': 'The peace of God, which transcends all understanding, will guard your hearts and your minds.', 'ref': 'Philippians 4:7'},
    {'text': 'He gives strength to the weary and increases the power of the weak.', 'ref': 'Isaiah 40:29'},
    {'text': 'Trust in the Lord with all your heart and lean not on your own understanding.', 'ref': 'Proverbs 3:5'},
    {'text': 'The Lord himself goes before you and will be with you; he will never leave you nor forsake you.', 'ref': 'Deuteronomy 31:8'},
    {'text': 'But those who hope in the Lord will renew their strength. They will soar on wings like eagles.', 'ref': 'Isaiah 40:31'},
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _revealTimer;
  Timer? _sequenceTimer;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _displayVerse = widget.scriptureText;
    _displayRef = widget.scriptureRef;
    _extraVerseBank.shuffle();

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _constellationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

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
    _sequenceTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _revealWords();
    });
  }

  void _revealWords() {
    _words = _displayVerse.split(' ');
    _revealedCount = 0;

    _revealTimer = Timer.periodic(const Duration(milliseconds: 380), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _revealedCount++);
      if (_revealedCount >= _words.length) {
        timer.cancel();
        setState(() => _wordsRevealed = true);
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
    await TtsService.speakSynced(_displayVerse, 0.32);
  }

  Future<void> _saveVerse() async {
    if (_isSaved) return;
    StatsService.saveVerse(_displayVerse, _displayRef);
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved to your Verses Vault',
            style: GoogleFonts.manrope(color: Colors.white)),
        backgroundColor: AppTheme.bgSlateHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _loadNextExtraVerse() {
    if (_extraVersesLeft <= 0 || _loadingExtra) return;
    _loadingExtra = true;
    _extraVersesLeft--;

    // Cancel any existing reveal
    _revealTimer?.cancel();

    // Fade out then swap
    setState(() {
      _words = [];
      _revealedCount = 0;
      _wordsRevealed = false;
      _showReference = false;
    });

    Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final verse = _extraVerseBank[_extraVerseIndex % _extraVerseBank.length];
      _extraVerseIndex++;

      setState(() {
        _displayVerse = verse['text']!;
        _displayRef = verse['ref']!;
        _isSaved = false;
      });

      // Reveal new verse
      _words = _displayVerse.split(' ');
      _revealedCount = 0;

      _revealTimer = Timer.periodic(const Duration(milliseconds: 380), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _revealedCount++);
        if (_revealedCount >= _words.length) {
          timer.cancel();
          setState(() {
            _wordsRevealed = true;
          });
          Timer(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _showReference = true);
          });
        }
      });

      _loadingExtra = false;
    });
  }

  void _snoozeGracefully() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("That's okay. I'll return when you're ready.",
            style: GoogleFonts.manrope(fontStyle: FontStyle.italic, color: Colors.white)),
        backgroundColor: AppTheme.bgSlateHigh,
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
        backgroundColor: AppTheme.bgSlate,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.bgSlateGlow),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, color: AppTheme.goldMid, size: 40),
              const SizedBox(height: 16),
              Text(
                'You matter.',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "If you're in crisis, please reach out. You don't have to carry this alone.",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.goldMid,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_rounded, color: AppTheme.bgDeep, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '988 · Suicide & Crisis Lifeline',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.bgDeep,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Available 24/7 · Free · Confidential',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
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
    setState(() {
      _feedbackShown = true;
      _showConstellationMessage = true;
    });

    _constellationController.forward(from: 0);

    await MemoryService.saveUserNote(
      'last_intervention_feedback',
      {
        'feeling': feeling,
        'verse': _displayRef,
        'at': DateTime.now().toIso8601String(),
      },
    );

    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) _exit();
  }

  void _exit() {
    _fadeInController.reverse().then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _confirmExit() async {
    if (!_feedbackShown && _showActions) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (_) => _SacredFeedbackSheet(
          onFeedback: (feeling) {
            Navigator.pop(context);
            _showFeedback(feeling);
          },
        ),
      );
      return;
    }
    _exit();
  }

  String _whyThisVerse() {
    final now = DateTime.now();
    final elapsed =
        _startTime != null ? now.difference(_startTime!).inMinutes : 0;
    return elapsed <= 1
        ? 'Your body signaled stress right now.\nThis came for that.'
        : 'Your body has been holding weight for $elapsed minute${elapsed == 1 ? '' : 's'}.\nThis came for that.';
  }

  String _timeStamp() {
    final now = DateTime.now();
    final hour =
        now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return '$hour:$minute $period · ${days[now.weekday - 1]}';
  }

  Map<String, dynamic> _breathState() {
    if (!_breathActive) return {'scale': 1.0, 'label': ''};
    final t = _breathController.value * 19;
    if (t < 4) {
      final progress = t / 4;
      final scale = 0.7 + Curves.easeInOut.transform(progress) * 0.45;
      return {'scale': scale, 'label': 'Breathe in'};
    } else if (t < 11) {
      return {'scale': 1.15, 'label': 'Hold'};
    } else {
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
    _constellationController.dispose();
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
        backgroundColor: AppTheme.bgDeep,
        body: AnimatedBuilder(
          animation: _fadeInController,
          builder: (context, _) {
            final fadeIn =
                Curves.easeInOut.transform(_fadeInController.value);

            return Stack(
              children: [
                // Aurora background
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

                // Particles
                Positioned.fill(
                  child: Opacity(
                    opacity: fadeIn * 0.6,
                    child: AnimatedBuilder(
                      animation: _particleController,
                      builder: (_, __) {
                        return CustomPaint(
                          painter: _SacredParticlePainter(
                            t: _particleController.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Constellation overlay
                if (_showConstellationMessage)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _constellationController,
                      builder: (_, __) {
                        return CustomPaint(
                          painter: _ConstellationPainter(
                            t: _constellationController.value,
                          ),
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _constellationController.value > 0.4
                                  ? 1.0
                                  : 0.0,
                              duration: const Duration(milliseconds: 800),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'This is now part of who\nLumíne knows you to be.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.goldCenter,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Content
                if (!_showConstellationMessage)
                  SafeArea(
                    child: Opacity(
                      opacity: fadeIn,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),

                              // Close button
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _confirmExit,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgSlate,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppTheme.borderSoft),
                                    ),
                                    child: Icon(Icons.close_rounded,
                                        color: AppTheme.textSecondary,
                                        size: 20),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Timestamp
                              Text(
                                _timeStamp(),
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: AppTheme.goldMid.withOpacity(0.55),
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Pause.
                              Text(
                                'Pause.',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.goldCenter,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Let this moment soften.',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textSecondary,
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Orb with breath ring
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  _orbController,
                                  _breathController,
                                  _ambientController,
                                ]),
                                builder: (_, __) {
                                  final breath = _breathState();
                                  final breathScale =
                                      breath['scale'] as double;
                                  final orbBreath = 0.95 +
                                      sin(_orbController.value * pi) * 0.05;

                                  return SizedBox(
                                    width: 300,
                                    height: 300,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Breath ring
                                        if (_breathActive)
                                          Transform.scale(
                                            scale: breathScale,
                                            child: Container(
                                              width: 260,
                                              height: 260,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppTheme.goldMid
                                                      .withOpacity(0.5),
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.goldMid
                                                        .withOpacity(0.25),
                                                    blurRadius: 30,
                                                    spreadRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                        // Orb
                                        GestureDetector(
                                          onTap: _breathActive
                                              ? _stopBreath
                                              : _startBreath,
                                          child: CustomPaint(
                                            size: const Size(200, 200),
                                            painter:
                                                _SacredOrbPainter(
                                              breath: orbBreath,
                                              active: _breathActive,
                                              t: _ambientController.value *
                                                  2 *
                                                  pi,
                                            ),
                                          ),
                                        ),

                                        // Breath label
                                        if (_breathActive)
                                          Positioned(
                                            bottom: 12,
                                            child: Text(
                                              breath['label'] as String,
                                              style: GoogleFonts.manrope(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.goldMid,
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
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    color: AppTheme.textTertiary,
                                    letterSpacing: 1.2,
                                  ),
                                ).animate().fadeIn(duration: 600.ms),

                              const SizedBox(height: 44),

                              // Verse word-by-word
                              _buildWordReveal(),

                              const SizedBox(height: 22),

                              // Reference
                              AnimatedOpacity(
                                opacity: _showReference ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 800),
                                child: Text(
                                  '— $_displayRef',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color:
                                        AppTheme.goldMid.withOpacity(0.75),
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Why this verse whisper
                              AnimatedOpacity(
                                opacity: _showWhisper ? 1.0 : 0.0,
                                duration:
                                    const Duration(milliseconds: 1000),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgSlate,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppTheme.borderSoft),
                                  ),
                                  child: Text(
                                    _whyThisVerse(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      height: 1.6,
                                      color: AppTheme.textTertiary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // ── ACTION BUTTONS ──
                              AnimatedOpacity(
                                opacity: _showActions ? 1.0 : 0.0,
                                duration:
                                    const Duration(milliseconds: 800),
                                child: Column(
                                  children: [
                                    // Top row: Save / Listen / 3 more
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _actionPill(
                                          icon: _isSaved
                                              ? Icons.favorite_rounded
                                              : Icons
                                                  .favorite_border_rounded,
                                          label:
                                              _isSaved ? 'Saved' : 'Save',
                                          onTap: _saveVerse,
                                        ),
                                        const SizedBox(width: 10),
                                        _actionPill(
                                          icon: Icons.volume_up_rounded,
                                          label: 'Listen',
                                          onTap: _listenAgain,
                                        ),
                                        const SizedBox(width: 10),
                                        if (_extraVersesLeft > 0)
                                          _actionPill(
                                            icon: Icons
                                                .auto_awesome_rounded,
                                            label:
                                                '$_extraVersesLeft more',
                                            onTap: _loadNextExtraVerse,
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Big "I am here" pill
                                    GestureDetector(
                                      onTap: _confirmExit,
                                      child: Container(
                                        width: double.infinity,
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.goldMid
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          border: Border.all(
                                            color: AppTheme.goldMid
                                                .withOpacity(0.4),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.goldMid
                                                  .withOpacity(0.1),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_rounded,
                                                color: AppTheme.goldMid,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'I am here',
                                              style: GoogleFonts.manrope(
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: AppTheme.goldMid,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // Small "not now" text
                                    GestureDetector(
                                      onTap: _snoozeGracefully,
                                      child: Text(
                                        'not now',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: AppTheme.textTertiary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Emergency — toned up
AnimatedOpacity(
  opacity: _showEmergency ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 600),
  child: GestureDetector(
    onTap: _showEmergencyDialog,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8080).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF8080).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded,
              size: 14,
              color: const Color(0xFFFF8080).withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(
            'Need to talk to someone?',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFFF8080).withOpacity(0.85),
            ),
          ),
        ],
      ),
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
    if (_words.isEmpty) return const SizedBox(height: 60);
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              transform:
                  Matrix4.translationValues(0, visible ? 0 : 8, 0),
              child: Text(
                _words[i],
                style: GoogleFonts.literata(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textPrimary,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgSlate,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
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
// FEEDBACK SHEET — animated icons (no emojis)
// ══════════════════════════════════════════════════════════════════
class _SacredFeedbackSheet extends StatefulWidget {
  final ValueChanged<String> onFeedback;
  const _SacredFeedbackSheet({required this.onFeedback});

  @override
  State<_SacredFeedbackSheet> createState() => _SacredFeedbackSheetState();
}

class _SacredFeedbackSheetState extends State<_SacredFeedbackSheet>
    with TickerProviderStateMixin {
  late AnimationController _iconAnim;

  @override
  void initState() {
    super.initState();
    _iconAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSlate,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.bgSlateGlow),
      ),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderSoft,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'How do you feel now?',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _iconAnim,
            builder: (_, __) {
              return Row(
                children: [
                  Expanded(
                    child: _feedbackTile(
                      'Better',
                      const Color(0xFF7DD69F),
                      CustomPaint(
                        size: const Size(40, 40),
                        painter: _FlowerPainter(t: _iconAnim.value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _feedbackTile(
                      'Same',
                      const Color(0xFF7BA9F0),
                      CustomPaint(
                        size: const Size(40, 40),
                        painter: _PulseCirclePainter(t: _iconAnim.value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _feedbackTile(
                      'Worse',
                      const Color(0xFFB8A0E8),
                      CustomPaint(
                        size: const Size(40, 40),
                        painter: _CandlePainter(t: _iconAnim.value),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _feedbackTile(String label, Color color, Widget icon) {
    return GestureDetector(
      onTap: () => widget.onFeedback(label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.manrope(
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
}

// ══════════════════════════════════════════════════════════════════
// FLOWER PAINTER — blooming petals (Better)
// ══════════════════════════════════════════════════════════════════
class _FlowerPainter extends CustomPainter {
  final double t;
  _FlowerPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalCount = 6;
    final bloomScale = 0.6 + t * 0.4;
    final petalLen = size.width * 0.28 * bloomScale;
    final petalWidth = size.width * 0.12 * bloomScale;

    for (int i = 0; i < petalCount; i++) {
      final angle = (i / petalCount) * 2 * pi + t * 0.3;
      final petalCenter = Offset(
        center.dx + cos(angle) * petalLen * 0.5,
        center.dy + sin(angle) * petalLen * 0.5,
      );

      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle + pi / 2);

      final path = Path();
      path.moveTo(0, -petalLen * 0.5);
      path.quadraticBezierTo(petalWidth, 0, 0, petalLen * 0.5);
      path.quadraticBezierTo(-petalWidth, 0, 0, -petalLen * 0.5);
      path.close();

      canvas.drawPath(
        path,
        Paint()..color = const Color(0xFF7DD69F).withOpacity(0.7),
      );
      canvas.restore();
    }

    // Center dot
    canvas.drawCircle(
        center, 3, Paint()..color = const Color(0xFFFFF8E5));
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════
// PULSE CIRCLE PAINTER — calm ripples (Same)
// ══════════════════════════════════════════════════════════════════
class _PulseCirclePainter extends CustomPainter {
  final double t;
  _PulseCirclePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.4;

    for (int i = 0; i < 3; i++) {
      final phase = (t + i * 0.33) % 1.0;
      final r = maxR * phase;
      final opacity = (1.0 - phase) * 0.6;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = const Color(0xFF7BA9F0).withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Center dot
    canvas.drawCircle(
      center,
      4,
      Paint()..color = const Color(0xFF7BA9F0).withOpacity(0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _PulseCirclePainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════
// CANDLE PAINTER — flickering flame (Worse)
// ══════════════════════════════════════════════════════════════════
class _CandlePainter extends CustomPainter {
  final double t;
  _CandlePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bottom = size.height * 0.85;

    // Candle body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 5, bottom - 18, 10, 18),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..color = const Color(0xFFF5F1EA).withOpacity(0.5),
    );

    // Wick
    canvas.drawLine(
      Offset(cx, bottom - 18),
      Offset(cx, bottom - 22),
      Paint()
        ..color = const Color(0xFF5A554D)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Flame — flickers
    final flameX = cx + sin(t * pi * 4) * 2;
    final flameY = bottom - 26;
    final flameH = 10 + sin(t * pi * 3) * 3;

    // Outer glow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(flameX, flameY - flameH * 0.3),
          width: 12,
          height: flameH + 6),
      Paint()
        ..color = const Color(0xFFB8A0E8).withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Flame body
    final flamePath = Path();
    flamePath.moveTo(flameX, flameY - flameH);
    flamePath.quadraticBezierTo(
        flameX + 5, flameY - flameH * 0.4, flameX, flameY);
    flamePath.quadraticBezierTo(
        flameX - 5, flameY - flameH * 0.4, flameX, flameY - flameH);
    flamePath.close();

    canvas.drawPath(
      flamePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFB8A0E8).withOpacity(0.9),
            const Color(0xFFE8CFFF).withOpacity(0.5),
          ],
        ).createShader(
            Rect.fromLTWH(flameX - 5, flameY - flameH, 10, flameH)),
    );

    // Inner bright core
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(flameX, flameY - 3), width: 3, height: 5),
      Paint()..color = Colors.white.withOpacity(0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════
// SACRED AURORA BACKGROUND
// ══════════════════════════════════════════════════════════════════
class _SacredAuroraPainter extends CustomPainter {
  final double t;
  _SacredAuroraPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = AppTheme.bgDeep);

    // Drifting slate mist
    canvas.drawCircle(
      Offset(size.width * (0.2 + sin(t * 0.3) * 0.1),
          size.height * (0.3 + cos(t * 0.25) * 0.08)),
      size.width * 0.6,
      Paint()
        ..color = const Color(0xFF1E293B).withOpacity(0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90),
    );

    canvas.drawCircle(
      Offset(size.width * (0.8 + cos(t * 0.2) * 0.1),
          size.height * (0.7 + sin(t * 0.3) * 0.08)),
      size.width * 0.55,
      Paint()
        ..color = const Color(0xFF2C3E5C).withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100),
    );

    // Gold accent glow
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * (0.4 + sin(t * 0.4) * 0.05)),
      size.width * 0.5,
      Paint()
        ..color = AppTheme.goldMid.withOpacity(0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
    );

    // Star field
    final rng = Random(42);
    for (int i = 0; i < 50; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final twinkle = 0.3 + sin(t * 0.8 + i * 1.7) * 0.3;
      canvas.drawCircle(
        Offset(x, y),
        0.7 + rng.nextDouble() * 0.4,
        Paint()..color = Colors.white.withOpacity(twinkle * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SacredAuroraPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════
// PARTICLE PAINTER — incense rising
// ══════════════════════════════════════════════════════════════════
class _SacredParticlePainter extends CustomPainter {
  final double t;
  _SacredParticlePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    for (int i = 0; i < 25; i++) {
      final x = rng.nextDouble() * size.width;
      final startY = size.height + rng.nextDouble() * 200;
      final rise = (t * 800 + i * 40) % (size.height + 200);
      final y = startY - rise;
      if (y < -20) continue;

      final drift = sin((t * 2 * pi) + i) * 20;
      final finalX = x + drift;

      double opacity = 1.0;
      if (y < 100) opacity = y / 100;
      if (y > size.height - 100) opacity = (size.height - y) / 100;
      opacity = opacity.clamp(0.0, 1.0) * 0.35;

      canvas.drawCircle(
        Offset(finalX, y),
        1.0 + rng.nextDouble() * 1.2,
        Paint()..color = AppTheme.goldMid.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SacredParticlePainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════
// SACRED ORB — liquid + cosmic + light rays
// ══════════════════════════════════════════════════════════════════
class _SacredOrbPainter extends CustomPainter {
  final double breath;
  final bool active;
  final double t;

  _SacredOrbPainter({
    required this.breath,
    required this.active,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * breath;

    // Outer soft glow
    canvas.drawCircle(
      center,
      radius * 1.2,
      Paint()
        ..color = AppTheme.goldMid.withOpacity(active ? 0.45 : 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, active ? 50 : 40),
    );

    // Main orb — single smooth radial gradient (no inner circles)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.0,
          colors: [
            const Color(0xFFFFF8E5),  // bright warm center-top
            const Color(0xFFF1D98A),  // mid gold
            const Color(0xFFD4B05C),  // warm amber
            const Color(0xFFB8923A),  // deep edge
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Soft surface texture — very faint craters
    final rng = Random(42);
    for (int i = 0; i < 5; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * radius * 0.6;
      final cx = center.dx + cos(angle) * dist;
      final cy = center.dy + sin(angle) * dist;
      final cr = radius * (0.06 + rng.nextDouble() * 0.08);
      canvas.drawCircle(
        Offset(cx, cy),
        cr,
        Paint()
          ..color = const Color(0xFFCDA44A).withOpacity(0.2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cr),
      );
    }

    // Thin bright rim at edge
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFFF8E5).withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _SacredOrbPainter old) =>
      old.breath != breath || old.active != active || old.t != t;
}

// ══════════════════════════════════════════════════════════════════
// CONSTELLATION PAINTER — dots + lines + learning message bg
// ══════════════════════════════════════════════════════════════════
class _ConstellationPainter extends CustomPainter {
  final double t;
  _ConstellationPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppTheme.bgDeep.withOpacity(0.92),
    );

    final center = Offset(size.width / 2, size.height / 2);
    final rng = Random(77);
    final dots = <Offset>[];

    // Generate 12 constellation dots
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi + 0.3;
      final dist = 80 + rng.nextDouble() * 60;
      dots.add(Offset(
        center.dx + cos(angle) * dist,
        center.dy + sin(angle) * dist - 20,
      ));
    }

    // Draw lines (appear progressively)
    final connections = [
      [0, 1], [1, 2], [2, 4], [4, 7], [7, 9], [9, 11], [11, 0],
      [3, 6], [5, 8], [6, 10],
    ];

    final lineProgress = (t * 2).clamp(0.0, 1.0);
    final visibleLines = (lineProgress * connections.length).floor();

    for (int i = 0; i < visibleLines && i < connections.length; i++) {
      final a = dots[connections[i][0]];
      final b = dots[connections[i][1]];
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = AppTheme.goldMid.withOpacity(0.25)
          ..strokeWidth = 0.8,
      );
    }

    // Draw dots (appear progressively)
    final dotProgress = (t * 1.5).clamp(0.0, 1.0);
    final visibleDots = (dotProgress * dots.length).floor();

    for (int i = 0; i < visibleDots && i < dots.length; i++) {
      // Glow
      canvas.drawCircle(
        dots[i],
        6,
        Paint()
          ..color = AppTheme.goldMid.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Dot
      canvas.drawCircle(
        dots[i],
        2.5,
        Paint()..color = AppTheme.goldMid.withOpacity(0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) => old.t != t;
}