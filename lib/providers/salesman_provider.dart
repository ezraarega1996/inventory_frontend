import 'package:flutter/foundation.dart';
import 'package:inventory_frontend/models/salesman.dart';
import 'package:inventory_frontend/services/api_service.dart';

class SalesmanProvider with ChangeNotifier {
  List<Salesman> _salesmen = [];
  bool _isLoading = false;
  String? _error;

  List<Salesman> get salesmen => _salesmen;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSalesmen() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/salesmen');
      _salesmen =
          (response.data as List)
              .map((json) => Salesman.fromJson(json))
              .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
