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
    print('Fetching users...');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('users');
      print('Users fetched successfully');
      // Ensure response is a List<dynamic> and parse each item explicitly
      final List<User> loadedUsers = [];
      if (response is List) {
        for (var item in response) {
          loadedUsers.add(User.fromJson(item as Map<String, dynamic>));
        }
      }
      _users = loadedUsers;
      print('Users loaded: \\${_users.length}');
      _isLoading = false;
      print("loading ended");
      notifyListeners();
      print("isLoadingProvider: $_isLoading");
    } catch (e) {
      print('Error fetching users: $e');
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
