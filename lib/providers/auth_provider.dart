import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/user.dart';
import 'package:inventory_frontend/utils/api.dart';
import 'package:inventory_frontend/utils/storage.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isOwner => _user?.role == 'owner';
  bool get isAdmin => _user?.role == 'admin';
  
  Future<void> checkAuth() async {
    final token = await Storage.getToken();
    final userData = await Storage.getUser();
    
    if (token != null && userData != null) {
      _user = User.fromJson(userData);
      _isAuthenticated = true;
      notifyListeners();
    }
  }
  
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.post('auth/login', {
        'username': username,
        'password': password,
      });
      
      final token = response['token'];
      final userData = response['user'];
      
      await Storage.saveToken(token);
      await Storage.saveUser(userData);
      
      _user = User.fromJson(userData);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.post('auth/register', userData);
      
      final token = response['token'];
      final user = response['user'];
      
      await Storage.saveToken(token);
      await Storage.saveUser(user);
      
      _user = User.fromJson(user);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> registerBusiness(Map<String, dynamic> businessData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.post('businesses', businessData);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await Storage.clearAll();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
