import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LumineApp());
}

class LumineApp extends StatelessWidget {
  const LumineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumíne',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1A1A2E),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        fontFamily: 'Roboto',
      ),
      home: const LumineHome(),
    );
  }
}
