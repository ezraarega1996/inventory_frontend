import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_frontend/utils/storage.dart';

class Api {
  static String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await Storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }
  
  static Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
    
    return _handleResponse(response);
  }
  
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    
    return _handleResponse(response);
  }
  
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    
    return _handleResponse(response);
  }
  
  static Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
    
    return _handleResponse(response);
  }
  
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Unknown error occurred');
    }
  }
}
