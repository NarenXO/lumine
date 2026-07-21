import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../services/api_service.dart';
import '../services/tts_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
 
  final Random _random = Random();
  Timer? _ambientTimer;

  // ─── Lifestyle sliders ───────────────────────────────
  double _sleep = 6;
  double _stress = 4;
  double _social = 5;
  double _rest = 6;

  // ─── Biometric signals (wearable simulation) ─────────
  int _heartRate = 72;
  double _hrv = 58; // ms — higher = healthier
  int _spo2 = 97; // blood oxygen %
  double _skinTemp = 36.6; // celsius
  int _steps = 3200;
  double _activityLevel = 0.3; // 0.0 calm → 1.0 intense

  // ─── Derived ─────────────────────────────────────────
  double _stressScore = 0.2;
  bool _ambientMode = false;
  bool _loading = false;
  bool _triggered = false; // prevent rapid re-triggers

  String _insight = '';
  String _verse = '';
  String _verseRef = '';

  // ─── Wearable status label ────────────────────────────
  String get _heartRateLabel {
    if (_heartRate < 60) return 'Low';
    if (_heartRate < 85) return 'Normal';
    if (_heartRate < 100) return 'Elevated';
    return 'High';
  }

  String get _activityLabel {
    if (_activityLevel < 0.2) return 'Sedentary';
    if (_activityLevel < 0.5) return 'Light';
    if (_activityLevel < 0.75) return 'Moderate';
    return 'Intense';
  }

  Color get _heartRateColor {
    if (_heartRate < 85) return Colors.greenAccent;
    if (_heartRate < 100) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  // ─── Compute stress score from all signals ────────────
  void _computeStress() {
    double hrScore = (_heartRate - 60) / 80;
    double hrvScore = 1.0 - (_hrv / 100); // low HRV = more stress
    double spo2Score = (100 - _spo2) / 10;
    double tempScore = (_skinTemp - 36.0) / 2;
    double actScore = _activityLevel * 0.3;

    _stressScore = ((hrScore + hrvScore + spo2Score + tempScore + actScore) / 5)
        .clamp(0.0, 1.0);
  }

  // ─── Ambient mode ─────────────────────────────────────
  void _startAmbient() {
    _ambientTimer?.cancel();
    _ambientTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        // natural drift
        _heartRate += _random.nextInt(5) - 2;
        _heartRate = _heartRate.clamp(55, 140);

        _hrv += _random.nextDouble() * 4 - 2;
        _hrv = _hrv.clamp(20, 90);

        _spo2 += _random.nextInt(3) - 1;
        _spo2 = _spo2.clamp(92, 100);

        _skinTemp += (_random.nextDouble() * 0.2) - 0.1;
        _skinTemp = _skinTemp.clamp(35.5, 38.5);

        _steps += _random.nextInt(60);

        _activityLevel += (_random.nextDouble() * 0.1) - 0.05;
        _activityLevel = _activityLevel.clamp(0.0, 1.0);

        // occasional spike
        if (_random.nextDouble() > 0.80) {
          _heartRate = 105 + _random.nextInt(20);
          _hrv = 25 + _random.nextDouble() * 10;
          _activityLevel = 0.8 + _random.nextDouble() * 0.2;
        }

        _computeStress();
      });

      // auto sacred trigger
      if (_stressScore > 0.72 && !_triggered) {
        _triggered = true;
        _autoSacredResponse();

        // cooldown — don't trigger again for 30s
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) setState(() => _triggered = false);
        });
      }
    });
  }

  void _stopAmbient() {
    _ambientTimer?.cancel();
  }

  void _autoSacredResponse() async {
    const verses = [
      "Be still, and know that I am God. — Psalm 46:10",
      "Cast all your anxiety on Him because He cares for you. — 1 Peter 5:7",
      "Come to me, all who are weary and burdened. — Matthew 11:28",
      "The Lord is my shepherd; I shall not want. — Psalm 23:1",
      "Peace I leave with you; my peace I give you. — John 14:27",
    ];

    final verse = verses[_random.nextInt(verses.length)];

    await TtsService.speak(verse);

    if (mounted) {
      setState(() {
        _verse = verse;
        _verseRef = '';
        _insight =
            'Lumíne detected elevated stress in your biometrics. Scripture was delivered automatically.';
      });

      _showSacredSnackbar(verse);
    }
  }

  void _showSacredSnackbar(String verse) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A0A2E),
        duration: const Duration(seconds: 5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✦ Sacred Interruption',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              verse,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Manual spike for demo ────────────────────────────
  void _simulateStressSpike() {
    setState(() {
      _heartRate = 112 + _random.nextInt(15);
      _hrv = 22 + _random.nextDouble() * 8;
      _spo2 = 93 + _random.nextInt(2);
      _skinTemp = 37.4 + _random.nextDouble() * 0.6;
      _activityLevel = 0.85;
      _computeStress();
    });
    _autoSacredResponse();
  }

  void _simulateCalm() {
    setState(() {
      _heartRate = 62 + _random.nextInt(6);
      _hrv = 65 + _random.nextDouble() * 10;
      _spo2 = 98;
      _skinTemp = 36.5;
      _activityLevel = 0.15;
      _computeStress();
    });
  }

  // ─── API call ─────────────────────────────────────────
  Future<void> _analyzeHabits() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.analyzeHabits(
        sleep: _sleep,
        stress: _stress,
        social: _social,
        rest: _rest,
        heartRate: _heartRate,
        activityLevel: _activityLevel,
      );
      setState(() {
        _insight = result['insight'] ?? 'No insight received.';
        _verse = result['verse'] ?? '';
        _verseRef = result['reference'] ?? '';
        _loading = false;
      });
      if (_verse.isNotEmpty) {
       await TtsService.speak(_verse);
      }
    } catch (e) {
      setState(() {
        _insight = 'Connection error. Try again.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _ambientTimer?.cancel();
    super.dispose();
  }

  // ─── UI ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0520),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Spiritual Habits Mirror',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your body. Your rhythms. Your Scripture.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),

              const SizedBox(height: 24),

              // ── Wearable Panel ──────────────────────────
              _sectionLabel('⌚ Wearable Signals'),
              const SizedBox(height: 12),

              // Ambient toggle
              _ambientToggle(),

              const SizedBox(height: 16),

              // Biometric grid
              _biometricGrid(),

              const SizedBox(height: 12),

              // Activity level bar
              _activityBar(),

              const SizedBox(height: 12),

              // Stress score
              _stressBar(),

              const SizedBox(height: 12),

              // Demo buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _simulateStressSpike,
                      icon: const Icon(Icons.favorite, color: Colors.white),
                      label: const Text('Simulate Stress Spike'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _simulateCalm,
                      icon: const Icon(Icons.self_improvement,
                          color: Colors.white),
                      label: const Text('Simulate Calm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Lifestyle Sliders ───────────────────────
              _sectionLabel('🌙 Daily Lifestyle'),
              const SizedBox(height: 12),
              _slider('Sleep', _sleep, 3, 10, (v) => setState(() => _sleep = v),
                  '${_sleep.toStringAsFixed(1)} hrs'),
              _slider(
                  'Stress',
                  _stress,
                  1,
                  10,
                  (v) => setState(() => _stress = v),
                  '${_stress.toStringAsFixed(0)} / 10'),
              _slider(
                  'Social',
                  _social,
                  1,
                  10,
                  (v) => setState(() => _social = v),
                  '${_social.toStringAsFixed(0)} / 10'),
              _slider('Rest', _rest, 1, 10, (v) => setState(() => _rest = v),
                  '${_rest.toStringAsFixed(1)} hrs'),

              const SizedBox(height: 24),

              // Analyze button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _analyzeHabits,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B3FA0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Analyze My Rhythms',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── AI Insight ─────────────────────────────
              if (_insight.isNotEmpty) ...[
                _sectionLabel('✦ Lumíne Insight'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF6B3FA0).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    _insight,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ],

              if (_verse.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A0A4E), Color(0xFF1A0A2E)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✦ Scripture for Your Moment',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"$_verse"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),
                      if (_verseRef.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '— $_verseRef',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widget Helpers ───────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD4AF37),
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _ambientToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _ambientMode
              ? const Color(0xFF6B3FA0)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.watch_rounded,
            color: _ambientMode ? const Color(0xFF6B3FA0) : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto Ambient Mode',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  _ambientMode
                      ? 'Lumíne is watching your signals...'
                      : 'Tap to let Lumíne monitor automatically',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: _ambientMode,
            activeColor: const Color(0xFF6B3FA0),
            onChanged: (val) {
              setState(() => _ambientMode = val);
              val ? _startAmbient() : _stopAmbient();
            },
          ),
        ],
      ),
    );
  }

  Widget _biometricGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _bioCard('❤️ Heart Rate', '$_heartRate bpm', _heartRateLabel,
            _heartRateColor),
        _bioCard('💧 HRV', '${_hrv.toStringAsFixed(0)} ms',
            _hrv > 50 ? 'Healthy' : 'Low', _hrv > 50 ? Colors.greenAccent : Colors.orangeAccent),
        _bioCard('🌡 Skin Temp', '${_skinTemp.toStringAsFixed(1)}°C',
            _skinTemp > 37.2 ? 'Warm' : 'Normal',
            _skinTemp > 37.2 ? Colors.orangeAccent : Colors.blueAccent),
        _bioCard('🩸 SpO₂', '$_spo2%', _spo2 >= 96 ? 'Normal' : 'Low',
            _spo2 >= 96 ? Colors.greenAccent : Colors.redAccent),
      ],
    );
  }

  Widget _bioCard(
      String label, String value, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          Text(status, style: TextStyle(color: statusColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _activityBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🏃 Activity — $_activityLabel',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('$_steps steps',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _activityLevel,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              _activityLevel > 0.7 ? Colors.orangeAccent : Colors.greenAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stressBar() {
    final pct = (_stressScore * 100).toStringAsFixed(0);
    final color = _stressScore > 0.7
        ? Colors.redAccent
        : _stressScore > 0.4
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('⚡ Biometric Stress Score',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            Text('$pct%', style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _stressScore,
            minHeight: 10,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        if (_stressScore > 0.72)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              '⚠ Sacred Interruption threshold reached',
              style: TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged, String display) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(display,
                  style: const TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 12)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: const Color(0xFF6B3FA0),
            inactiveColor: Colors.white12,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}