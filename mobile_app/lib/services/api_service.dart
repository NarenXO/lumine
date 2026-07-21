import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> analyzeHabits({
  required double sleep,
  required double stress,
  required double social,
  required double rest,
}) async {
  final response = await http.post(
    Uri.parse("https://lumine-backend-420v.onrender.com/habits"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "sleep": sleep,
      "stress": stress,
      "social": social,
      "rest": rest,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Habits endpoint error");
  }
}
  static Future<Map<String, dynamic>> analyzeMessage(String message) async {
    final response = await http.post(
      Uri.parse("https://lumine-backend-420v.onrender.com/analyze"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to connect to backend");
    }
  }

static Future<Map<String, dynamic>> getResonance() async {
  final response = await http.get(
    Uri.parse("https://lumine-backend-420v.onrender.com/resonance"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Resonance endpoint error");
  }
}


}