import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventory_frontend/utils/storage.dart';
import 'package:inventory_frontend/config.dart' as config;

class Api {
  static String baseUrl = config.baseUrl;
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await Storage.getToken();
    print('API: Token retrieved: ${token != null ? 'Present' : 'Missing'}');
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
    
    print('API: Headers prepared: $headers');
    return headers;
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
    print('API POST Request: $baseUrl/$endpoint');
    print('API POST Data: $data');
    print('API POST Headers: $headers');
    
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    
    print('API POST Response Status: ${response.statusCode}');
    print('API POST Response Body: ${response.body}');
    
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
    print('API Response Status: ${response.statusCode}');
    print('API Response Headers: ${response.headers}');
    print('API Response Body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print('API Error parsing JSON: $e');
        throw Exception('Invalid JSON response from server');
      }
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Server error: ${response.statusCode}');
      } catch (e) {
        print('API Error parsing error response: $e');
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    }
  }
}
