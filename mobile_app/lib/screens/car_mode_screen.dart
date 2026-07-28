import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../services/tts_service.dart';
import '../services/theme_service.dart';
import '../services/app_theme.dart';

class CarModeScreen extends StatefulWidget {
  const CarModeScreen({super.key});

  @override
  State<CarModeScreen> createState() => _CarModeScreenState();
}

class _CarModeScreenState extends State<CarModeScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  bool _isNarrating = false;
  String _currentVerse = '';
  String _currentRef = '';
  String _currentNarration = '';

  List<String> _words = [];
  int _revealedWords = 0;
  int _verseIndex = 0;
  int _elapsedSeconds = 0;
  Timer? _progressTimer;

  String _nextVerse = '';
  String _nextRef = '';
  String _nextNarration = '';
  bool _preloading = false;

  double _contentOpacity = 1.0;

  late AnimationController _auroraController;
  late AnimationController _starGlowController;
  late AnimationController _particleController;

  final List<Map<String, String>> _verses = [
    {'text': 'Be still, and know that I am God.', 'ref': 'Psalm 46:10'},
    {'text': 'Come to me, all you who are weary and burdened, and I will give you rest.', 'ref': 'Matthew 11:28'},
    {'text': 'Peace I leave with you; my peace I give you.', 'ref': 'John 14:27'},
    {'text': 'Cast all your anxiety on him because he cares for you.', 'ref': '1 Peter 5:7'},
    {'text': 'The Lord is my shepherd, I lack nothing.', 'ref': 'Psalm 23:1'},
    {'text': 'When anxiety was great within me, your consolation brought me joy.', 'ref': 'Psalm 94:19'},
    {'text': 'He heals the brokenhearted and binds up their wounds.', 'ref': 'Psalm 147:3'},
    {'text': 'The Lord is close to the brokenhearted and saves those who are crushed in spirit.', 'ref': 'Psalm 34:18'},
    {'text': 'I can do all this through him who gives me strength.', 'ref': 'Philippians 4:13'},
    {'text': 'For I know the plans I have for you, declares the Lord.', 'ref': 'Jeremiah 29:11'},
    {'text': 'You will keep in perfect peace those whose minds are steadfast.', 'ref': 'Isaiah 26:3'},
    {'text': 'The Lord gives strength to his people; the Lord blesses his people with peace.', 'ref': 'Psalm 29:11'},
    {'text': 'Those who hope in the Lord will renew their strength.', 'ref': 'Isaiah 40:31'},
    {'text': 'My grace is sufficient for you, for my power is made perfect in weakness.', 'ref': '2 Corinthians 12:9'},
    {'text': 'Give thanks to the Lord, for he is good. His love endures forever.', 'ref': 'Psalm 136:1'},
  ];

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
    _starGlowController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _particleController = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    _verses.shuffle();
    _startCarMode();
  }

  void _startCarMode() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.15);
      await _audioPlayer.play(AssetSource('audio/ambient.mp3'));
    } catch (e) {}

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    await _loadFirstVerse();
  }

  Future<void> _loadFirstVerse() async {
    final verse = _verses[_verseIndex % _verses.length];
    final narration = await _fetchNarration(verse['text']!, verse['ref']!);

    if (!mounted) return;
    setState(() {
      _currentVerse = verse['text']!;
      _currentRef = verse['ref']!;
      _currentNarration = narration;
    });

    _preloadNext();
    _playCurrentVerse();
  }

  Future<void> _preloadNext() async {
    if (_preloading) return;
    _preloading = true;
    final nextIndex = (_verseIndex + 1) % _verses.length;
    final verse = _verses[nextIndex];
    final narration = await _fetchNarration(verse['text']!, verse['ref']!);
    _nextVerse = verse['text']!;
    _nextRef = verse['ref']!;
    _nextNarration = narration;
    _preloading = false;
  }

  void _playCurrentVerse() async {
    if (!mounted) return;

    _words = _currentVerse.split(' ');
    _revealedWords = 0;
    setState(() {});

    void revealNext() {
      if (!mounted) return;
      if (_revealedWords < _words.length) {
        setState(() => _revealedWords++);
        Future.delayed(const Duration(milliseconds: 199), revealNext);
      }
    }

    revealNext();

    Completer<void> verseComplete = Completer<void>();
    TtsService.speakWithCallback(_currentVerse, 0.35, () {
      if (!verseComplete.isCompleted) verseComplete.complete();
    });
    await verseComplete.future;

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _isNarrating = true);

    Completer<void> narrationComplete = Completer<void>();
    TtsService.speakWithCallback(_currentNarration, 0.32, () {
      if (!narrationComplete.isCompleted) narrationComplete.complete();
    });
    await narrationComplete.future;

    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    await _crossfadeToNext();
  }

  Future<void> _crossfadeToNext() async {
    if (!mounted) return;

    const fadeDuration = Duration(milliseconds: 600);
    final startTime = DateTime.now();

    await Future.doWhile(() async {
      if (!mounted) return false;
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final t = (elapsed / fadeDuration.inMilliseconds).clamp(0.0, 1.0);
      setState(() => _contentOpacity = 1.0 - t);
      if (t >= 1.0) return false;
      await Future.delayed(const Duration(milliseconds: 16));
      return true;
    });

    if (!mounted) return;

    int wait = 0;
    while (_preloading && wait < 5000) {
      await Future.delayed(const Duration(milliseconds: 100));
      wait += 100;
    }

    _verseIndex++;
    setState(() {
      _currentVerse = _nextVerse.isNotEmpty
          ? _nextVerse
          : _verses[_verseIndex % _verses.length]['text']!;
      _currentRef = _nextRef.isNotEmpty
          ? _nextRef
          : _verses[_verseIndex % _verses.length]['ref']!;
      _currentNarration = _nextNarration;
      _isNarrating = false;
      _nextVerse = '';
      _nextRef = '';
      _nextNarration = '';
      _words = [];
      _revealedWords = 0;
    });

    _preloadNext();

    final fadeInStart = DateTime.now();
    await Future.doWhile(() async {
      if (!mounted) return false;
      final elapsed = DateTime.now().difference(fadeInStart).inMilliseconds;
      final t = (elapsed / fadeDuration.inMilliseconds).clamp(0.0, 1.0);
      setState(() => _contentOpacity = t);
      if (t >= 1.0) return false;
      await Future.delayed(const Duration(milliseconds: 16));
      return true;
    });

    if (!mounted) return;
    _playCurrentVerse();
  }

  Future<String> _fetchNarration(String verseText, String verseRef) async {
    try {
      final response = await http.post(
        Uri.parse('https://lumine-backend-420v.onrender.com/zen'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'verse': verseText,
          'ref': verseRef,
          'emotion': 'calm',
          'used_refs': [],
        }),
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String narration = data['narration'] ?? '';
        narration = narration.replaceAll(RegExp(r'[#*_~`>]'), '');
        narration = narration.replaceAll(RegExp(r'\n+'), ' ');
        return narration.trim().isNotEmpty
            ? narration.trim()
            : _fallbackNarration();
      }
    } catch (_) {}
    return _fallbackNarration();
  }

  String _fallbackNarration() {
    final fallbacks = [
      'This was written in a moment of real human struggle, preserved so it could find you here. You are not carrying this alone.',
      'These words crossed centuries of silence to reach you in this exact moment. Something in them was made for right now.',
      'This came from someone who had run out of answers and found something deeper than answers. That same thing is available to you.',
      'Written at the edge of what felt possible — and yet the person kept going. So will you.',
      'This was not written for the comfortable. It was written for someone exactly where you are right now.',
    ];
    return fallbacks[_random.nextInt(fallbacks.length)];
  }

  void _exitCarMode() {
    _audioPlayer.stop();
    _progressTimer?.cancel();
    TtsService.stop();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _starGlowController.dispose();
    _particleController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _progressTimer?.cancel();
    TtsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emotionColor = ThemeService.getEmotionColor();
    final progress = (_elapsedSeconds / 300).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          // Dark cosmic background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _auroraController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _CarDarkBgPainter(
                    t: _auroraController.value * 2 * pi,
                    emotionColor: emotionColor,
                  ),
                );
              },
            ),
          ),

          // Rising gold particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _CarParticlesPainter(
                    t: _particleController.value,
                  ),
                );
              },
            ),
          ),

          // Gold progress bar at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              color: Colors.black.withOpacity(0.3),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.goldMid.withOpacity(0.8),
                        emotionColor.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CAR MODE',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _exitCarMode,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.bgSlate,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.borderSoft),
                          ),
                          child: Icon(Icons.close_rounded,
                              color: AppTheme.textSecondary, size: 18),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Gold star
                  AnimatedBuilder(
                    animation: _starGlowController,
                    builder: (context, child) {
                      final glow = _starGlowController.value;
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            AppTheme.goldMid.withOpacity(0.25 * glow),
                            Colors.transparent,
                          ]),
                        ),
                        child: CustomPaint(
                          size: const Size(60, 60),
                          painter: _CarStarPainter(glow: glow),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Verse reference
                  AnimatedOpacity(
                    opacity: _currentRef.isNotEmpty ? 0.6 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _currentRef,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.goldMid,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Verse word-by-word + narration
                  AnimatedOpacity(
                    opacity: _contentOpacity,
                    duration: const Duration(milliseconds: 16),
                    child: Column(
                      children: [
                        // Word-by-word verse
                        _words.isEmpty
                            ? const SizedBox(height: 40)
                            : Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 5,
                                runSpacing: 8,
                                children: List.generate(_words.length, (i) {
                                  final visible = i < _revealedWords;
                                  return AnimatedOpacity(
                                    opacity: visible ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      transform: Matrix4.translationValues(
                                          0, visible ? 0 : 8, 0),
                                      child: Text(
                                        _words[i],
                                        style: GoogleFonts.literata(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w400,
                                          color: AppTheme.textPrimary,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),

                        const SizedBox(height: 20),

                        // Narration box
                        AnimatedOpacity(
                          opacity: _isNarrating ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 800),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSlate,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppTheme.goldMid.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldMid.withOpacity(0.06),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              _currentNarration,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.literata(
                                fontSize: 14,
                                height: 1.7,
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Status label
                  AnimatedOpacity(
                    opacity: _isNarrating ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 500),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _starGlowController,
                          builder: (_, __) {
                            return Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.goldMid.withOpacity(
                                    0.5 + _starGlowController.value * 0.5),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isNarrating ? 'Lumíne is speaking' : 'Lumíne is with you',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// DARK COSMIC BACKGROUND — emotion aura + drifting clouds
// ══════════════════════════════════════════════════════════════════
class _CarDarkBgPainter extends CustomPainter {
  final double t;
  final Color emotionColor;

  _CarDarkBgPainter({required this.t, required this.emotionColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep midnight base
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0F1214),
    );

    // Emotion aura — left side
    canvas.drawCircle(
      Offset(-size.width * 0.15 + sin(t * 0.3) * 30,
          size.height * 0.35 + cos(t * 0.2) * 40),
      size.width * 0.7,
      Paint()
        ..shader = RadialGradient(
          colors: [
            emotionColor.withOpacity(0.12),
            emotionColor.withOpacity(0.04),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(-size.width * 0.15, size.height * 0.35),
          radius: size.width * 0.7,
        )),
    );

    // Emotion aura — right side
    canvas.drawCircle(
      Offset(size.width * 1.1 + cos(t * 0.25) * 25,
          size.height * 0.6 + sin(t * 0.3) * 35),
      size.width * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            emotionColor.withOpacity(0.08),
            emotionColor.withOpacity(0.02),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 1.1, size.height * 0.6),
          radius: size.width * 0.6,
        )),
    );

    // Gold vignette top
    canvas.drawCircle(
      Offset(size.width * 0.5, -size.height * 0.1),
      size.width * 0.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF1D98A).withOpacity(0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, -size.height * 0.1),
          radius: size.width * 0.8,
        )),
    );

    // Star field
    final rng = Random(42);
    final starPaint = Paint();
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final twinkle = 0.3 + sin(t * 0.8 + i * 1.7) * 0.3;
      starPaint.color = Colors.white.withOpacity(twinkle * 0.6);
      canvas.drawCircle(Offset(x, y), 0.8 + rng.nextDouble() * 0.5, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CarDarkBgPainter old) =>
      old.t != t || old.emotionColor != emotionColor;
}

// ══════════════════════════════════════════════════════════════════
// RISING GOLD PARTICLES
// ══════════════════════════════════════════════════════════════════
class _CarParticlesPainter extends CustomPainter {
  final double t;
  _CarParticlesPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(77);
    final paint = Paint();

    for (int i = 0; i < 25; i++) {
      final baseX = rng.nextDouble() * size.width;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * 2 * pi;
      final particleSize = 1.0 + rng.nextDouble() * 1.5;

      final y = size.height - ((t * speed + phase / (2 * pi)) % 1.0) * (size.height + 40);
      final x = baseX + sin(t * 2 * pi * 0.3 + phase) * 15;
      final alpha = 0.15 + sin(t * 2 * pi + phase) * 0.1;

      paint.color = const Color(0xFFF1D98A).withOpacity(alpha.clamp(0.05, 0.3));
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CarParticlesPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════
// GOLD STAR — same 4-point star, dark-theme optimized
// ══════════════════════════════════════════════════════════════════
class _CarStarPainter extends CustomPainter {
  final double glow;
  _CarStarPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.48;
    final waist = size.width * 0.02;

    final path = Path();
    path.moveTo(center.dx, center.dy - outerRadius);
    path.quadraticBezierTo(
        center.dx + waist, center.dy - waist, center.dx + outerRadius, center.dy);
    path.quadraticBezierTo(
        center.dx + waist, center.dy + waist, center.dx, center.dy + outerRadius);
    path.quadraticBezierTo(
        center.dx - waist, center.dy + waist, center.dx - outerRadius, center.dy);
    path.quadraticBezierTo(
        center.dx - waist, center.dy - waist, center.dx, center.dy - outerRadius);
    path.close();

    // Outer glow
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF1D98A).withOpacity(0.3 + glow * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + glow * 8),
    );

    // Core
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFF8E5).withOpacity(0.95),
          const Color(0xFFF1D98A).withOpacity(0.5),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: center, radius: outerRadius)),
    );

    // Subtle border
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF1D98A).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _CarStarPainter old) => old.glow != glow;
}