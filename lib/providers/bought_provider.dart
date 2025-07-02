import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/bought.dart';
import 'package:inventory_frontend/utils/api.dart';

class BoughtProvider with ChangeNotifier {
  List<Bought> _boughts = [];
  bool _isLoading = false;
  String? _error;
  
  List<Bought> get boughts => _boughts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchBoughts() async { 
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('boughts');
      print("boughts response: $response");
      _boughts = List<Bought>.from(
        response.map((x) => Bought.fromJson(x))
      );
      print("Fetched boughts: $_boughts.shop");
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> createBought({
    required String itemId,
    required String fractionId,
    required double fractionPurchasePrice,
    required double fractionSoldPrice,
    required double quantity,
    DateTime? expiryDate,
    String? shopId,
  }) async {
    print('BoughtProvider: createBought called with:');
    print('itemId: $itemId');
    print('fractionId: $fractionId');
    print('fractionPurchasePrice: $fractionPurchasePrice');
    print('fractionSoldPrice: $fractionSoldPrice');
    print('quantity: $quantity');
    print('expiryDate: $expiryDate');
    print('shopId: $shopId');
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final requestData = {
        'itemId': itemId,
        'fractionId': fractionId,
        'fractionPurchasePrice': fractionPurchasePrice,
        'fractionSoldPrice': fractionSoldPrice,
        'quantity': quantity,
        'expiryDate': expiryDate?.toIso8601String(),
        'shopId': shopId,
      };
      
      print('BoughtProvider: Sending request data: $requestData');
      
      final response = await Api.post('boughts', requestData);
      
      print('BoughtProvider: Received response: $response');
      
      final newBought = Bought.fromJson(response);
      _boughts.insert(0, newBought);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      print('BoughtProvider: Error occurred: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> updateBought({
    required String id,
    String? fractionId,
    double? fractionPurchasePrice,
    double? fractionSoldPrice,
    double? quantity,
    DateTime? expiryDate,
    String? shopId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.put('boughts/$id', {
        'fractionId': fractionId,
        'fractionPurchasePrice': fractionPurchasePrice,
        'fractionSoldPrice': fractionSoldPrice,
        'quantity': quantity,
        'expiryDate': expiryDate?.toIso8601String(),
        'shopId': shopId,
      });
      
      final updatedBought = Bought.fromJson(response);
      final index = _boughts.indexWhere((t) => t.id == id);
      if (index != -1) {
        _boughts[index] = updatedBought;
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
  
  Future<bool> deleteBought(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await Api.delete('boughts/$id');
      
      _boughts.removeWhere((t) => t.id == id);
      
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