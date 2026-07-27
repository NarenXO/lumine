import 'package:flutter/material.dart';
import 'app_controller.dart';

class ThemeService {
  // ═══════════════════════════════════════════════════════════
  // EMOTION ACCENT COLORS — luminous, glowing, dark-mode friendly
  // ═══════════════════════════════════════════════════════════
  static Color getEmotionColor() {
    final emotion = AppController().currentEmotion.toLowerCase().trim();
    switch (emotion) {
      case "calm":       return const Color(0xFF7BA9F0); // soft sky glow
      case "happy":      return const Color(0xFFFFD470); // warm amber
      case "sad":        return const Color(0xFFB8A0E8); // dusty lavender
      case "angry":      return const Color(0xFFFF7C6B); // warm coral
      case "hopeful":    return const Color(0xFF6BC5D9); // pale cyan dawn
      case "anxious":    return const Color(0xFFC688F0); // soft violet
      case "grateful":   return const Color(0xFF7DD69F); // mint sage
      case "stressed":   return const Color(0xFFFFA560); // golden amber
      case "optimistic": return const Color(0xFFFFDF80); // sunrise gold
      case "depressed":  return const Color(0xFF8FA0B8); // pewter mist
      case "crisis":     return const Color(0xFFFF8080); // alert soft red
      case "neutral":    return const Color(0xFF7BA9F0);
      default:           return const Color(0xFF7BA9F0);
    }
  }
}