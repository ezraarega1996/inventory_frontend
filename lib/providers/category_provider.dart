import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/category.dart';
import 'package:inventory_frontend/utils/api.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('categories');
      
      _categories = List<Category>.from(
        response.map((x) => Category.fromJson(x))
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> createCategory(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.post('categories', {'name': name});
      
      final newCategory = Category.fromJson(response);
      _categories.add(newCategory);
      
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
  
  Future<bool> updateCategory(String id, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.put('categories/$id', {'name': name});
      
      final updatedCategory = Category.fromJson(response);
      final index = _categories.indexWhere((category) => category.id == id);
      
      if (index != -1) {
        _categories[index] = updatedCategory;
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
  
  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await Api.delete('categories/$id');
      
      _categories.removeWhere((category) => category.id == id);
      
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
