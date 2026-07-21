import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://lumine-backend-420v.onrender.com';

  // Used by chat_screen.dart
  static Future<Map<String, dynamic>> analyzeMessage(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze message');
    }
  }

  // Used by resonance_screen.dart
  static Future<Map<String, dynamic>> getResonance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/resonance'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get resonance');
    }
  }

  // Used by habits_screen.dart
  static Future<Map<String, dynamic>> analyzeHabits({
    required double sleep,
    required double stress,
    required double social,
    required double rest,
    int heartRate = 72,
    double activityLevel = 0.3,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/habits'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sleep': sleep,
        'stress': stress,
        'social': social,
        'rest': rest,
        'heart_rate': heartRate,
        'activity_level': activityLevel,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze habits');
    }
  }
}