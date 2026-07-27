import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  static int sacredInterruptions = 0;
  static int versesReceived = 0;
  static int habitsChecked = 0;
  static int streakDays = 1;

  static List<Map<String, String>> savedVerses = [];

  // ─── Soul Map Data ────────────────────────────────
  static List<Map<String, dynamic>> emotionHistory = [];
  static List<Map<String, dynamic>> verseHistory = [];
  static List<Map<String, dynamic>> stressSpikes = [];
  static DateTime? lastStressTime;
  static DateTime? lastCalmTime;
  static List<int> recoveryTimesMinutes = [];

  // ─── Journal + Fingerprint ────────────────────────
  static String todayJournal = "";
  static bool journalLoading = false;
  static String glooFingerprint = "";
  static bool fingerprintLoading = false;

  // ─── Save all data ────────────────────────────────
  static Future<void> saveAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('sacredInterruptions', sacredInterruptions);
    await prefs.setInt('versesReceived', versesReceived);
    await prefs.setInt('habitsChecked', habitsChecked);
    await prefs.setInt('streakDays', streakDays);

    await prefs.setString('savedVerses', jsonEncode(savedVerses));
    await prefs.setString('emotionHistory', jsonEncode(emotionHistory));
    await prefs.setString('verseHistory', jsonEncode(verseHistory));
    await prefs.setString('stressSpikes', jsonEncode(stressSpikes));
    await prefs.setString('recoveryTimes', jsonEncode(recoveryTimesMinutes));
    await prefs.setString('todayJournal', todayJournal);
    await prefs.setString('glooFingerprint', glooFingerprint);
  }

  // ─── Load all data ────────────────────────────────
  static Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    sacredInterruptions = prefs.getInt('sacredInterruptions') ?? 0;
    versesReceived = prefs.getInt('versesReceived') ?? 0;
    habitsChecked = prefs.getInt('habitsChecked') ?? 0;
    streakDays = prefs.getInt('streakDays') ?? 1;

    final sv = prefs.getString('savedVerses');
    if (sv != null) {
      savedVerses = (jsonDecode(sv) as List)
          .map((e) => Map<String, String>.from(e))
          .toList();
    }

    final eh = prefs.getString('emotionHistory');
    if (eh != null) {
      emotionHistory = (jsonDecode(eh) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final vh = prefs.getString('verseHistory');
    if (vh != null) {
      verseHistory = (jsonDecode(vh) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final ss = prefs.getString('stressSpikes');
    if (ss != null) {
      stressSpikes = (jsonDecode(ss) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final rt = prefs.getString('recoveryTimes');
    if (rt != null) {
      recoveryTimesMinutes = (jsonDecode(rt) as List)
          .map((e) => e as int)
          .toList();
    }

    todayJournal = prefs.getString('todayJournal') ?? "";
    glooFingerprint = prefs.getString('glooFingerprint') ?? "";
  }

  // ─── Existing Methods (now with auto-save) ────────

  static void addSacredInterruption() {
    sacredInterruptions++;
    saveAll();
  }

  static void addVerseReceived() {
    versesReceived++;
    saveAll();
  }

  static void addHabitsChecked() {
    habitsChecked++;
    saveAll();
  }

  static void saveVerse(String text, String reference) {
    final exists = savedVerses.any((v) => v["ref"] == reference);
    if (!exists) {
      savedVerses.insert(0, {"text": text, "ref": reference});
      saveAll();
    }
  }

  static void removeVerse(String reference) {
    savedVerses.removeWhere((v) => v["ref"] == reference);
    saveAll();
  }

  static bool isVerseSaved(String reference) {
    return savedVerses.any((v) => v["ref"] == reference);
  }

  // ─── Soul Map Methods (now with auto-save) ────────

  static void recordEmotion(String emotion) {
    emotionHistory.add({
      "emotion": emotion,
      "time": DateTime.now().toIso8601String(),
      "hour": DateTime.now().hour,
    });
    if (emotionHistory.length > 100) emotionHistory.removeAt(0);
    saveAll();
  }

  static void recordVerse(String text, String reference) {
    verseHistory.add({
      "text": text,
      "ref": reference,
      "time": DateTime.now().toIso8601String(),
    });
    if (verseHistory.length > 50) verseHistory.removeAt(0);
    saveAll();
  }

  static void recordStressSpike() {
    lastStressTime = DateTime.now();
    stressSpikes.add({
      "time": DateTime.now().toIso8601String(),
      "hour": DateTime.now().hour,
    });
    if (stressSpikes.length > 50) stressSpikes.removeAt(0);
    saveAll();
  }

  static void recordCalmRestored() {
    lastCalmTime = DateTime.now();
    if (lastStressTime != null) {
      final recovery =
          lastCalmTime!.difference(lastStressTime!).inMinutes;
      if (recovery > 0 && recovery < 120) {
        recoveryTimesMinutes.add(recovery);
        saveAll();
      }
    }
  }

  // ─── Soul Map Analytics ───────────────────────────

  static String getMostFrequentEmotion() {
    if (emotionHistory.isEmpty) return "calm";
    final counts = <String, int>{};
    for (var e in emotionHistory) {
      final em = e["emotion"] as String;
      counts[em] = (counts[em] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  static String getAnchorVerse() {
    if (verseHistory.isEmpty) return "";
    final counts = <String, int>{};
    for (var v in verseHistory) {
      final ref = v["ref"] as String;
      counts[ref] = (counts[ref] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  static int getAnchorVerseCount() {
    if (verseHistory.isEmpty) return 0;
    final anchor = getAnchorVerse();
    return verseHistory.where((v) => v["ref"] == anchor).length;
  }

  static String getAnchorVerseText() {
    if (verseHistory.isEmpty) return "";
    final anchor = getAnchorVerse();
    final entry = verseHistory.firstWhere(
      (v) => v["ref"] == anchor,
      orElse: () => {"text": "", "ref": ""},
    );
    return entry["text"] as String;
  }

  static int getAverageRecoveryMinutes() {
    if (recoveryTimesMinutes.isEmpty) return 0;
    final sum = recoveryTimesMinutes.reduce((a, b) => a + b);
    return (sum / recoveryTimesMinutes.length).round();
  }

  static Map<String, String> getTimeOfDayPattern() {
    final pattern = {
      "Morning": "Calm",
      "Afternoon": "Calm",
      "Evening": "Calm",
      "Night": "Calm",
    };

    if (emotionHistory.isEmpty) return pattern;

    final buckets = <String, List<String>>{
      "Morning": [],
      "Afternoon": [],
      "Evening": [],
      "Night": [],
    };

    for (var e in emotionHistory) {
      final hour = e["hour"] as int;
      final emotion = e["emotion"] as String;
      if (hour >= 5 && hour < 12) {
        buckets["Morning"]!.add(emotion);
      } else if (hour >= 12 && hour < 17) {
        buckets["Afternoon"]!.add(emotion);
      } else if (hour >= 17 && hour < 21) {
        buckets["Evening"]!.add(emotion);
      } else {
        buckets["Night"]!.add(emotion);
      }
    }

    for (var key in buckets.keys) {
      final list = buckets[key]!;
      if (list.isEmpty) continue;
      final counts = <String, int>{};
      for (var e in list) {
        counts[e] = (counts[e] ?? 0) + 1;
      }
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      pattern[key] = sorted.first.key;
    }

    return pattern;
  }

  static int getStressSpikesToday() {
    final today = DateTime.now();
    return stressSpikes.where((s) {
      final time = DateTime.parse(s["time"] as String);
      return time.year == today.year &&
          time.month == today.month &&
          time.day == today.day;
    }).length;
  }
}