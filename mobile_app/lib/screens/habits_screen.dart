import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  double sleep = 6;
  double stress = 5;
  double social = 5;
  double rest = 5;

  String? _resultMessage;
  String? _scriptureText;
  String? _scriptureRef;
  bool _loading = false;

  Future<void> _analyzeHabits() async {
    setState(() {
      _loading = true;
      _resultMessage = null;
    });

    try {
      final result = await ApiService.analyzeHabits(
        sleep: sleep,
        stress: stress,
        social: social,
        rest: rest,
      );

      setState(() {
        _resultMessage = result["insight"];
        _scriptureText = result["scripture"]["text"];
        _scriptureRef = result["scripture"]["reference"];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = "Connection error.";
        _loading = false;
      });
    }
  }

  Widget _buildSlider(String label, double value, Function(double) onChanged,
      double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ${value.toStringAsFixed(1)}",
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        Slider(
          min: min,
          max: max,
          value: value,
          activeColor: Colors.amberAccent,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Spiritual Habits Mirror"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reflect on your day",
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSlider("Sleep (hours)", sleep,
                (v) => setState(() => sleep = v), 0, 12),
            _buildSlider("Stress Level", stress,
                (v) => setState(() => stress = v), 0, 10),
            _buildSlider("Social Interaction", social,
                (v) => setState(() => social = v), 0, 10),
            _buildSlider("Rest Quality", rest,
                (v) => setState(() => rest = v), 0, 10),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _loading ? null : _analyzeHabits,
                child: Text(_loading ? "Analyzing..." : "Reflect"),
              ),
            ),
            const SizedBox(height: 20),
            if (_resultMessage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _resultMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_scriptureText != null)
                    Text(
                      "\"$_scriptureText\"\n— $_scriptureRef",
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}