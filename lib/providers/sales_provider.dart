import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/sold_item.dart';
import 'package:inventory_frontend/utils/api.dart';

class SalesProvider with ChangeNotifier {
  List<SoldItem> _sales = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dashboardStats;
  
  List<SoldItem> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  
  Future<void> fetchSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('sales');
      
      _sales = List<SoldItem>.from(
        response.map((x) => SoldItem.fromJson(x))
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchUserSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('sales/user');
      
      _sales = List<SoldItem>.from(
        response.map((x) => SoldItem.fromJson(x))
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('sales/dashboard');
      
      _dashboardStats = response;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> createSale(Map<String, dynamic> saleData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.post('sales', saleData);
      
      final newSale = SoldItem.fromJson(response);
      _sales.insert(0, newSale);
      
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
  
  Future<bool> updateSale(String id, Map<String, dynamic> saleData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.put('sales/$id', saleData);
      
      final updatedSale = SoldItem.fromJson(response);
      final index = _sales.indexWhere((sale) => sale.id == id);
      
      if (index != -1) {
        _sales[index] = updatedSale;
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
  
  Future<bool> deleteSale(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await Api.delete('sales/$id');
      
      _sales.removeWhere((sale) => sale.id == id);
      
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
