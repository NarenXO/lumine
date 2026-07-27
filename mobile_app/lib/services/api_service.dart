import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://lumine-backend-420v.onrender.com';

  static final List<String> _usedVerseRefs = [];

  // ─── UPGRADED chat endpoint ─────────────────────────────────
  static Future<Map<String, dynamic>> analyzeMessage(
    String text, {
    List<Map<String, String>>? recentHistory,
    Map<String, dynamic>? memoryProfile,
    Map<String, dynamic>? appContext,
    List<String>? lastReplies,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'recent_history': recentHistory ?? [],
        'memory_profile': memoryProfile ?? {},
        'app_context': appContext ?? {},
        'last_replies': lastReplies ?? [],
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze message');
    }
  }

  // ─── NEW: summarize chat history into memory profile ────────
  static Future<Map<String, dynamic>> summarizeMemory({
    required List<Map<String, String>> chatHistory,
    required Map<String, dynamic> currentProfile,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/summarize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chat_history': chatHistory,
        'current_profile': currentProfile,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return currentProfile;
  }

  static Future<Map<String, dynamic>> getJournal({
    required List<Map<String, dynamic>> emotions,
    required int interruptions,
    required int spikes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/journal'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'emotions': emotions,
        'interruptions': interruptions,
        'spikes': spikes,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate journal');
    }
  }

  static Future<Map<String, dynamic>> getSoulMap({
    required String topEmotion,
    required String anchorVerse,
    required int anchorCount,
    required int recoveryMinutes,
    required int stressSpikes,
    required Map<String, String> pattern,
    required int interruptions,
    required int daysActive,
    List<String> recentEmotions = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/soulmap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'top_emotion': topEmotion,
        'anchor_verse': anchorVerse,
        'anchor_count': anchorCount,
        'recovery_minutes': recoveryMinutes,
        'stress_spikes': stressSpikes,
        'pattern': pattern,
        'interruptions': interruptions,
        'days_active': daysActive,
        'recent_emotions': recentEmotions,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate soul map');
    }
  }

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

  static Future<Map<String, dynamic>> getZenVerse({
    required String theme,
    required String emotion,
  }) async {
    try {
      final seeds = [
        'morning', 'evening', 'night', 'stillness', 'movement',
        'breath', 'waiting', 'journey', 'rest', 'renewal',
        'courage', 'surrender', 'presence', 'light', 'shadow',
      ];
      final seed = seeds[DateTime.now().millisecond % seeds.length];

      final response = await http.post(
        Uri.parse('$baseUrl/zen'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'theme': theme,
          'emotion': emotion,
          'seed': seed,
          'used_refs': _usedVerseRefs.take(10).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ref = data['ref'] ?? '';
        if (ref.isNotEmpty && !_usedVerseRefs.contains(ref)) {
          _usedVerseRefs.add(ref);
          if (_usedVerseRefs.length > 30) _usedVerseRefs.removeAt(0);
        }
        return data;
      } else {
        throw Exception('Zen fetch failed');
      }
    } catch (e) {
      return {
        'verse': 'Be still and know that I am God.',
        'ref': 'Psalm 46:10',
        'narration': '',
      };
    }
  }
}