import 'package:flutter/foundation.dart';
import 'package:inventory_frontend/models/shop.dart';
import 'package:inventory_frontend/models/user.dart';
import 'package:inventory_frontend/utils/api.dart';
import 'package:inventory_frontend/utils/storage.dart';

class ShopProvider with ChangeNotifier {
  List<Shop> _shops = [];
  List<User> _availableSalespeople = [];
  bool _isLoading = false;
  String? _error;

  List<Shop> get shops => _shops;
  List<User> get availableSalespeople => _availableSalespeople;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all shops
  Future<void> getShops() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await Api.get('shops');
      
      if (response != null) {
        final List<dynamic> shopsData = response;
        _shops = shopsData.map((shop) => Shop.fromJson(shop)).toList();
        notifyListeners();
      } else {
        _setError('Failed to load shops');
      }
    } catch (e) {
      _setError('Error loading shops: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get shop by ID
  Future<Shop?> getShopById(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await Api.get('shops/$id');
      
      if (response != null) {
        final shop = Shop.fromJson(response);
        return shop;
      } else {
        _setError('Failed to load shop');
        return null;
      }
    } catch (e) {
      _setError('Error loading shop: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Create shop
  Future<bool> createShop(String name, String address) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await Api.post('shops', {
        'name': name,
        'address': address,
      });
      
      if (response != null) {
        final shop = Shop.fromJson(response['shop']);
        _shops.add(shop);
        notifyListeners();
        return true;
      } else {
        _setError('Failed to create shop');
        return false;
      }
    } catch (e) {
      _setError('Error creating shop: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update shop
  Future<bool> updateShop(String id, String name, String address) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await Api.put('shops/$id', {
        'name': name,
        'address': address,
      });
      
      if (response != null) {
        final updatedShop = Shop.fromJson(response['shop']);
        final index = _shops.indexWhere((shop) => shop.id == id);
        if (index != -1) {
          _shops[index] = updatedShop;
          notifyListeners();
        }
        return true;
      } else {
        _setError('Failed to update shop');
        return false;
      }
    } catch (e) {
      _setError('Error updating shop: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete shop
  Future<bool> deleteShop(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await Api.delete('shops/$id');
      
      if (response != null) {
        _shops.removeWhere((shop) => shop.id == id);
        notifyListeners();
        return true;
      } else {
        _setError('Failed to delete shop');
        return false;
      }
    } catch (e) {
      _setError('Error deleting shop: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get available salespeople
  Future<void> getAvailableSalespeople() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await Api.get('shops/available-salespeople');
      
      if (response != null) {
        final List<dynamic> salespeopleData = response;
        _availableSalespeople = salespeopleData.map((user) => User.fromJson(user)).toList();
        notifyListeners();
      } else {
        _setError('Failed to load available salespeople');
      }
    } catch (e) {
      _setError('Error loading available salespeople: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Assign salesperson to shop
  Future<bool> assignSalespersonToShop(String shopId, String salespersonId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await Api.post('shops/$shopId/assign-salesperson', {
        'salespersonId': salespersonId,
      });
      
      if (response != null) {
        // Refresh shops to get updated data
        await getShops();
        await getAvailableSalespeople();
        return true;
      } else {
        _setError('Failed to assign salesperson');
        return false;
      }
    } catch (e) {
      _setError('Error assigning salesperson: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove salesperson from shop
  Future<bool> removeSalespersonFromShop(String shopId, String salespersonId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await Api.post('shops/$shopId/remove-salesperson', {
        'salespersonId': salespersonId,
      });
      
      if (response != null) {
        // Refresh shops to get updated data
        await getShops();
        await getAvailableSalespeople();
        return true;
      } else {
        _setError('Failed to remove salesperson');
        return false;
      }
    } catch (e) {
      _setError('Error removing salesperson: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearShops() {
    _shops = [];
    notifyListeners();
  }
} 