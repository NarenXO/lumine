import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResonanceScreen extends StatefulWidget {
  const ResonanceScreen({super.key});

  @override
  State<ResonanceScreen> createState() => _ResonanceScreenState();
}

class _ResonanceScreenState extends State<ResonanceScreen> {
  Map<String, dynamic> _resonance = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchResonance();
  }

  Future<void> _fetchResonance() async {
    try {
      final data = await ApiService.getResonance();
      setState(() {
        _resonance = data["resonance"];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Resonance"),
        backgroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Themes that speak to you most",
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: _resonance.entries.map((e) {
                        int value = e.value ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.key,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    value.toString(),
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: (value / 10).clamp(0.0, 1.0),
                                backgroundColor: Colors.white10,
                                color: Colors.amberAccent,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _fetchResonance,
                      child: const Text(
                        "Refresh",
                        style: TextStyle(color: Colors.amberAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}