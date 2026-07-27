import 'package:flutter/material.dart';
import 'app_controller.dart';

class ThemeService {
  static Color getEmotionColor() {
    final emotion = AppController().currentEmotion.toLowerCase().trim();
    switch (emotion) {
      case "calm":       return const Color(0xFF3AB0FF); // vivid sky
      case "happy":      return const Color(0xFFFFC61E); // vivid gold
      case "sad":        return const Color(0xFF9B6BE0); // vivid lavender
      case "angry":      return const Color(0xFFFF4E3B); // vivid coral red
      case "hopeful":    return const Color(0xFF2ECBFF); // vivid cyan
      case "anxious":    return const Color(0xFFC661FF); // vivid violet
      case "grateful":   return const Color(0xFF34D97F); // vivid green
      case "stressed":   return const Color(0xFFFF8A2E); // vivid amber
      case "optimistic": return const Color(0xFFFFD500); // vivid sunny
      case "depressed":  return const Color(0xFF6B7A93); // deeper grey-blue
      case "crisis":     return const Color(0xFF9B1C1C); // deep alarm red
      case "neutral":    return const Color(0xFF3AB0FF); // fallback to calm
      default:           return const Color(0xFF3AB0FF);
    }
  }
}