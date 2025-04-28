import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/utils/api.dart';

class ItemProvider with ChangeNotifier {
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;
  
  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('items');
      
      _items = List<Item>.from(
        response.map((x) => Item.fromJson(x))
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> createItem(String name, String categoryId, List<Map<String, dynamic>> fractions) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.post('items', {
        'name': name,
        'categoryId': categoryId,
        'fractions': fractions,
      });
      
      final newItem = Item.fromJson(response);
      _items.add(newItem);
      
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
  
  Future<bool> updateItem(String id, String name, String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.put('items/$id', {
        'name': name,
        'categoryId': categoryId,
      });
      
      final updatedItem = Item.fromJson(response);
      final index = _items.indexWhere((item) => item.id == id);
      
      if (index != -1) {
        _items[index] = updatedItem;
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
  
  Future<bool> deleteItem(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await Api.delete('items/$id');
      
      _items.removeWhere((item) => item.id == id);
      
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
  
  Future<bool> createFraction(String itemId, String name, double ratio, double price, {bool isUnit = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.post('fractions', {
        'itemId': itemId,
        'name': name,
        'ratio': ratio,
        'price': price,
        'isUnit': isUnit,
      });
      
      final newFraction = Fraction.fromJson(response);
      
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        final item = _items[index];
        final fractions = item.fractions?.toList() ?? [];
        fractions.add(newFraction);
        
        _items[index] = Item(
          id: item.id,
          name: item.name,
          categoryId: item.categoryId,
          category: item.category,
          fractions: fractions,
        );
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
  
  Future<bool> updateFraction(String id, String name, double ratio, double price, {bool isUnit = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.put('fractions/$id', {
        'name': name,
        'ratio': ratio,
        'price': price,
        'isUnit': isUnit,
      });
      
      final updatedFraction = Fraction.fromJson(response);
      
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.fractions != null) {
          final fractionIndex = item.fractions!.indexWhere((f) => f.id == id);
          if (fractionIndex != -1) {
            final fractions = item.fractions!.toList();
            fractions[fractionIndex] = updatedFraction;
            
            _items[i] = Item(
              id: item.id,
              name: item.name,
              categoryId: item.categoryId,
              category: item.category,
              fractions: fractions,
            );
            break;
          }
        }
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
  
  Future<bool> deleteFraction(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await Api.delete('fractions/$id');
      
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.fractions != null) {
          final fractionIndex = item.fractions!.indexWhere((f) => f.id == id);
          if (fractionIndex != -1) {
            final fractions = item.fractions!.toList();
            fractions.removeAt(fractionIndex);
            
            _items[i] = Item(
              id: item.id,
              name: item.name,
              categoryId: item.categoryId,
              category: item.category,
              fractions: fractions,
            );
            break;
          }
        }
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
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
