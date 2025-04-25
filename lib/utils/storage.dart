import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  // Token methods
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  // User data methods
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userData.toString());
  }
  
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      // Convert string back to map
      return Map<String, dynamic>.from(userString as Map);
    }
    return null;
  }
  
  // Clear all data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
