// lib/utils/json_parser.dart
import 'dart:convert';

// ✅ Top-level function, class ke andar nahi
List<dynamic> parseJson(String jsonString) {
  return jsonDecode(jsonString) as List<dynamic>;
}
