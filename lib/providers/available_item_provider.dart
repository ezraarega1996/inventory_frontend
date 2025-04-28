import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'package:inventory_frontend/utils/api.dart';

class AvailableItemProvider with ChangeNotifier {
  List<AvailableItem> _availableItems = [];
  bool _isLoading = false;
  String? _error;
  
  List<AvailableItem> get availableItems => _availableItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchAvailableItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('available-items');
      
      _availableItems = List<AvailableItem>.from(
        response.map((x) => AvailableItem.fromJson(x))
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> calculateAvailableItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('available-items/calculate');
      
      _availableItems = List<AvailableItem>.from(
        response.map((x) => AvailableItem.fromJson(x))
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 