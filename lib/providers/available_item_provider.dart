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
      // First, get the available items
      final response = await Api.get('available-items');
      print('API Response: $response'); // Debug log
      
      if (response == null) {
        throw Exception('No response from server');
      }
      
      _availableItems = List<AvailableItem>.from(
        response.map((x) {
          print('Parsing available item: $x'); // Debug log
          return AvailableItem.fromJson(x);
        })
      );
      
      // Then, fetch transactions for each item
      for (var item in _availableItems) {
        try {
          final transactionsResponse = await Api.get('available-items/${item.id}/transactions');
          print('Transactions for item ${item.id}: $transactionsResponse'); // Debug log
          
          if (transactionsResponse != null) {
            final updatedItem = AvailableItem.fromJson({
              ...item.toJson(),
              'boughtTransactions': transactionsResponse['boughtTransactions'],
              'soldTransactions': transactionsResponse['soldTransactions'],
            });
            
            final index = _availableItems.indexWhere((i) => i.id == item.id);
            if (index != -1) {
              _availableItems[index] = updatedItem;
            }
          }
        } catch (e) {
          print('Error fetching transactions for item ${item.id}: $e'); // Debug log
        }
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error fetching available items: $e'); // Debug log
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

  Future<void> fetchAvailableItemTransactions(String availableItemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final transactionsResponse = await Api.get('available-items/$availableItemId/transactions');
      
      if (transactionsResponse != null) {
        final index = _availableItems.indexWhere((i) => i.id == availableItemId);
        if (index != -1) {
          final updatedItem = AvailableItem.fromJson({
            ..._availableItems[index].toJson(),
            'boughtTransactions': transactionsResponse['boughtTransactions'],
            'soldTransactions': transactionsResponse['soldTransactions'],
          });
          _availableItems[index] = updatedItem;
        }
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error fetching transactions for item $availableItemId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  AvailableItem? getAvailableItem(String availableItemId) {
    try {
      return _availableItems.firstWhere((item) => item.id == availableItemId);
    } catch (e) {
      return null;
    }
  }
} 