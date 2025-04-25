import 'package:flutter/foundation.dart';
import '../models/business.dart';
import '../models/subscription_plan.dart';
import '../services/business_service.dart';

class BusinessProvider with ChangeNotifier {
  final BusinessService _businessService;
  Business? _currentBusiness;
  List<Business> _businesses = [];
  Map<String, SubscriptionPlan> _subscriptionPlans = {};
  bool _isLoading = false;
  String? _error;

  BusinessProvider(this._businessService);

  Business? get currentBusiness => _currentBusiness;
  List<Business> get businesses => _businesses;
  Map<String, SubscriptionPlan> get subscriptionPlans => _subscriptionPlans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCurrentBusiness(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBusiness = await _businessService.getBusinessById(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBusinesses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _businesses = await _businessService.getAllBusinesses();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createBusiness(Business business) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newBusiness = await _businessService.createBusiness(business);
      _businesses.add(newBusiness);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateBusiness(Business business) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedBusiness = await _businessService.updateBusiness(
        business.id,
        business,
      );
      final index = _businesses.indexWhere((b) => b.id == business.id);
      if (index != -1) {
        _businesses[index] = updatedBusiness;
      }
      if (_currentBusiness?.id == business.id) {
        _currentBusiness = updatedBusiness;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSubscription(
    String id,
    String status,
    String plan,
    DateTime? endsAt,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedBusiness = await _businessService.updateSubscription(
        id,
        status,
        plan,
        endsAt,
      );
      final index = _businesses.indexWhere((b) => b.id == id);
      if (index != -1) {
        _businesses[index] = updatedBusiness;
      }
      if (_currentBusiness?.id == id) {
        _currentBusiness = updatedBusiness;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getBusinessStats(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stats = await _businessService.getBusinessStats(id);
      _error = null;
      return stats;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubscriptionPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _subscriptionPlans = await _businessService.getSubscriptionPlans();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> createCheckoutSession(String planName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final checkoutUrl = await _businessService.createCheckoutSession(planName);
      _error = null;
      return checkoutUrl;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
