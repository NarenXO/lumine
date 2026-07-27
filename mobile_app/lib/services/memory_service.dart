import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  static const String _kChatHistory = 'lumine_chat_history';
  static const String _kMemoryProfile = 'lumine_memory_profile';
  static const String _kLastAssistantReplies = 'lumine_last_replies';
  static const String _kUserNotes = 'lumine_user_notes';

  // ─── Chat history persistence ─────────────────────────────
  static Future<List<Map<String, String>>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kChatHistory);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChatHistory(List<Map<String, String>> history) async {
    final prefs = await SharedPreferences.getInstance();
    // Cap at 200 messages to keep storage sane
    final capped = history.length > 200
        ? history.sublist(history.length - 200)
        : history;
    await prefs.setString(_kChatHistory, jsonEncode(capped));
  }

  static Future<void> appendMessage(String user, String lumine) async {
    final history = await loadChatHistory();
    history.add({'user': user, 'lumine': lumine});
    await saveChatHistory(history);
  }

  static Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kChatHistory);
  }

  // ─── Rolling memory profile (summarized themes) ───────────
  static Future<Map<String, dynamic>> loadMemoryProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMemoryProfile);
    if (raw == null) {
      return {
        'themes': [],
        'recurring_struggles': [],
        'milestones': [],
        'preferred_tone': 'warm',
        'spiritual_focus_areas': [],
        'last_summarized_at': null,
        'message_count_at_last_summary': 0,
      };
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {
        'themes': [],
        'recurring_struggles': [],
        'milestones': [],
        'preferred_tone': 'warm',
        'spiritual_focus_areas': [],
        'last_summarized_at': null,
        'message_count_at_last_summary': 0,
      };
    }
  }

  static Future<void> saveMemoryProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMemoryProfile, jsonEncode(profile));
  }

  // ─── Last N assistant replies (for repetition avoidance) ─
  static Future<List<String>> loadLastReplies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastAssistantReplies);
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  static Future<void> pushLastReply(String reply) async {
    final list = await loadLastReplies();
    list.add(reply);
    // Keep last 10
    final capped = list.length > 10 ? list.sublist(list.length - 10) : list;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastAssistantReplies, jsonEncode(capped));
  }

  // ─── User notes (personalized) ────────────────────────────
  static Future<Map<String, dynamic>> loadUserNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserNotes);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveUserNote(String key, dynamic value) async {
    final notes = await loadUserNotes();
    notes[key] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserNotes, jsonEncode(notes));
  }
}