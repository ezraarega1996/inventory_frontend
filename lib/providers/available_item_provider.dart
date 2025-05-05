import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'package:inventory_frontend/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_frontend/utils/api.dart';

class AvailableItemProvider with ChangeNotifier {
  List<AvailableItem> _availableItems = [];
  bool _isLoading = false;
  String? _error;
  
  List<AvailableItem> get availableItems => _availableItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get available items for a specific salesman
  List<AvailableItem> getAvailableItemsForSalesman(String salesmanId) {
    return _availableItems.where((item) => item.salesmanId == salesmanId).toList();
  }
  
  Future<void> fetchAvailableItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('available-items');
      // await http.get(
      //   Uri.parse('$baseUrl/available-items'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
      // );
      _availableItems = List<AvailableItem>.from(
        response.map((x) => AvailableItem.fromJson(x))
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAvailableItem({
    required String itemId,
    required double quantity,
    required double soldPrice,
    String? salesmanId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.post('available-items', {
        'itemId': itemId,
        'quantity': quantity,
        'soldPrice': soldPrice,
        'salesmanId': salesmanId,
      });
      
        await fetchAvailableItems();
        return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAvailableItem({
    required String id,
    double? quantity,
    double? soldPrice,
    String? salesmanId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.put('available-items/$id', {
        'quantity': quantity,
        'soldPrice': soldPrice,
        'salesmanId': salesmanId,
      });
      // await http.put(
      //   Uri.parse('$baseUrl/available-items/$id'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
        // body: json.encode({
        //   'quantity': quantity,
        //   'soldPrice': soldPrice,
        //   'salesmanId': salesmanId,
        // }),
      // );
      
        await fetchAvailableItems();
        return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAvailableItem(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.delete('available-items/$id');
      // await http.delete(
      //   Uri.parse('$baseUrl/available-items/$id'),
      // );
      
        _availableItems.removeWhere((item) => item.id == id);
        return true;

    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
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
      // await http.get(
      //   Uri.parse('$baseUrl/available-items/calculate'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
      // );
      
        final List<dynamic> data = json.decode(response);
        _availableItems = data.map((item) => AvailableItem.fromJson(item)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignToSalesman(
    String availableItemId,
    String salesmanId,
    double quantity,
    double soldPrice,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Api.post('available-items/$availableItemId/assign', {
        'salesmanId': salesmanId,
        'quantity': quantity,
        'soldPrice': soldPrice,
      });

        await fetchAvailableItems();
        return true;

    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 