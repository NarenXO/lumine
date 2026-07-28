import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_controller.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import 'sacred_interruption_screen.dart';
import '../services/tts_service.dart';
import '../services/stats_service.dart';
import '../services/memory_service.dart';
import '../services/app_theme.dart';
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

  late AnimationController _userPillController;
  late AnimationController _lumineReplyController;

    String get _statusLine {
    if (_isLoading) return 'Reading between your lines...';
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
     _warmBackend();
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

  Future<void> _warmBackend() async {
    try {
      // Silent ping to wake Render's sleeping instance
      await ApiService.analyzeMessage(
        'hi',
        recentHistory: [],
        memoryProfile: {},
        appContext: {'current_emotion': 'calm'},
        lastReplies: [],
      ).timeout(const Duration(seconds: 30));
    } catch (_) {
      // Silent — ignore all errors, this is just a warmup
    }
  }

  @override
  void dispose() {
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
// Show instant thinking indicator — user sees Lumíne respond immediately
    setState(() {
      _lumineReply = '...';
      _isLoading = true;
    });
    _lumineReplyController.forward(from: 0);
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
      ).timeout(const Duration(seconds: 5));

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
          _lumineReply = _localFallbackReply(userMessage);
          _isLoading = false;
          _isSpeaking = true;
        });
        _lumineReplyController.forward(from: 0);
        // Speak the fallback too
        TtsService.speakWithCallback(_localFallbackReply(userMessage), 0.4, () {
          if (mounted) setState(() => _isSpeaking = false);
        });
      }
    }
  }

  // Local intelligent reply when backend is slow — never leave user hanging
  String _localFallbackReply(String userMessage) {
    final msg = userMessage.toLowerCase();

    // Detect emotional keywords
    if (msg.contains('sad') || msg.contains('crying') || msg.contains('hurt') || msg.contains('lonely')) {
      return "I hear that weight in what you said. Tell me more — I'm here, unhurried.";
    }
    if (msg.contains('angry') || msg.contains('mad') || msg.contains('frustrated') || msg.contains('annoyed')) {
      return "Something is asking to be heard beneath that anger. What actually happened?";
    }
    if (msg.contains('anxious') || msg.contains('worried') || msg.contains('scared') || msg.contains('afraid')) {
      return "That kind of anxiety usually has a specific shape. What's the thought that keeps returning?";
    }
    if (msg.contains('tired') || msg.contains('exhausted') || msg.contains('burnt out') || msg.contains('drained')) {
      return "There's tired, and then there's this kind of tired. When did you last really rest?";
    }
    if (msg.contains('grateful') || msg.contains('thankful') || msg.contains('blessed')) {
      return "That's a rare thing to notice. What in particular is opening you up right now?";
    }
    if (msg.contains('happy') || msg.contains('good') || msg.contains('great')) {
      return "Good is worth naming. What made today feel that way?";
    }
    if (msg.contains('lost') || msg.contains('confused') || msg.contains('stuck')) {
      return "Feeling lost usually means you're standing at a real crossroads. What's the choice you're actually avoiding?";
    }
    if (msg.contains('why') || msg.contains('meaning') || msg.contains('purpose')) {
      return "That's the question underneath most questions. What do you think you're actually looking for?";
    }

    // Generic thoughtful fallback
    return "Say more. I'm listening.";
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.bgSlate,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: AppTheme.bgSlateGlow, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Chat History",
                  style: AppTheme.display(
                    size: 24,
                    color: AppTheme.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary),
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
                        style: AppTheme.body(
                          size: 14,
                          color: AppTheme.textSecondary,
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
                              // User message — gold-tinted bubble
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldMid.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.goldMid.withOpacity(0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  msg["user"] ?? "",
                                  style: AppTheme.body(
                                    color: AppTheme.textPrimary,
                                    size: 14,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideX(begin: 0.1, curve: Curves.easeOut),
                              const SizedBox(height: 8),
                              // Lumíne reply — Literata
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgSlateHigh,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.bgSlateGlow,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  msg["lumine"] ?? "",
                                  style: AppTheme.verse(
                                    color: AppTheme.textPrimary,
                                    size: 15,
                                    height: 1.6,
                                    fontStyle: FontStyle.normal,
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
  // BUILD — KEEPS KEYBOARD FIX INTACT
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
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Main content
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

                        if (!_hasStartedChat && !showingKeyboardBar)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _greetingText(),
                              textAlign: TextAlign.center,
                              style: AppTheme.display(
                                size: 26,
                                color: AppTheme.textPrimary,
                                weight: FontWeight.w600,
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

                // Keyboard bar — positioned, no white background
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
          style: AppTheme.display(
            size: 30,
            color: AppTheme.textPrimary,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusLine,
            key: ValueKey(_statusLine),
            style: AppTheme.body(
              size: 13,
              color: AppTheme.textSecondary,
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
            // User pill — gold-tinted dark
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
                          color: AppTheme.bgSlate.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.goldMid.withOpacity(0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldMid.withOpacity(0.1),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          _livePartial.isNotEmpty
                              ? _livePartial
                              : (_lastUserMessage ?? ''),
                          style: AppTheme.body(
                            size: 15,
                            color: AppTheme.textPrimary,
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
            // Lumíne reply pill — dark slate with gold border, Literata
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSlateHigh,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppTheme.goldMid.withOpacity(0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldMid.withOpacity(0.18),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          _lumineReply!,
                          style: AppTheme.verse(
                            size: 16,
                            color: AppTheme.textPrimary,
                            height: 1.6,
                            fontStyle: FontStyle.normal,
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
            child: Icon(
              Icons.history_rounded,
              color: AppTheme.goldMid,
              size: 22,
            ),
          ),
          _MicButton(
            isListening: _isListeningNow,
            onTap: _toggleMic,
          ),
          _AnimatedDockButton(
            onTap: _openKeyboard,
            floatDelay: 500,
            child: Icon(
              Icons.keyboard_outlined,
              color: AppTheme.goldMid,
              size: 22,
            ),
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
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(28),
        color: AppTheme.bgSlate,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.bgSlateGlow, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _keyboardFocus,
                  style: AppTheme.body(
                    size: 15,
                    color: AppTheme.textPrimary,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  cursorColor: AppTheme.goldMid,
                  decoration: InputDecoration(
                    hintText: "Share what you're feeling...",
                    hintStyle: AppTheme.body(
                      size: 15,
                      color: AppTheme.textTertiary,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _sendMessage(),
                icon: Icon(
                  Icons.arrow_upward_rounded,
                  color: AppTheme.goldMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// DOCK BUTTONS — dark slate with gold icons
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.bgSlate,
                    border: Border.all(
                      color: AppTheme.goldMid.withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldMid.withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
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

// ══════════════════════════════════════════════════════════════════
// MIC BUTTON — gold when idle, red when listening
// ══════════════════════════════════════════════════════════════════
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

        final baseColor = widget.isListening
            ? const Color(0xFFE85D5D)
            : AppTheme.goldMid;

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor,
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withOpacity(widget.isListening ? 0.6 : 0.4),
                    blurRadius: widget.isListening ? 32 : 24,
                    spreadRadius: widget.isListening ? 6 : 3,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                widget.isListening
                    ? Icons.stop_rounded
                    : Icons.mic_none_rounded,
                color: widget.isListening ? Colors.white : AppTheme.bgDeep,
                size: 34,
              ),
            ),
          ),
        );
      },
    );
  }
}