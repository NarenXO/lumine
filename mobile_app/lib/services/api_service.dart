import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> analyzeMessage(String message) async {
    final response = await http.post(
      Uri.parse("http://192.168.0.4:8000/analyze"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to connect to backend");
    }
  }
}