import 'package:flutter/material.dart';

class SacredInterruptionScreen extends StatelessWidget {
  final String scriptureText;
  final String scriptureRef;

  const SacredInterruptionScreen({
    super.key,
    required this.scriptureText,
    required this.scriptureRef,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pause.",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Breathe. Listen.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "\"$scriptureText\"",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "— $scriptureRef",
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("I am here."),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}