import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/user.dart';
import 'package:inventory_frontend/utils/api.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('users');
      
      _users = List<User>.from(
        response.map((x) => User.fromJson(x))
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> createUser(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.post('users', userData);
      
      final newUser = User.fromJson(response);
      _users.add(newUser);
      
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
  
  Future<bool> updateUser(String id, Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.put('users/$id', userData);
      
      final updatedUser = User.fromJson(response);
      final index = _users.indexWhere((user) => user.id == id);
      
      if (index != -1) {
        _users[index] = updatedUser;
      }
      
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
  
  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await Api.delete('users/$id');
      
      _users.removeWhere((user) => user.id == id);
      
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
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
