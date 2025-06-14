import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:inventory_frontend/models/sold_item.dart';
import 'package:inventory_frontend/utils/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_frontend/config.dart';
import 'package:inventory_frontend/models/user.dart';
import 'package:inventory_frontend/models/sales_data.dart';

class SalesProvider with ChangeNotifier {
  List<SoldItem> _sales = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dashboardStats;
  double? _totalSales;
  int? _totalItemsSold;
  double? _todaySales;
  List<SalesData> _todaySalesData = [];

  List<SoldItem> get sales => [..._sales];
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  double? get totalSales => _totalSales;
  int? get totalItemsSold => _totalItemsSold;
  double? get todaySales => _todaySales;
  List<SalesData> get todaySalesData => _todaySalesData;

  Future<void> fetchSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Api.get("sales");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _sales = data.map((json) => SoldItem.fromJson(json)).toList();
        _totalItemsSold = _sales.length;
        _todaySales = _sales.fold<double>(0.0, (sum, item) => sum + item.soldPrice);
      } else {
        _error = 'Failed to fetch sales';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodaySales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Api.get('available-items/today-sales');
      print('Today sales response: $response'); // Debug print
      
      if (response != null && response is Map<String, dynamic>) {
        _todaySales = (response['totalSales'] ?? 0).toDouble();
        print('Total sales: $_todaySales'); // Debug print
        
        if (response['salesBySalesman'] != null) {
          _todaySalesData = (response['salesBySalesman'] as List)
              .map((json) => SalesData.fromJson(json))
              .toList();
          print('Sales by salesman: $_todaySalesData'); // Debug print
        } else {
          _todaySalesData = [];
        }
      } else {
        _error = 'Invalid response format';
        _todaySalesData = [];
      }
    } catch (e) {
      print('Error in fetchTodaySales: $e'); // Debug print
      _error = e.toString();
      _todaySalesData = [];
    } finally {
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

      _sales = List<SoldItem>.from(response.map((x) => SoldItem.fromJson(x)));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardStats() async {
    print('Fetching dashboard stats...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {

      final response = await Api.get('sales/dashboard');
      if (response != null) {
        _totalSales = response['totalSales']?.toDouble();
        _totalItemsSold = response['salesCount'];

        _dashboardStats = response;
        if (response['sales'] is List) {
          _sales = List<SoldItem>.from(
            (response['sales'] as List).map((x) => SoldItem.fromJson(x)),
          );
        } else {
          _sales = [];
        }
        _sales.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Calculate today's sales
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        _todaySales = response['todaySales'];
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
      final response = await Api.get(
        'sales/available-quantity?itemId=$itemId&fractionId=$fractionId',
      );

      print('Available quantity response: $response'); // Debug log

      if (response == null) {
        throw Exception('No response from server');
      }

      if (response is Map<String, dynamic> && response.containsKey('availableQuantity')) {
        final quantity = response['availableQuantity'];
        if (quantity is num) {
          _isLoading = false;
          notifyListeners();
          return quantity.toDouble();
        }
      }

      throw Exception('Invalid response format');
    } catch (e) {
      print('Error in getAvailableQuantity: $e'); // Debug log
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
