import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../services/tts_service.dart';
import '../services/theme_service.dart';

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

  // Word-by-word reveal
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

    // Start word-by-word reveal
    _words = _currentVerse.split(' ');
    _revealedWords = 0;
    setState(() {});

    void revealNext() {
      if (!mounted) return;
      if (_revealedWords < _words.length) {
        setState(() => _revealedWords++);
        Future.delayed(const Duration(milliseconds: 280), revealNext);
      }
    }

    revealNext();

    // TTS speaks verse only
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
      );
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
      body: Stack(
        children: [
          CarAuroraBackground(
              controller: _auroraController,
              emotionColor: emotionColor),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              color: Colors.black.withOpacity(0.06),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [emotionColor, const Color(0xFF0F0F0F)]),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CAR MODE',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color:
                                  const Color(0xFF0F0F0F).withOpacity(0.5))),
                      GestureDetector(
                        onTap: _exitCarMode,
                        child: Icon(Icons.close_rounded,
                            color: const Color(0xFF0F0F0F).withOpacity(0.6),
                            size: 22),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

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
                            const Color(0xFFFFD700).withOpacity(0.3 * glow),
                            Colors.transparent
                          ]),
                        ),
                        child: CustomPaint(
                          size: const Size(60, 60),
                          painter: CarStarPainter(glow: glow),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  AnimatedOpacity(
                    opacity: _contentOpacity,
                    duration: const Duration(milliseconds: 16),
                    child: Column(
                      children: [
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
                              ),

                        const SizedBox(height: 16),

                        AnimatedOpacity(
                          opacity: _isNarrating ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 800),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              _currentNarration,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                height: 1.7,
                                color: Colors.white.withOpacity(0.92),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  AnimatedOpacity(
                    opacity: _isNarrating ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _isNarrating ? 'Lumíne is speaking' : 'Lumíne is with you',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CarStarPainter extends CustomPainter {
  final double glow;
  CarStarPainter({required this.glow});

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

    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.5 + glow * 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + glow * 6);
    canvas.drawPath(path, glowPaint);

    final corePaint = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFF8DC).withOpacity(0.9),
        const Color(0xFFFFD700).withOpacity(0.4),
        Colors.transparent
      ]).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawPath(path, corePaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF0F0F0F).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CarStarPainter oldDelegate) =>
      oldDelegate.glow != glow;
}
class CarAuroraBackground extends StatelessWidget {
  final AnimationController controller;
  final Color emotionColor;

  const CarAuroraBackground(
      {super.key, required this.controller, required this.emotionColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value * 2 * pi;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 1200),
          color: emotionColor,
          child: Stack(
            children: [
              Positioned(
                top: -50 + sin(t) * 80,
                left: -100 + cos(t) * 100,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Colors.white.withOpacity(0.35),
                      Colors.transparent
                    ]),
                  ),
                ),
              ),
              Positioned(
                top: 200 + cos(t + 1) * 100,
                right: -80 + sin(t + 1) * 80,
                child: Container(
                  width: 480,
                  height: 480,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.transparent
                    ]),
                  ),
                ),
              ),
              Positioned(
                bottom: -80 + cos(t + 3) * 70,
                left: -50 + sin(t + 3) * 80,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Colors.white.withOpacity(0.20),
                      Colors.transparent
                    ]),
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ],
          ),
        );
      },
    );
  }
}