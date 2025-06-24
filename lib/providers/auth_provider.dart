import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
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
  
  AuthProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await checkAuth();
  }
  
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = await Storage.getToken();
      final userData = await Storage.getUser();
      
      if (token != null && userData != null) {
        _user = User.fromJson(userData);
        _isAuthenticated = true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> login(String username, String password) async {
    print('AuthProvider: login called with username: $username');
    
    if (username.isEmpty || password.isEmpty) {
      _error = 'Username and password are required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('AuthProvider: Making API call to auth/login');
      final response = await Api.post('auth/login', {
        'username': username,
        'password': password,
      });

      print('AuthProvider: Received response: $response');

      if (response == null || response['token'] == null || response['user'] == null) {
        _error = 'Invalid response from server';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final token = response['token'];
      final userData = response['user'];
      
      print('AuthProvider: Saving token and user data');
      await Storage.saveToken(token);
      await Storage.saveUser(userData);
      
      _user = User.fromJson(userData);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      
      print('AuthProvider: Login successful for user: ${_user?.name}');
      return true;
    } on FormatException catch (e) {
      print('AuthProvider: FormatException: $e');
      _error = 'Invalid response format from server';
    } on SocketException catch (e) {
      print('AuthProvider: SocketException: $e');
      _error = 'No internet connection';
    } on HttpException catch (e) {
      print('AuthProvider: HttpException: $e');
      _error = e.message;
    } catch (e) {
      print('AuthProvider: Unexpected error: $e');
      _error = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return false;
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
