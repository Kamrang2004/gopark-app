import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gopark_app/core/constants.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          debugPrint('JSON Decode Error. Raw body: ${response.body}');
          return {'status': 'error', 'message': 'Invalid Server Response: ${response.body}'};
        }
      } else {
        return {'status': 'error', 'message': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('Connection Error: $e');
      return {'status': 'error', 'message': 'Connection Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          debugPrint('JSON Decode Error. Raw body: ${response.body}');
          return {'status': 'error', 'message': 'Invalid Server Response: ${response.body}'};
        }
      } else {
        return {'status': 'error', 'message': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('Connection Error: $e');
      return {'status': 'error', 'message': 'Connection Error: $e'};
    }
  }
}
