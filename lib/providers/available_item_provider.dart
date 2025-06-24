import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'dart:convert';
import 'package:inventory_frontend/utils/api.dart';

class AvailableItemProvider with ChangeNotifier {
  List<AvailableItem> _availableItems = [];
  bool _isLoading = false;
  String? _error;
  
  List<AvailableItem> get availableItems => _availableItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAvailableItems({String? shopId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      String endpoint = 'available-items';
      if (shopId != null && shopId.isNotEmpty) {
        endpoint += '?shopId=$shopId';
      }
      print('Fetching available items for shopId: $shopId');
      final response = await Api.get(endpoint);
      final List<dynamic> data = response is List ? response : json.decode(response);
      _availableItems = data.map((item) => AvailableItem.fromJson(item)).toList();
      print('Fetched available items:');
      for (var item in _availableItems) {
        print('AvailableItem: itemId=${item.itemId}, shopId=${item.shopId}, quantity=${item.quantity}');
      }
    } catch (e) {
      _error = e.toString();
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
      final List<dynamic> data = json.decode(response);
      _availableItems = data.map((item) => AvailableItem.fromJson(item)).toList();
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
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.post('available-items', {
        'itemId': itemId,
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

  Future<bool> updateAvailableItem({
    required String id,
    double? quantity,
    double? soldPrice,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.put('available-items/$id', {
        'quantity': quantity,
        'soldPrice': soldPrice,
      });
      // await http.put(
      //   Uri.parse('$baseUrl/available-items/$id'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
        // body: json.encode({
        //   'quantity': quantity,
        //   'soldPrice': soldPrice,
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

  // Get available items for a specific shop
  List<AvailableItem> getAvailableItemsForShop(String shopId) {
    return _availableItems.where((item) => item.shopId == shopId).toList();
  }
} 