import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../services/app_controller.dart';
import '../services/stats_service.dart';
import '../services/theme_service.dart';
import 'car_mode_screen.dart';
import 'dart:async';

class ZenAuroraBackground extends StatefulWidget {
  final Color baseColor;
  const ZenAuroraBackground({super.key, required this.baseColor});

  @override
  State<ZenAuroraBackground> createState() => _ZenAuroraBackgroundState();
}

class _ZenAuroraBackgroundState extends State<ZenAuroraBackground>
    with TickerProviderStateMixin {
  late AnimationController _c1, _c2, _c3;

  @override
  void initState() {
    super.initState();
    _c1 = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _c2 = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat(reverse: true);
    _c3 = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c1, _c2, _c3]),
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor.withOpacity(0.85),
                widget.baseColor.withOpacity(0.6),
                Colors.white.withOpacity(0.4),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 40 + 60 * _c1.value,
                top: 80 + 40 * _c2.value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
              ),
              Positioned(
                right: 20 + 50 * _c2.value,
                top: 200 + 60 * _c3.value,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.13),
                  ),
                ),
              ),
              Positioned(
                left: 80 + 40 * _c3.value,
                bottom: 100 + 50 * _c1.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScriptureFeedScreen extends StatefulWidget {
  const ScriptureFeedScreen({super.key});

  @override
  State<ScriptureFeedScreen> createState() => _ScriptureFeedScreenState();
}

class _ScriptureFeedScreenState extends State<ScriptureFeedScreen>
    with TickerProviderStateMixin {
  String _selectedTheme = 'PEACE';
  String _selectedTimer = '5 MIN';
  bool _loading = false;

  late AnimationController _iconSway;
  late AnimationController _btnPulse;

  final List<String> _themes = [
    'PEACE',
    'HOPE',
    'REST',
    'GRATITUDE',
    'STRENGTH'
  ];
  final List<String> _timers = ['2 MIN', '5 MIN', '10 MIN', 'FREE'];

  @override
  void initState() {
    super.initState();
    _iconSway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _btnPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconSway.dispose();
    _btnPulse.dispose();
    super.dispose();
  }

  Color get _baseColor => ThemeService.getEmotionColor();

  int _timerToSeconds(String t) {
    switch (t) {
      case '2 MIN':
        return 120;
      case '5 MIN':
        return 300;
      case '10 MIN':
        return 600;
      default:
        return 0;
    }
  }

  Future<void> _beginSession() async {
    setState(() => _loading = true);

    final timerSeconds = _timerToSeconds(_selectedTimer);

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _ZenSessionPage(
          theme: _selectedTheme,
          totalSeconds: timerSeconds,
          isFreeMode: _selectedTimer == 'FREE',
        ),
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _baseColor;

    return Scaffold(
      backgroundColor: color,
      body: Stack(
        children: [
          Positioned.fill(child: ZenAuroraBackground(baseColor: color)),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    AnimatedBuilder(
                      animation: _iconSway,
                      builder: (_, __) {
                        final sway = sin(_iconSway.value * pi) * 0.08;
                        return Transform.rotate(
                          angle: sway,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.25),
                            ),
                            child: const Icon(
                              Icons.spa_rounded,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    Text(
                      'Zen Mode',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Let Scripture find you.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 50),

                    _buildSectionLabel('Choose a theme'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _themes.map(_themeChip).toList(),
                    ),

                    const SizedBox(height: 40),

                    _buildSectionLabel('Session length'),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _timers.map(_timerChip).toList(),
                    ),

                    const SizedBox(height: 50),

                    AnimatedBuilder(
                      animation: _btnPulse,
                      builder: (_, __) {
                        final glow = 8.0 + 12.0 * _btnPulse.value;
                        return GestureDetector(
                          onTap: _loading ? null : _beginSession,
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.55),
                                  blurRadius: glow,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Begin Session',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Car Mode — highlighted pill
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CarModeScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions_car_rounded,
                              size: 20,
                              color: Colors.white,
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(
                                    duration: 2000.ms, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Switch to Car Mode',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.05, 1.05),
                          duration: 1800.ms,
                        ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.7),
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _themeChip(String theme) {
    final selected = _selectedTheme == theme;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(selected ? 0.0 : 0.35),
            width: 1,
          ),
        ),
        child: Text(
          theme,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? _baseColor : Colors.white,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _timerChip(String timer) {
    final selected = _selectedTimer == timer;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimer = timer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(selected ? 0.0 : 0.35),
            width: 1,
          ),
        ),
        child: Text(
          timer,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? _baseColor : Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ZenSessionPage extends StatefulWidget {
  final String theme;
  final int totalSeconds;
  final bool isFreeMode;

  const _ZenSessionPage({
    required this.theme,
    required this.totalSeconds,
    required this.isFreeMode,
  });

  @override
  State<_ZenSessionPage> createState() => _ZenSessionPageState();
}

class _ZenSessionPageState extends State<_ZenSessionPage>
    with TickerProviderStateMixin {
  String _verseText = '';
  String _verseRef = '';

  String _nextVerseText = '';
  String _nextVerseRef = '';
  bool _preloading = false;

  List<String> _words = [];
  int _revealedWords = 0;
  bool _verseFullyRevealed = false;
  int _resonanceCount = 142;

  int _sessionSeconds = 0;

  double _dragOffset = 0;
  bool _actionTriggered = false;
  bool _showHeartBurst = false;

  late AnimationController _heartBurstController;
  Timer? _sessionTimer;

  // Lower threshold + velocity detection = super responsive swipe
  static const double _swipeThreshold = 60;
  static const double _swipeVelocityThreshold = 300;

  @override
  void initState() {
    super.initState();
    _heartBurstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _initSession();
  }

  Future<void> _initSession() async {
    await _loadVerse(isFirst: true);
    if (!widget.isFreeMode) {
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _sessionSeconds++);
        if (_sessionSeconds >= widget.totalSeconds) {
          _closeSession();
        }
      });
    }
    _preloadNextVerse();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _heartBurstController.dispose();
    TtsService.stop();
    super.dispose();
  }

  Color get _baseColor => ThemeService.getEmotionColor();

  Future<void> _preloadNextVerse() async {
    if (_preloading) return;
    _preloading = true;
    try {
      final result = await ApiService.getZenVerse(
        theme: widget.theme.toLowerCase(),
        emotion: AppController().currentEmotion,
      );
      _nextVerseText =
          result['verse'] ?? 'The Lord is my shepherd, I lack nothing.';
      _nextVerseRef = result['ref'] ?? 'Psalm 23:1';
    } catch (e) {
      _nextVerseText = 'The Lord is my shepherd, I lack nothing.';
      _nextVerseRef = 'Psalm 23:1';
    }
    _preloading = false;
  }

  Future<void> _loadVerse({bool isFirst = false}) async {
    TtsService.stop();

    String verseText;
    String verseRef;

    if (!isFirst && _nextVerseText.isNotEmpty) {
      verseText = _nextVerseText;
      verseRef = _nextVerseRef;
      _nextVerseText = '';
      _nextVerseRef = '';
    } else {
      try {
        final result = await ApiService.getZenVerse(
          theme: widget.theme.toLowerCase(),
          emotion: AppController().currentEmotion,
        );
        verseText = result['verse'] ?? 'Be still and know that I am God.';
        verseRef = result['ref'] ?? 'Psalm 46:10';
      } catch (e) {
        verseText = 'Be still and know that I am God.';
        verseRef = 'Psalm 46:10';
      }
    }

    setState(() {
      _verseText = verseText;
      _verseRef = verseRef;
      _words = [];
      _revealedWords = 0;
      _verseFullyRevealed = false;
      _dragOffset = 0;
      _actionTriggered = false;
    });

    StatsService.recordVerse(verseText, verseRef);
    _preloadNextVerse();
    _startWordReveal(verseText);
  }

  void _startWordReveal(String verse) {
    _words = verse.split(' ');
    _revealedWords = 0;
    _verseFullyRevealed = false;

    TtsService.speakSynced(verse, 0.35);

    void revealNext() {
      if (!mounted) return;
      if (_revealedWords < _words.length) {
        setState(() => _revealedWords++);
        Future.delayed(const Duration(milliseconds: 320), revealNext);
      } else {
        setState(() {
          _verseFullyRevealed = true;
          _resonanceCount = 140 + Random().nextInt(40);
        });
      }
    }

    revealNext();
  }

  void _onDragStart(DragStartDetails details) {
    if (_actionTriggered) return;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_actionTriggered) return;
    setState(() {
      _dragOffset += details.delta.dx;
      if (_dragOffset > _swipeThreshold) {
        _dragOffset = _swipeThreshold + (_dragOffset - _swipeThreshold) * 0.25;
      } else if (_dragOffset < -_swipeThreshold) {
        _dragOffset =
            -_swipeThreshold + (_dragOffset + _swipeThreshold) * 0.25;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) async {
    if (_actionTriggered) return;

    final velocity = details.primaryVelocity ?? 0;

    final isFlickRight = velocity > _swipeVelocityThreshold;
    final isFlickLeft = velocity < -_swipeVelocityThreshold;
    final isDraggedRight = _dragOffset > _swipeThreshold;
    final isDraggedLeft = _dragOffset < -_swipeThreshold;

    if (isFlickRight || isDraggedRight) {
      setState(() => _actionTriggered = true);
      await _animateSwipeOut(toRight: true);
      await _saveAndNext();
    } else if (isFlickLeft || isDraggedLeft) {
      setState(() => _actionTriggered = true);
      await _animateSwipeOut(toRight: false);
      await _loadVerse();
    } else {
      _snapBack();
    }
  }

  Future<void> _animateSwipeOut({required bool toRight}) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final target = toRight ? screenWidth * 1.5 : -screenWidth * 1.5;
    const duration = Duration(milliseconds: 280);
    final startOffset = _dragOffset;
    final startTime = DateTime.now();

    await Future.doWhile(() async {
      if (!mounted) return false;
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final t = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
      final curve = Curves.easeOut.transform(t);
      setState(() =>
          _dragOffset = startOffset + (target - startOffset) * curve);
      if (t >= 1.0) return false;
      await Future.delayed(const Duration(milliseconds: 16));
      return true;
    });
  }

  void _snapBack() {
    final startOffset = _dragOffset;
    final startTime = DateTime.now();
    const duration = Duration(milliseconds: 300);

    Future.doWhile(() async {
      if (!mounted) return false;
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final t = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
      final curve = Curves.elasticOut.transform(t);
      setState(() => _dragOffset = startOffset * (1 - curve));
      if (t >= 1.0) {
        setState(() => _dragOffset = 0);
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 16));
      return true;
    });
  }

  Future<void> _saveAndNext() async {
    setState(() => _showHeartBurst = true);
    _heartBurstController.forward(from: 0);
    StatsService.saveVerse(_verseText, _verseRef);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _showHeartBurst = false);
    await _loadVerse();
  }

  void _closeSession() {
    TtsService.stop();
    _sessionTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = _baseColor;
    final progress = widget.isFreeMode
        ? 0.0
        : (_sessionSeconds / widget.totalSeconds).clamp(0.0, 1.0);

    final swipeProgress = (_dragOffset / _swipeThreshold).clamp(-1.0, 1.0);
    final cardRotation = swipeProgress * 0.06;
    final cardOpacity = (1.0 - swipeProgress.abs() * 0.15).clamp(0.0, 1.0);
    final heartOpacity = (swipeProgress).clamp(0.0, 1.0);
    final skipOpacity = (-swipeProgress).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: color,
      body: Stack(
        children: [
          Positioned.fill(child: ZenAuroraBackground(baseColor: color)),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor:
                  AlwaysStoppedAnimation(Colors.white.withOpacity(0.85)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.theme,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 2,
                        ),
                      ),
                      GestureDetector(
                        onTap: _closeSession,
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Opacity(
                            opacity: skipOpacity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.skip_next_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 40,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Skip',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Opacity(
                            opacity: heartOpacity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Save',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Center(
                        child: GestureDetector(
                          onHorizontalDragStart: _onDragStart,
                          onHorizontalDragUpdate: _onDragUpdate,
                          onHorizontalDragEnd: _onDragEnd,
                          child: Transform.translate(
                            offset: Offset(_dragOffset, 0),
                            child: Transform.rotate(
                              angle: cardRotation,
                              child: Opacity(
                                opacity: cardOpacity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildWordReveal(),

                                      const SizedBox(height: 32),

                                      if (_verseFullyRevealed &&
                                          _verseRef.isNotEmpty)
                                        Text(
                                          '— $_verseRef',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color:
                                                Colors.white.withOpacity(0.65),
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        )
                                            .animate()
                                            .fadeIn(duration: 600.ms),

                                      const SizedBox(height: 48),

                                      if (_verseFullyRevealed)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.favorite_rounded,
                                              size: 14,
                                              color: Colors.white
                                                  .withOpacity(0.6),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$_resonanceCount souls resonating',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        )
                                            .animate()
                                            .fadeIn(duration: 800.ms),

                                      const SizedBox(height: 24),

                                      // Highlighted swipe hint pill
                                      if (_verseFullyRevealed &&
                                          _dragOffset == 0 &&
                                          !_actionTriggered)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.4),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.arrow_back_rounded,
                                                size: 14,
                                                color: Colors.white
                                                    .withOpacity(0.85),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'skip',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              Container(
                                                width: 1,
                                                height: 12,
                                                margin: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 12),
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                              ),
                                              Text(
                                                'save',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 14,
                                                color: Colors.white
                                                    .withOpacity(0.85),
                                              ),
                                            ],
                                          ),
                                        )
                                            .animate(
                                                onPlay: (c) =>
                                                    c.repeat(reverse: true))
                                            .scale(
                                              begin: const Offset(1.0, 1.0),
                                              end: const Offset(1.06, 1.06),
                                              duration: 1500.ms,
                                            )
                                            .animate()
                                            .fadeIn(
                                                delay: 800.ms,
                                                duration: 600.ms),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_showHeartBurst)
                        Center(
                          child: AnimatedBuilder(
                            animation: _heartBurstController,
                            builder: (_, __) {
                              return Transform.scale(
                                scale:
                                    0.5 + _heartBurstController.value * 1.5,
                                child: Opacity(
                                  opacity:
                                      (1.0 - _heartBurstController.value)
                                          .clamp(0.0, 1.0),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 80,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordReveal() {
    if (_words.isEmpty) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 5,
      runSpacing: 8,
      children: List.generate(_words.length, (i) {
        final visible = i < _revealedWords;
        return AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Text(
            _words[i],
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        );
      }),
    );
  }
}