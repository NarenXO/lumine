import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_controller.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../services/stats_service.dart';
import '../services/app_theme.dart';
import 'sacred_interruption_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveformController;
  late AnimationController _ringController;
  late AnimationController _weatherController;
  late AnimationController _radarController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;

  int _heartRate = 72;
  int _hrv = 42;
  int _steps = 4823;
  double _sleepHours = 7.2;
  double _stressScore = 0.18;

  int _presenceScore = 72;
  int _bodyScore = 64;
  int _mindScore = 71;
  int _spiritScore = 82;

  double _sleepQuality = 7.0;
  double _stressLevel = 4.0;
  double _socialEnergy = 6.0;
  double _dailyRest = 5.5;

  String _analyzeInsight = '';
  bool _analyzeLoading = false;

  bool _wearableActive = true;
  Timer? _bioTimer;
  DateTime? _lastSpike;
  bool _isFlashing = false;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _weatherController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _startBioSim();
        // Wake up backend silently in background — no user wait
    _warmBackend();
  }
  Future<void> _warmBackend() async {
    try {
      // Fire-and-forget ping to wake Render's sleeping instance
      await ApiService.analyzeHabits(
        sleep: 5,
        stress: 5,
        social: 5,
        rest: 5,
        heartRate: 72,
        activityLevel: 0.3,
      ).timeout(const Duration(seconds: 30));
    } catch (_) {
      // Silent — this is just a warmup, ignore all errors
    }
  }
  @override
  void dispose() {
    _waveformController.dispose();
    _ringController.dispose();
    _weatherController.dispose();
    _radarController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    _bioTimer?.cancel();
    super.dispose();
  }

  void _startBioSim() {
    _bioTimer?.cancel();
    if (!_wearableActive) return;
    _bioTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _heartRate += _random.nextInt(5) - 2;
        _heartRate = _heartRate.clamp(58, 130);
        _hrv += _random.nextInt(4) - 2;
        _hrv = _hrv.clamp(20, 80);
        _steps += _random.nextInt(15);
        _stressScore = ((_heartRate - 60) / 70).clamp(0.0, 1.0);
        _bodyScore = ((_heartRate < 90 ? 80 : 55) + _random.nextInt(10)).clamp(0, 100);
        _mindScore = ((_hrv > 40 ? 75 : 50) + _random.nextInt(10)).clamp(0, 100);
        _spiritScore = (75 + _random.nextInt(15)).clamp(0, 100);
        _presenceScore = ((_bodyScore + _mindScore + _spiritScore) ~/ 3);
      });
    });
  }

 void _triggerSpike() {
  setState(() {
    _heartRate = 118 + _random.nextInt(8);
    _stressScore = 0.85;
    _lastSpike = DateTime.now();
    _isFlashing = true;
  });

  // Update global app emotion immediately
  AppController().setEmotion('stressed');
  StatsService.recordEmotion('stressed');

  Future.delayed(const Duration(milliseconds: 500), () {
    if (mounted) setState(() => _isFlashing = false);
  });

  Future.delayed(const Duration(milliseconds: 400), () {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SacredInterruptionScreen(
          scriptureText:
              'Come to me, all you who are weary and burdened, and I will give you rest.',
          scriptureRef: 'Matthew 11:28',
        ),
      ),
    );
  });
}

  void _resetBio() {
    setState(() {
      _heartRate = 72;
      _hrv = 42;
      _stressScore = 0.18;
      _lastSpike = null;
    });
  }

  Future<void> _analyzeRhythm() async {
    setState(() {
      _analyzeLoading = true;
      _analyzeInsight = '';
    });
    try {
      final result = await ApiService.analyzeHabits(
        sleep: _sleepQuality,
        stress: _stressLevel,
        social: _socialEnergy,
        rest: _dailyRest,
        heartRate: _heartRate,
        activityLevel: _steps / 10000,
      );
      if (mounted) {
        setState(() {
          _analyzeInsight = result['insight'] ?? 'Your rhythm is steady today.';
          _analyzeLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _analyzeInsight = 'Your body is asking for gentleness today.';
          _analyzeLoading = false;
        });
      }
    }
  }

  double get _faceMood {
    final s = _sleepQuality / 10;
    final st = 1.0 - (_stressLevel / 10);
    final so = _socialEnergy / 10;
    final r = _dailyRest / 10;
    final avg = (s + st + so + r) / 4;
    return (avg * 2) - 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController(),
      builder: (_, __) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 20),

                  _buildWaveformCard()
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.15, curve: Curves.easeOut),
                  const SizedBox(height: 14),

                  _buildRingsCard()
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 600.ms)
                      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut),
                  const SizedBox(height: 14),

                  _buildWeatherCard()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideX(begin: 0.15, curve: Curves.easeOut),
                  const SizedBox(height: 14),

                  _buildGlooInsightCard()
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: 0.15, curve: Curves.easeOut),
                  const SizedBox(height: 14),

                  _buildWearableCard()
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .slideX(begin: -0.15, curve: Curves.easeOut),
                  const SizedBox(height: 14),

                  _buildRhythmSlidersCard()
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),

                 const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Naren's Rhythms",
                style: AppTheme.display(
                  size: 30,
                  color: AppTheme.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Body, mind, spirit — all connected",
                style: AppTheme.body(
                  size: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgSlate,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.bgSlateGlow),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Icon(_timeIcon(), color: AppTheme.goldMid, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(),
                    style: AppTheme.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _timeIcon() {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 18) return Icons.wb_sunny_rounded;
    return Icons.nightlight_round;
  }

  String _formatTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final p = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  // ══════════════════════════════════════════════════════════════
  // 1. LIVE WAVEFORM
  // ══════════════════════════════════════════════════════════════
  Widget _buildWaveformCard() {
    return _DarkBentoBox(
      patternPainter: _GridPatternPainter(t: _waveformController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AnimatedHeartIcon(pulse: _pulseController),
              const SizedBox(width: 10),
              Text(
                "LIVE PULSE",
                style: AppTheme.label(
                  size: 12,
                  letterSpacing: 1.8,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              _AnimatedNumberText(
                value: _heartRate.toDouble(),
                suffix: ' BPM',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldMid,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: AnimatedBuilder(
              animation: _waveformController,
              builder: (_, __) {
                return CustomPaint(
                  size: const Size(double.infinity, 70),
                  painter: _WaveformPainter(
                    t: _waveformController.value,
                    heartRate: _heartRate,
                    stress: _stressScore,
                    color: ThemeService.getEmotionColor(),
                    isFlashing: _isFlashing,
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
  // 2. BIOMETRIC RINGS
  // ══════════════════════════════════════════════════════════════
  Widget _buildRingsCard() {
    return _DarkBentoBox(
      patternPainter: _RingEchoesPatternPainter(t: _ringController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PRESENCE RINGS",
            style: AppTheme.label(
              size: 12,
              letterSpacing: 1.8,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: AnimatedBuilder(
                animation: _ringController,
                builder: (_, __) {
                  return CustomPaint(
                    size: const Size(220, 220),
                    painter: _RingsPainter(
                      body: _bodyScore / 100,
                      mind: _mindScore / 100,
                      spirit: _spiritScore / 100,
                      rotation: _ringController.value * 2 * pi,
                      emotionColor: ThemeService.getEmotionColor(),
                    ),
                   child: Center(
                      child: _AnimatedNumberText(
                        value: _presenceScore.toDouble(),
                        suffix: '%',
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.goldMid,
                        font: GoogleFonts.manrope,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ringLegend('Body', _bodyScore, const Color(0xFFE87A5F), Icons.favorite_rounded),
              _ringLegend('Mind', _mindScore, const Color(0xFF8B5CF6), Icons.psychology_rounded),
              _ringLegend('Spirit', _spiritScore, const Color(0xFF10B981), Icons.auto_awesome_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ringLegend(String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) {
            return Transform.scale(
              scale: 1.0 + sin(_pulseController.value * pi) * 0.06,
              child: Icon(icon, color: color, size: 20),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.label(
            size: 11,
            letterSpacing: 1,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        _AnimatedNumberText(
          value: value.toDouble(),
          suffix: '%',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 3. WEATHER TIMELINE
  // ══════════════════════════════════════════════════════════════
 Widget _buildWeatherCard() {
  final currentHour = DateTime.now().hour;
  final history = StatsService.emotionHistory;

  final Map<int, String> hourMap = {};
  for (final e in history) {
    final h = e['hour'] as int;
    hourMap[h] = e['emotion'] as String;
  }

  // Also merge any real data on top
  final history = StatsService.emotionHistory;
  for (final e in history) {
    final h = e['hour'] as int;
    hourMap[h] = e['emotion'] as String;
  }

  return _DarkBentoBox(
    patternPainter: _DiagonalShimmerPatternPainter(
        t: _weatherController.value * 2 * pi),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S EMOTIONAL WEATHER",
          style: AppTheme.label(
            size: 12,
            letterSpacing: 1.6,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 24,
            itemBuilder: (context, hour) {
              final emotion = hourMap[hour];
              final isCurrent = hour == currentHour;
              final displayH =
                  hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
              final period = hour >= 12 ? 'PM' : 'AM';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? ThemeService.getEmotionColor()
                                .withOpacity(0.25)
                            : Colors.transparent,
                        border: isCurrent
                            ? Border.all(
                                color: ThemeService.getEmotionColor(),
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: emotion == null
                            ? Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.textTertiary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : _AnimatedWeatherIcon(
                                emotion: emotion,
                                controller: _weatherController,
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$displayH $period',
                      style: AppTheme.body(
                        size: 10,
                        weight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isCurrent
                            ? AppTheme.textPrimary
                            : AppTheme.textTertiary,
                      ),
                    ),
                  ],
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
  // 4. WHAT YOUR BODY IS SAYING
  // ══════════════════════════════════════════════════════════════
  Widget _buildGlooInsightCard() {
    return _DarkBentoBox(
      patternPainter: _PulsingEyePatternPainter(t: _pulseController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + sin(_pulseController.value * pi) * 0.08,
                  child: Icon(
                    Icons.remove_red_eye_rounded,
                    color: AppTheme.goldMid.withOpacity(0.8),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "WHAT YOUR BODY IS SAYING",
                style: AppTheme.label(
                  size: 12,
                  letterSpacing: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _bodyInsight(),
            style: AppTheme.verse(
              size: 16,
              color: AppTheme.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _bodyInsight() {
    if (_heartRate > 100) {
      return 'Your heart is racing — your body is carrying more than you may realize.';
    } else if (_hrv < 30) {
      return 'Your nervous system is working hard. A slow breath now would help.';
    } else if (_heartRate < 65 && _stressScore < 0.2) {
      return 'Your body is settled — a rare kind of quiet is resting on you.';
    } else if (_steps > 8000) {
      return 'You have moved with intention today. Your body remembers this.';
    }
    return 'Your rhythm is steady. Lumíne is quietly with you.';
  }

  // ══════════════════════════════════════════════════════════════
  // 5. WEARABLE SYNC
  // ══════════════════════════════════════════════════════════════
Widget _buildWearableCard() {
  return _DarkBentoBox(
    patternPainter: _RadarPatternPainter(
      t: _radarController.value * 2 * pi,
      active: _wearableActive,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                return Transform.scale(
                  scale: _wearableActive
                      ? 1.0 + sin(_pulseController.value * pi) * 0.08
                      : 1.0,
                  child: Icon(
                    Icons.watch_rounded,
                    color: _wearableActive
                        ? const Color(0xFF10B981)
                        : AppTheme.textTertiary,
                    size: 20,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              "WEARABLE SYNC",
              style: AppTheme.label(
                size: 12,
                letterSpacing: 1.8,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            _wearableToggle(),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.bgSlateHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.smartphone_rounded,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motorola Edge 60 Pro',
                    style: AppTheme.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _wearableActive
                        ? 'Reading your body every 4s'
                        : 'Tap to connect Lumíne to your body',
                    style: AppTheme.body(
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _bioMetric(
              Icons.favorite_rounded,
              _heartRate.toDouble(),
              ' bpm',
              const Color(0xFFE87A5F),
            ),
            const SizedBox(width: 8),
            _bioMetric(
              Icons.show_chart_rounded,
              _hrv.toDouble(),
              ' ms',
              const Color(0xFF8B5CF6),
            ),
            const SizedBox(width: 8),
            _bioMetric(
              Icons.directions_walk_rounded,
              _steps.toDouble(),
              '',
              const Color(0xFF10B981),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _devButton(
                'Trigger Spike',
                Icons.bolt_rounded,
                const Color(0xFFEF4444),
                _triggerSpike,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _devButton(
                'Reset',
                Icons.refresh_rounded,
                AppTheme.textSecondary,
                _resetBio,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
  Widget _wearableToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _wearableActive = !_wearableActive);
        _startBioSim();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _wearableActive
              ? const Color(0xFF10B981)
              : AppTheme.bgSlateGlow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          alignment: _wearableActive ? Alignment.centerRight : Alignment.centerLeft,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bioMetric(IconData icon, double value, String suffix, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            _AnimatedNumberText(
              value: value,
              suffix: suffix,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _devButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.body(
                size: 13,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 6. DAILY RHYTHMS
  // ══════════════════════════════════════════════════════════════
  Widget _buildRhythmSlidersCard() {
    return _DarkBentoBox(
      patternPainter: _WaveLinesPatternPainter(t: _waveformController.value * 2 * pi),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DAILY RHYTHMS",
            style: AppTheme.label(
              size: 12,
              letterSpacing: 1.8,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Move each slider — watch how you feel.",
            style: AppTheme.body(
              size: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

                    _rhythmSlider(
            label: 'Sleep Quality',
            value: _sleepQuality,
            icon: Icons.bedtime_rounded,
            positive: true,
            color: const Color(0xFF7BA9F0), // soft sky
            onChanged: (v) => setState(() => _sleepQuality = v),
          ),
          _rhythmSlider(
            label: 'Stress Level',
            value: _stressLevel,
            icon: Icons.whatshot_rounded,
            positive: false,
            color: const Color(0xFFFF9B85), // warm coral
            onChanged: (v) => setState(() => _stressLevel = v),
          ),
          _rhythmSlider(
            label: 'Social Energy',
            value: _socialEnergy,
            icon: Icons.people_rounded,
            positive: true,
            color: const Color(0xFFE9D08C), // sacred gold
            onChanged: (v) => setState(() => _socialEnergy = v),
          ),
          _rhythmSlider(
            label: 'Daily Rest',
            value: _dailyRest,
            icon: Icons.spa_rounded,
            positive: true,
            color: const Color(0xFF7DD69F), // mint sage
            onChanged: (v) => setState(() => _dailyRest = v),
          ),

          const SizedBox(height: 12),

          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: AnimatedBuilder(
                animation: _sparkleController,
                builder: (_, __) {
                  return CustomPaint(
                    size: const Size(280, 280),
                    painter: _MorphingFacePainter(
                      mood: _faceMood,
                      sparkleT: _sparkleController.value * 2 * pi,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (_analyzeInsight.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgSlateHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.goldMid.withOpacity(0.3)),
              ),
              child: Text(
                _analyzeInsight,
                style: AppTheme.verse(
                  size: 15,
                  color: AppTheme.textPrimary,
                  height: 1.6,
                ),
              ),
            ).animate().fadeIn(duration: 500.ms),

          if (_analyzeInsight.isNotEmpty) const SizedBox(height: 16),

          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final glow = 8.0 + sin(_pulseController.value * pi) * 8;
                return GestureDetector(
                  onTap: _analyzeLoading ? null : _analyzeRhythm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.goldMid,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldMid.withOpacity(0.35),
                          blurRadius: glow,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                                        child: _analyzeLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: AppTheme.bgDeep,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Reading you...',
                                style: AppTheme.body(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: AppTheme.bgDeep,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.insights_rounded, color: AppTheme.bgDeep, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Analyze Rhythm',
                                style: AppTheme.body(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: AppTheme.bgDeep,
                                  letterSpacing: 0.5,
                                ),
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

  Widget _rhythmSlider({
    required String label,
    required double value,
    required IconData icon,
    required bool positive,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    final moodValue = positive ? value : (10 - value);
    String descriptor;
    if (moodValue >= 8) {
      descriptor = 'Great';
    } else if (moodValue >= 6) {
      descriptor = 'Good';
    } else if (moodValue >= 4) {
      descriptor = 'Okay';
    } else if (moodValue >= 2) {
      descriptor = 'Low';
    } else {
      descriptor = 'Rough';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  return Transform.scale(
                    scale: 1.0 + sin(_pulseController.value * pi) * 0.08,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTheme.body(
                  size: 15,
                  weight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Container(
                  key: ValueKey(descriptor),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    descriptor,
                    style: AppTheme.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value.toStringAsFixed(1),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ExpressiveSlider(
            value: value,
            color: color,
            onChanged: onChanged,
            pulseController: _pulseController,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// DARK BENTO BOX — matches app-wide slate look
// ══════════════════════════════════════════════════════════════════
class _DarkBentoBox extends StatelessWidget {
  final Widget child;
  final CustomPainter patternPainter;

  const _DarkBentoBox({
    required this.child,
    required this.patternPainter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgSlate,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.bgSlateGlow, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.bgSlateGlow.withOpacity(0.5),
            blurRadius: 24,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: patternPainter)),
            Positioned(
              top: 0, left: 0, right: 0, height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ANIMATED NUMBER TEXT
// ══════════════════════════════════════════════════════════════════
class _AnimatedNumberText extends StatelessWidget {
  final double value;
  final String suffix;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final TextStyle Function({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    FontStyle? fontStyle,
    double? height,
    double? letterSpacing,
  })? font;

  const _AnimatedNumberText({
    required this.value,
    this.suffix = '',
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    this.font,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: value),
      builder: (context, animatedValue, __) {
        final display = value >= 100 || value.truncateToDouble() == value
            ? animatedValue.round().toString()
            : animatedValue.toStringAsFixed(1);
        final style = (font ?? GoogleFonts.manrope)(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
        return Text(display + suffix, style: style);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ANIMATED HEART ICON
// ══════════════════════════════════════════════════════════════════
class _AnimatedHeartIcon extends StatelessWidget {
  final AnimationController pulse;
  const _AnimatedHeartIcon({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        return Transform.scale(
          scale: 1.0 + sin(pulse.value * pi) * 0.15,
          child: const Icon(
            Icons.favorite_rounded,
            color: Color(0xFFE87A5F),
            size: 20,
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ANIMATED WEATHER ICON
// ══════════════════════════════════════════════════════════════════
class _AnimatedWeatherIcon extends StatelessWidget {
  final String emotion;
  final AnimationController controller;

  const _AnimatedWeatherIcon({required this.emotion, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * pi;
        switch (emotion) {
          case 'happy':
          case 'optimistic':
            return Transform.rotate(
              angle: t * 0.15,
              child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFD470), size: 24),
            );
          case 'sad':
          case 'depressed':
            return Transform.translate(
              offset: Offset(0, sin(t) * 2),
              child: const Icon(Icons.grain_rounded, color: Color(0xFFB8A0E8), size: 24),
            );
          case 'angry':
          case 'crisis':
            return Transform.translate(
              offset: Offset(sin(t * 3) * 1.5, 0),
              child: const Icon(Icons.thunderstorm_rounded, color: Color(0xFFFF7C6B), size: 24),
            );
          case 'hopeful':
            return const Icon(Icons.wb_twilight_rounded, color: Color(0xFF6BC5D9), size: 24);
          case 'anxious':
          case 'stressed':
            return Transform.translate(
              offset: Offset(cos(t) * 2, 0),
              child: const Icon(Icons.air_rounded, color: Color(0xFFC688F0), size: 24),
            );
          case 'grateful':
            return Transform.scale(
              scale: 0.95 + sin(t) * 0.08,
              child: const Icon(Icons.filter_drama_rounded, color: Color(0xFF7DD69F), size: 24),
            );
          case 'calm':
          default:
            return Transform.translate(
              offset: Offset(sin(t * 0.5) * 1.5, 0),
              child: const Icon(Icons.cloud_rounded, color: Color(0xFF7BA9F0), size: 24),
            );
        }
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// EXPRESSIVE SLIDER
// ══════════════════════════════════════════════════════════════════
class _ExpressiveSlider extends StatefulWidget {
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  final AnimationController pulseController;

  const _ExpressiveSlider({
    required this.value,
    required this.color,
    required this.onChanged,
    required this.pulseController,
  });

  @override
  State<_ExpressiveSlider> createState() => _ExpressiveSliderState();
}

class _ExpressiveSliderState extends State<_ExpressiveSlider> {
  bool _isDragging = false;

  double _valueFromPosition(double dx, double width) {
    final ratio = (dx / width).clamp(0.0, 1.0);
    return ratio * 10;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final progress = (widget.value / 10).clamp(0.0, 1.0);

        return GestureDetector(
          onHorizontalDragStart: (details) {
            setState(() => _isDragging = true);
            widget.onChanged(_valueFromPosition(details.localPosition.dx, width));
          },
          onHorizontalDragUpdate: (details) {
            widget.onChanged(_valueFromPosition(details.localPosition.dx, width));
          },
          onHorizontalDragEnd: (_) {
            setState(() => _isDragging = false);
          },
          onTapDown: (details) {
            widget.onChanged(_valueFromPosition(details.localPosition.dx, width));
          },
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: 0, right: 0,
                  top: 18,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                ...List.generate(11, (i) {
                  final tickX = (i / 10) * width;
                  final isPassed = (widget.value / 10) >= (i / 10);
                  return Positioned(
                    left: tickX - 1,
                    top: 16,
                    child: Container(
                      width: 2,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? widget.color.withOpacity(0.7)
                            : widget.color.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                }),
                Positioned(
                  left: 0,
                  top: 18,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: (width * progress).clamp(0.0, width),
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withOpacity(0.85),
                          widget.color,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  left: (width * progress - 16).clamp(0.0, width - 32),
                  top: 6,
                  child: AnimatedBuilder(
                    animation: widget.pulseController,
                    builder: (_, __) {
                      final pulse = 1.0 + sin(widget.pulseController.value * pi) * 0.1;
                      final scaleUp = _isDragging ? 1.25 : 1.0;
                      return Transform.scale(
                        scale: pulse * scaleUp,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.bgSlate,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.color,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withOpacity(_isDragging ? 0.5 : 0.3),
                                blurRadius: _isDragging ? 20 : 10,
                                spreadRadius: _isDragging ? 4 : 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// WAVEFORM PAINTER
// ══════════════════════════════════════════════════════════════════
class _WaveformPainter extends CustomPainter {
  final double t;
  final int heartRate;
  final double stress;
  final Color color;
  final bool isFlashing;

  _WaveformPainter({
    required this.t,
    required this.heartRate,
    required this.stress,
    required this.color,
    required this.isFlashing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final amplitude = 12 + (heartRate - 60) * 0.5;
    final sharpness = 1.0 + stress * 3;
    final speed = 1.0 + stress * 0.5;

    final lineColor = isFlashing ? const Color(0xFFFF7C6B) : color;

    final glowPaint = Paint()
      ..color = lineColor.withOpacity(0.4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final scrollT = t * 2 * pi;

    for (double x = 0; x <= size.width; x += 2) {
      final phase = (x / size.width) * pi * 4 * sharpness + scrollT * speed;
      final wobble = sin(phase) * amplitude +
          sin(phase * 3) * (amplitude * 0.15 * sharpness);
      final y = centerY + wobble;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.t != t || old.heartRate != heartRate || old.stress != stress || old.isFlashing != isFlashing;
}

// ══════════════════════════════════════════════════════════════════
// RINGS PAINTER
// ══════════════════════════════════════════════════════════════════
class _RingsPainter extends CustomPainter {
  final double body;
  final double mind;
  final double spirit;
  final double rotation;
  final Color emotionColor;

  _RingsPainter({
    required this.body,
    required this.mind,
    required this.spirit,
    required this.rotation,
    required this.emotionColor,
  });

  void _drawRing(Canvas canvas, Offset center, double radius, double thickness,
      double progress, Color color) {
    final trackPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _drawRing(canvas, center, size.width * 0.44, 14, body, const Color(0xFFE87A5F));
    _drawRing(canvas, center, size.width * 0.34, 12, mind, const Color(0xFF8B5CF6));
    _drawRing(canvas, center, size.width * 0.24, 10, spirit, const Color(0xFF10B981));
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.body != body || old.mind != mind || old.spirit != spirit;
}

// ══════════════════════════════════════════════════════════════════
// MORPHING FACE PAINTER
// ══════════════════════════════════════════════════════════════════
class _MorphingFacePainter extends CustomPainter {
  final double mood;
  final double sparkleT;

  _MorphingFacePainter({required this.mood, required this.sparkleT});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    Color faceColor;
    if (mood > 0) {
      faceColor = Color.lerp(
        const Color(0xFFECECEC),
        const Color(0xFFFFE066),
        mood,
      )!;
    } else {
      faceColor = Color.lerp(
        const Color(0xFFECECEC),
        const Color(0xFFA8C8E8),
        -mood,
      )!;
    }

        final baseRadius = w * 0.42;
    // Very subtle morph — no cuts on sides, always looks circular
    final droop = mood < 0 ? -mood * 6 : 0.0;
    final rounding = mood > 0 ? mood * 4 : 0.0;

    final facePath = Path();
    const points = 80;
    for (int i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * pi;
      // Smooth droop applied only to the very bottom (not sides)
      final bottomDip = (angle > pi * 0.6 && angle < pi * 0.9)
          ? sin((angle - pi * 0.6) / (pi * 0.3) * pi) * droop
          : 0.0;
      // Smooth round applied only to the very top (not sides)
      final topLift = (angle > pi * 1.1 && angle < pi * 1.4)
          ? sin((angle - pi * 1.1) / (pi * 0.3) * pi) * rounding
          : 0.0;
      final r = baseRadius + bottomDip + topLift;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) {
        facePath.moveTo(x, y);
      } else {
        facePath.lineTo(x, y);
      }
    }
    facePath.close();

    canvas.drawPath(
      facePath,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawPath(facePath, Paint()..color = faceColor);

    if (mood > 0.15) {
      final blushOpacity = ((mood - 0.15) * 1.5).clamp(0.0, 0.6);
      final blushPaint = Paint()
        ..color = const Color(0xFFFF8FA3).withOpacity(blushOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(
        Offset(center.dx - w * 0.2, center.dy + h * 0.05),
        w * 0.06,
        blushPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + w * 0.2, center.dy + h * 0.05),
        w * 0.06,
        blushPaint,
      );
    }

       final eyeY = center.dy - h * 0.06;
    final eyeSpacing = w * 0.14;
    final eyeSize = w * 0.055; // bigger eyes = more kawaii

    if (mood > 0.5) {
      final eyeCurve = (mood - 0.5) * 2;
      final leftEyePath = Path();
      leftEyePath.moveTo(center.dx - eyeSpacing - eyeSize, eyeY + eyeSize * 0.3);
      leftEyePath.quadraticBezierTo(
        center.dx - eyeSpacing,
        eyeY - eyeSize * eyeCurve,
        center.dx - eyeSpacing + eyeSize,
        eyeY + eyeSize * 0.3,
      );
      final rightEyePath = Path();
      rightEyePath.moveTo(center.dx + eyeSpacing - eyeSize, eyeY + eyeSize * 0.3);
      rightEyePath.quadraticBezierTo(
        center.dx + eyeSpacing,
        eyeY - eyeSize * eyeCurve,
        center.dx + eyeSpacing + eyeSize,
        eyeY + eyeSize * 0.3,
      );
      final eyePaint = Paint()
        ..color = const Color(0xFF0F0F0F)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(leftEyePath, eyePaint);
      canvas.drawPath(rightEyePath, eyePaint);
        } else {
      final wideFactor = mood < 0 ? 1.0 + (-mood * 0.4) : 1.0;
      final eyePaint = Paint()..color = const Color(0xFF0F0F0F);
      final highlightPaint = Paint()..color = Colors.white;

      // Left eye — big black dot + tiny white highlight for shine
      final leftEyeCenter = Offset(center.dx - eyeSpacing, eyeY);
      canvas.drawCircle(leftEyeCenter, eyeSize * wideFactor, eyePaint);
      canvas.drawCircle(
        Offset(leftEyeCenter.dx - eyeSize * 0.3, leftEyeCenter.dy - eyeSize * 0.3),
        eyeSize * 0.28,
        highlightPaint,
      );

      // Right eye — same
      final rightEyeCenter = Offset(center.dx + eyeSpacing, eyeY);
      canvas.drawCircle(rightEyeCenter, eyeSize * wideFactor, eyePaint);
      canvas.drawCircle(
        Offset(rightEyeCenter.dx - eyeSize * 0.3, rightEyeCenter.dy - eyeSize * 0.3),
        eyeSize * 0.28,
        highlightPaint,
      );
    }
    final browY = eyeY - h * 0.08;
    final browTilt = mood * 0.25;
    final browPaint = Paint()
      ..color = const Color(0xFF0F0F0F).withOpacity(0.75)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx - eyeSpacing, browY);
    canvas.rotate(-browTilt);
    canvas.drawLine(
      Offset(-w * 0.05, 0),
      Offset(w * 0.05, 0),
      browPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx + eyeSpacing, browY);
    canvas.rotate(browTilt);
    canvas.drawLine(
      Offset(-w * 0.05, 0),
      Offset(w * 0.05, 0),
      browPaint,
    );
    canvas.restore();

    final mouthY = center.dy + h * 0.13;
    final mouthWidth = w * 0.18;
    final mouthCurve = mood * h * 0.08;

    final mouthPath = Path();
    mouthPath.moveTo(center.dx - mouthWidth, mouthY);
    mouthPath.quadraticBezierTo(
      center.dx,
      mouthY + mouthCurve,
      center.dx + mouthWidth,
      mouthY,
    );

    final mouthPaint = Paint()
      ..color = const Color(0xFF0F0F0F)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(mouthPath, mouthPaint);

    if (mood > 0.5) {
      final sparkleOpacity = ((mood - 0.5) * 2).clamp(0.0, 1.0);
      for (int i = 0; i < 5; i++) {
        final angle = (i / 5) * 2 * pi + sparkleT;
        final r = w * 0.55 + sin(sparkleT + i) * 8;
        final sx = center.dx + cos(angle) * r;
        final sy = center.dy + sin(angle) * r;
        final sparkleSize = 3.0 + sin(sparkleT * 2 + i) * 2;
        canvas.drawCircle(
          Offset(sx, sy),
          sparkleSize,
          Paint()..color = const Color(0xFFFFD700).withOpacity(sparkleOpacity),
        );
      }
    }

    if (mood < -0.4) {
      final rainOpacity = ((-mood - 0.4) * 2).clamp(0.0, 1.0);
      for (int i = 0; i < 6; i++) {
        final dropX = center.dx - w * 0.35 + (i * w * 0.14);
        final dropY = center.dy + h * 0.35 + (sparkleT * 15 + i * 10) % 40;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(dropX, dropY), width: 4, height: 8),
          Paint()..color = const Color(0xFF6BA6D6).withOpacity(rainOpacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MorphingFacePainter old) =>
      old.mood != mood || old.sparkleT != sparkleT;
}

// ══════════════════════════════════════════════════════════════════
// PATTERN PAINTERS — visible on dark
// ══════════════════════════════════════════════════════════════════

class _GridPatternPainter extends CustomPainter {
  final double t;
  _GridPatternPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.04);
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint..strokeWidth = 0.5);
    }
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint..strokeWidth = 0.5);
    }
  }
  @override
  bool shouldRepaint(covariant _GridPatternPainter old) => old.t != t;
}

class _RingEchoesPatternPainter extends CustomPainter {
  final double t;
  _RingEchoesPatternPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 8; i++) {
      final r = i * 30.0 + sin(t + i) * 3;
      canvas.drawCircle(center, r, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _RingEchoesPatternPainter old) => old.t != t;
}

class _DiagonalShimmerPatternPainter extends CustomPainter {
  final double t;
  _DiagonalShimmerPatternPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.035)..strokeWidth = 0.6;
    for (double x = -size.height; x < size.width; x += 16) {
      final shift = sin(t + x * 0.02) * 4;
      canvas.drawLine(
        Offset(x + shift, 0),
        Offset(x + size.height + shift, size.height),
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant _DiagonalShimmerPatternPainter old) => old.t != t;
}

class _PulsingEyePatternPainter extends CustomPainter {
  final double t;
  _PulsingEyePatternPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.5);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 5; i++) {
      final r = i * 20.0 + sin(t + i) * 4;
      canvas.drawCircle(center, r, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _PulsingEyePatternPainter old) => old.t != t;
}

class _RadarPatternPainter extends CustomPainter {
  final double t;
  final bool active;
  _RadarPatternPainter({required this.t, required this.active});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.3);
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, i * 22.0, ringPaint);
    }
    if (active) {
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          startAngle: t,
          endAngle: t + pi / 3,
          colors: [
            const Color(0xFF10B981).withOpacity(0.0),
            const Color(0xFF10B981).withOpacity(0.2),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 130));
      canvas.drawCircle(center, 130, sweepPaint);
    }
  }
  @override
  bool shouldRepaint(covariant _RadarPatternPainter old) => old.t != t || old.active != active;
}

class _WaveLinesPatternPainter extends CustomPainter {
  final double t;
  _WaveLinesPatternPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 0.6;
    for (double y = 20; y < size.height; y += 20) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 4) {
        final wave = sin(x * 0.03 + t + y * 0.02) * 3;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _WaveLinesPatternPainter old) => old.t != t;
}