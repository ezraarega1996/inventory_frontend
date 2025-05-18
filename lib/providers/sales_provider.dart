import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:inventory_frontend/models/sold_item.dart';
import 'package:inventory_frontend/utils/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SalesProvider with ChangeNotifier {
  List<SoldItem> _sales = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dashboardStats;
  double? _totalSales;
  int? _totalItemsSold;
  double? _todaySales;
  
  List<SoldItem> get sales => [..._sales];
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  double? get totalSales => _totalSales;
  int? get totalItemsSold => _totalItemsSold;
  double? get todaySales => _todaySales;
  
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
      final response = await Api.get('sales/dashboard-stats');

      if (response != null) {
        _totalSales = response['totalSales']?.toDouble();
        _totalItemsSold = response['salesCount'];
        
        // Calculate today's sales
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        _todaySales = _sales
          .where((sale) => sale.createdAt.isAfter(todayStart))
          .fold(0.0, (double? sum, sale) => (sum ?? 0.0) + (sale.soldPrice ?? 0.0));
      } else {
        _error = 'Failed to fetch dashboard stats';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
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
      
      if (response == null) {
        _error = 'No response received from server';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
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
  
  Future<double> getAvailableQuantity(String itemId, String fractionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await Api.get('sales/available-quantity?itemId=$itemId&fractionId=$fractionId');
      
      _isLoading = false;
      notifyListeners();
      
      return response['availableQuantity'] ?? 0.0;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return 0.0;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
