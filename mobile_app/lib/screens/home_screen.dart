
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class LumineHome extends StatelessWidget {
  const LumineHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Lumíne",
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.bold,
          color: Colors.amberAccent,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        "Spiritual Operating System",
        style: TextStyle(
          fontSize: 18,
          color: Colors.white70,
        ),
      ),
      const SizedBox(height: 40),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.amberAccent,
            foregroundColor: Colors.black,
          ),
          onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const DashboardScreen(),
    ),
  );
},
          child: const Text(
            "Enter Lumíne",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    ],
  ),
)
    );
  }
}    
  
