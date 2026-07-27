import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_controller.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import 'sacred_interruption_screen.dart';
import '../services/tts_service.dart';
import '../services/stats_service.dart';
import '../services/theme_service.dart';
import '../services/memory_service.dart';
import '../widgets/glow_orb.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _keyboardFocus = FocusNode();
  final VoiceService _voiceService = VoiceService();

  String? _lastUserMessage;
  String? _lumineReply;
  List<Map<String, String>> _chatHistory = [];
  Map<String, dynamic> _memoryProfile = {};

  String _livePartial = '';
  bool _isLoading = false;
  bool _isListeningNow = false;
  bool _isSpeaking = false;
  bool _showKeyboard = false;
    bool _hasStartedChat = false;

  late AnimationController _bgController;
  late AnimationController _userPillController;
  late AnimationController _lumineReplyController;

  String get _statusLine {
    if (_isLoading) return 'Reflecting..';
    if (_isSpeaking) return 'Speaking..';
    if (_isListeningNow) return 'Listening..';
    return 'Shared presence';
  }

    String _greetingText() {
    final hour = DateTime.now().hour;
    const name = "Naren";
    if (hour < 12) return "Good morning, $name.\nHow are you feeling?";
    if (hour < 17) return "Hey $name.\nWhat's on your mind?";
    if (hour < 21) return "Good evening, $name.\nHow was your day?";
    return "Peaceful night, $name.\nHow are you doing?";
  }

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _userPillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _lumineReplyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    _keyboardFocus.addListener(() {
      if (!_keyboardFocus.hasFocus && _showKeyboard) {
        setState(() => _showKeyboard = false);
      }
      AppController().setKeyboardActive(_keyboardFocus.hasFocus || _showKeyboard);
    });

    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final history = await MemoryService.loadChatHistory();
    final profile = await MemoryService.loadMemoryProfile();
    if (mounted) {
      setState(() {
        _chatHistory = history;
        _memoryProfile = profile;
      });
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _userPillController.dispose();
    _lumineReplyController.dispose();
    _controller.dispose();
    _keyboardFocus.dispose();
    _voiceService.stopListening();
    TtsService.stop();
    super.dispose();
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final userMessage = (overrideText ?? _controller.text).trim();
    if (userMessage.isEmpty || _isLoading) return;

    _keyboardFocus.unfocus();
    setState(() {
      _showKeyboard = false;
      _lastUserMessage = userMessage;
      _livePartial = '';
      _lumineReply = null;
      _isLoading = true;
      _isListeningNow = false;
      _isSpeaking = false;
     _hasStartedChat = true;
    });
    _userPillController.forward(from: 0);
    _controller.clear();

    try {
      final now = DateTime.now();
      final hour = now.hour;
      String timeOfDay;
      if (hour < 12) {
        timeOfDay = 'morning';
      } else if (hour < 17) {
        timeOfDay = 'afternoon';
      } else if (hour < 21) {
        timeOfDay = 'evening';
      } else {
        timeOfDay = 'night';
      }

      final appContext = {
        'current_emotion': AppController().currentEmotion,
        'time_of_day': timeOfDay,
        'anchor_verse': StatsService.getAnchorVerse(),
        'spiritual_fingerprint': StatsService.glooFingerprint,
        'days_active': StatsService.streakDays,
        'pattern': StatsService.getTimeOfDayPattern(),
        'stress_spikes': StatsService.getStressSpikesToday(),
      };

      final lastReplies = await MemoryService.loadLastReplies();

      final result = await ApiService.analyzeMessage(
        userMessage,
        recentHistory: _chatHistory,
        memoryProfile: _memoryProfile,
        appContext: appContext,
        lastReplies: lastReplies,
      );

      final emotion = result['emotion'] ?? 'neutral';
      final response = result['response'] ?? 'I am here with you.';
      final isCrisis = result['crisis'] == true;

      AppController().updateEmotion(emotion);
      StatsService.recordEmotion(emotion);

      await MemoryService.appendMessage(userMessage, response);
      await MemoryService.pushLastReply(response);
      _chatHistory.add({'user': userMessage, 'lumine': response});

      if (!mounted) return;
      setState(() {
        _lumineReply = response;
        _isLoading = false;
        _isSpeaking = true;
      });
      _lumineReplyController.forward(from: 0);

      await TtsService.speakWithCallback(response, 0.4, () {
        if (mounted) setState(() => _isSpeaking = false);
      });

      if (_chatHistory.length % 20 == 0) {
        _runBackgroundSummary();
      }

      if (isCrisis) return;

      final controller = AppController();
      if (controller.anxiety >= 0.3 || controller.reactivity >= 0.3) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        final scripture = result['scripture'];
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SacredInterruptionScreen(
              scriptureText:
                  scripture?['text'] ?? 'Be still, and know that I am God.',
              scriptureRef: scripture?['reference'] ?? 'Psalm 46:10',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _lumineReply = 'Connection error. Try again in a moment.';
          _isLoading = false;
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _runBackgroundSummary() async {
    try {
      final updated = await ApiService.summarizeMemory(
        chatHistory: _chatHistory,
        currentProfile: _memoryProfile,
      );
      _memoryProfile = updated;
      await MemoryService.saveMemoryProfile(updated);
    } catch (_) {}
  }

  Future<void> _toggleMic() async {
    if (_isLoading) return;

    if (_isListeningNow) {
      await _voiceService.stopListening();
      if (mounted) {
        setState(() {
          _isListeningNow = false;
          _livePartial = '';
        });
      }
      return;
    }

    await TtsService.stop();
    if (mounted) setState(() => _isSpeaking = false);

    setState(() {
      _livePartial = '';
      _lastUserMessage = null;
      _lumineReply = null;
    });

    final available = await _voiceService.init();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone unavailable. Check permissions.')),
        );
      }
      return;
    }
    if (!mounted) return;

    setState(() {
      _isListeningNow = true;
      _showKeyboard = false;
      _keyboardFocus.unfocus();
       _hasStartedChat = true; 
    });

    var finalText = '';
    var alreadySent = false;
    Timer? silenceTimer;

    Future<void> finalize() async {
      if (alreadySent) return;
      alreadySent = true;
      silenceTimer?.cancel();
      await _voiceService.stopListening();
      if (!mounted) return;
      final captured = finalText.trim();
      setState(() {
        _isListeningNow = false;
        _livePartial = '';
      });
      if (captured.isNotEmpty) {
        await _sendMessage(captured);
      }
    }

    _voiceService.startListening((text) {
      if (!mounted || alreadySent) return;
      finalText = text;
      setState(() => _livePartial = text);

      silenceTimer?.cancel();
      silenceTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && _isListeningNow && finalText.trim().isNotEmpty) {
          finalize();
        }
      });
    });

    _voiceService.onSilence(() {
      if (!alreadySent) finalize();
    });

    Future.delayed(const Duration(seconds: 35), () {
      if (mounted && _isListeningNow && !alreadySent) {
        finalize();
      }
    });
  }

  void _openKeyboard() {
    if (_isListeningNow) return;
    setState(() {
      _showKeyboard = true;
      _hasStartedChat = true;
    });
    AppController().setKeyboardActive(true);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _keyboardFocus.requestFocus();
    });
  }

  void _closeKeyboard() {
    _keyboardFocus.unfocus();
    setState(() {
      _showKeyboard = false;
    });
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Chat History",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _chatHistory.isEmpty
                  ? Center(
                      child: Text(
                        "No conversations yet.\nStart sharing with Lumíne.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF1A1A1A).withOpacity(0.6),
                          height: 1.6,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chatHistory.length,
                      itemBuilder: (context, index) {
                        final msg = _chatHistory[_chatHistory.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  msg["user"] ?? "",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideX(begin: 0.1, curve: Curves.easeOut),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  msg["lumine"] ?? "",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF1A1A1A),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 150.ms, duration: 400.ms)
                                  .slideX(begin: -0.1, curve: Curves.easeOut),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;
    final keyboardOpen = keyboardHeight > 0;
    final showingKeyboardBar = _showKeyboard || keyboardOpen;

    return PopScope(
      canPop: !showingKeyboardBar,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && showingKeyboardBar) _closeKeyboard();
      },
      child: AnimatedBuilder(
        animation: AppController(),
        builder: (_, __) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: const Color(0xFFFDFBF3),
            body: Stack(
              children: [
                // ─── Background — always full physical screen ───
                Positioned.fill(
  child: _AnimatedGradientBackground(
    bgController: _bgController,
    emotion: AppController().currentEmotion,
  ),
),

                // ─── Foreground content ───
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: showingKeyboardBar ? _closeKeyboard : null,
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildHeader(),
                        SizedBox(height: showingKeyboardBar ? 16 : 32),
                                                GlowOrb(
                          size: showingKeyboardBar ? 130 : 220,
                          active: _isListeningNow || _isSpeaking,
                        ),
                        SizedBox(height: showingKeyboardBar ? 16 : 32),

                        // ── Greeting text below orb (only when idle) ──
                        if (!_hasStartedChat && !showingKeyboardBar)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _greetingText(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F0F0F),
                                height: 1.3,
                              ),
                            ),
                          ),

                        SizedBox(height: showingKeyboardBar ? 16 : 24),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: showingKeyboardBar
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTranscript(),
                                if (!showingKeyboardBar) ...[
                                  const SizedBox(height: 80),
                                  _buildControlDock(),
                                  const SizedBox(height: 144),
                                ] else ...[
                                  const SizedBox(height: 100),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Keyboard bar — full width, floats above keyboard ───
                if (showingKeyboardBar)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: _buildKeyboardBar(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Reflect',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusLine,
              
            key: ValueKey(_statusLine),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF1A1A1A).withOpacity(0.65),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranscript() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_livePartial.isNotEmpty || _lastUserMessage != null)
              AnimatedBuilder(
                animation: _userPillController,
                builder: (_, __) {
                  final t = _userPillController.value;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX((1 - t) * -0.2)
                      ..translate(0.0, (1 - t) * 12),
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _livePartial.isNotEmpty
                              ? _livePartial
                              : (_lastUserMessage ?? ''),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF1A1A1A),
                            fontStyle: _livePartial.isNotEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (_livePartial.isNotEmpty || _lastUserMessage != null)
              const SizedBox(height: 12),
            if (_lumineReply != null)
              AnimatedBuilder(
                animation: _lumineReplyController,
                builder: (_, __) {
                  final t = Curves.easeOutBack.transform(
                    _lumineReplyController.value.clamp(0.0, 1.0),
                  );
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY((1 - t) * 0.4)
                      ..scale(0.9 + t * 0.1),
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          _lumineReply!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlDock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AnimatedDockButton(
            onTap: _showChatHistory,
            floatDelay: 0,
            child: const Icon(Icons.history_rounded,
                color: Color(0xFF1A1A1A), size: 22),
          ),
          _MicButton(
            isListening: _isListeningNow,
            onTap: _toggleMic,
          ),
          _AnimatedDockButton(
            onTap: _openKeyboard,
            floatDelay: 500,
            child: const Icon(Icons.keyboard_outlined,
                color: Color(0xFF1A1A1A), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardBar() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        elevation: 12,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _keyboardFocus,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: const Color(0xFF1A1A1A),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: "Share what you're feeling...",
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1A1A1A).withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _sendMessage(),
                icon: const Icon(Icons.arrow_upward_rounded,
                    color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// IVORY BACKGROUND — uses physical screen size, immune to keyboard
// ══════════════════════════════════════════════════════════════════
class _AnimatedGradientBackground extends StatelessWidget {
  final AnimationController bgController;
  final String emotion;

  const _AnimatedGradientBackground({
    required this.bgController,
    required this.emotion,
  });

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final w = view.physicalSize.width / view.devicePixelRatio;
    final h = view.physicalSize.height / view.devicePixelRatio;

    return RepaintBoundary(
      child: OverflowBox(
        minWidth: w,
        maxWidth: w,
        minHeight: h,
        maxHeight: h,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: w,
          height: h,
          child: AnimatedBuilder(
            animation: bgController,
            builder: (_, __) {
              return CustomPaint(
                painter: _IvoryDepthPainter(
                  t: bgController.value * 2 * pi,
                  emotion: emotion,
                ),
                size: Size(w, h),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IvoryDepthPainter extends CustomPainter {
  final double t;
  final String emotion;

  _IvoryDepthPainter({required this.t, required this.emotion});

  // ── Emotion-shifted ivory palette ──
  // Each emotion has its own tinted ivory tones — cream stays dominant,
  // but the whole paper feels different depending on mood.
   static List<Color> _paletteFor(String emotion) {
    switch (emotion) {
      case 'calm':
        return [
          const Color(0xFFF6F9FC),
          const Color(0xFFE8EEF5),
          const Color(0xFFD9E3EE),
          const Color(0xFFE5EDF3),
        ];
      case 'happy':
        return [
          const Color(0xFFFEFAEC),
          const Color(0xFFF9EFCB),
          const Color(0xFFEFD99A),
          const Color(0xFFFAF3D6),
        ];
      case 'sad':
        return [
          const Color(0xFFF6F3F9),
          const Color(0xFFEBE4F0),
          const Color(0xFFD9CDE0),
          const Color(0xFFEFEAF3),
        ];
      case 'angry':
        return [
          const Color(0xFFFDF3EE),
          const Color(0xFFF8DFD1),
          const Color(0xFFEBC1A8),
          const Color(0xFFF9E5D8),
        ];
      case 'hopeful':
        return [
          const Color(0xFFF3FAFD),
          const Color(0xFFDDEEF6),
          const Color(0xFFBEDDEB),
          const Color(0xFFE0EEF5),
        ];
      case 'anxious':
        return [
          const Color(0xFFF7F0FA),
          const Color(0xFFECDCF3),
          const Color(0xFFD5BEE3),
          const Color(0xFFEEDFF4),
        ];
      case 'grateful':
        return [
          const Color(0xFFF3FAF4),
          const Color(0xFFDCEEDF),
          const Color(0xFFBCDCC0),
          const Color(0xFFDEEFE1),
        ];
      case 'stressed':
        return [
          const Color(0xFFFDF5EA),
          const Color(0xFFF8E5C7),
          const Color(0xFFEDCB93),
          const Color(0xFFFAECD3),
        ];
      case 'optimistic':
        return [
          const Color(0xFFFEFAE4),
          const Color(0xFFFAEEB8),
          const Color(0xFFF0DA80),
          const Color(0xFFFCF3C9),
        ];
      case 'depressed':
        return [
          const Color(0xFFF2F3F6),
          const Color(0xFFE2E5EB),
          const Color(0xFFCACFDA),
          const Color(0xFFE7EAEF),
        ];
      case 'crisis':
        return [
          const Color(0xFFFCEEED),
          const Color(0xFFF8D5D2),
          const Color(0xFFEBB1AC),
          const Color(0xFFF9DDDA),
        ];
      case 'neutral':
      default:
        return [
          const Color(0xFFFDFBF3),
          const Color(0xFFF3EAD1),
          const Color(0xFFE8DFC3),
          const Color(0xFFEEF0F0),
        ];
    }
  }
  @override
  void paint(Canvas canvas, Size size) {
    final palette = _paletteFor(emotion);
    final ivory = palette[0];
    final ivoryWarm = palette[1];
    final ivoryDeep = palette[2];
    final ivoryCool = palette[3];

    // ── Warm cream vertical gradient base ──
    final base = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [ivory, ivoryWarm, ivoryDeep],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = base.createShader(Offset.zero & size),
    );

    // ── Soft radial vignette from top-left (warm light source) ──
    final topLeftGlow = RadialGradient(
      center: Alignment(-0.6 + sin(t * 0.4) * 0.05, -0.7),
      radius: 1.3,
      colors: [
        Colors.white.withOpacity(0.55),
        Colors.white.withOpacity(0.0),
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = topLeftGlow.createShader(Offset.zero & size),
    );

    // ── Soft cool shadow from bottom-right (adds depth) ──
    final bottomRightShade = RadialGradient(
      center: Alignment(0.7 + cos(t * 0.35) * 0.05, 0.8),
      radius: 1.3,
      colors: [
        ivoryCool.withOpacity(0.45),
        ivoryCool.withOpacity(0.0),
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = bottomRightShade.createShader(Offset.zero & size),
    );

    // ── Drifting warm blob (very subtle motion) ──
    final blob1Center = Offset(
      size.width * (0.25 + sin(t * 0.6) * 0.08),
      size.height * (0.35 + cos(t * 0.5) * 0.06),
    );
    final blob1 = Paint()
      ..color = ivoryWarm.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(blob1Center, size.width * 0.5, blob1);

    // ── Drifting cool blob ──
    final blob2Center = Offset(
      size.width * (0.75 + cos(t * 0.5) * 0.08),
      size.height * (0.75 + sin(t * 0.4) * 0.06),
    );
    final blob2 = Paint()
      ..color = ivoryCool.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(blob2Center, size.width * 0.45, blob2);

    // ── Very fine paper-like grain ──
    final grainDark = Paint()..color = Colors.black.withOpacity(0.028);
    final rng = Random(42);
    for (int i = 0; i < 1200; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 0.7 + 0.2;
      canvas.drawCircle(Offset(x, y), r, grainDark);
    }

    final grainLight = Paint()..color = Colors.white.withOpacity(0.04);
    final rng2 = Random(99);
    for (int i = 0; i < 900; i++) {
      final x = rng2.nextDouble() * size.width;
      final y = rng2.nextDouble() * size.height;
      final r = rng2.nextDouble() * 0.6 + 0.15;
      canvas.drawCircle(Offset(x, y), r, grainLight);
    }

    // ── Subtle diagonal texture lines (very faint, gives paper feel) ──
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.015)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 4) {
      final xOffset = sin(y * 0.02 + t * 0.5) * 3;
      canvas.drawLine(
        Offset(xOffset, y),
        Offset(size.width + xOffset, y - 20),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IvoryDepthPainter old) =>
      old.t != t || old.emotion != emotion;
}
// ══════════════════════════════════════════════════════════════════
// DOCK BUTTONS
// ══════════════════════════════════════════════════════════════════
class _AnimatedDockButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final int floatDelay;

  const _AnimatedDockButton({
    required this.child,
    required this.onTap,
    required this.floatDelay,
  });

  @override
  State<_AnimatedDockButton> createState() => _AnimatedDockButtonState();
}

class _AnimatedDockButtonState extends State<_AnimatedDockButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.floatDelay), () {
      if (mounted) _floatCtrl.forward();
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, __) {
        final offsetY = sin(_floatCtrl.value * pi) * 3;
        final rotate = sin(_floatCtrl.value * pi) * 0.05;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotate),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) {
                setState(() => _pressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(child: widget.child),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const _MicButton({required this.isListening, required this.onTap});

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final pulse = widget.isListening
            ? 1.0 + sin(_pulseCtrl.value * pi) * 0.06
            : 1.0;

        final targetScale = widget.isListening ? 1.35 : 1.0;
        final targetLift = widget.isListening ? -18.0 : 0.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          transform: Matrix4.identity()
            ..translate(0.0, targetLift)
            ..scale(targetScale * pulse * (_pressed ? 0.92 : 1.0)),
          transformAlignment: Alignment.center,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isListening
                    ? Colors.redAccent
                    : const Color(0xFF1A1A1A),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isListening
                            ? Colors.redAccent
                            : Colors.black)
                        .withOpacity(widget.isListening ? 0.5 : 0.24),
                    blurRadius: widget.isListening ? 32 : 20,
                    spreadRadius: widget.isListening ? 6 : 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                widget.isListening
                    ? Icons.stop_rounded
                    : Icons.mic_none_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }
}