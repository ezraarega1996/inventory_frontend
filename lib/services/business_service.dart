import 'package:dio/dio.dart';
import '../models/business.dart';
import '../models/subscription_plan.dart';
import '../utils/api.dart';

class BusinessService {
  final Dio _dio;
  final String baseUrl;

  BusinessService({required this.baseUrl}) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  // Add token to requests
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Create a new business
  Future<Business> createBusiness(Map<String, dynamic> businessData) async {
    try {
      final response = await _dio.post('/api/businesses', data: businessData);
      return Business.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create business: $e');
    }
  }

  // Get all businesses (admin only)
  Future<List<Business>> getAllBusinesses() async {
    try {
      final response = await Api.get('businesses');
      return (response as List)
          .map((json) => Business.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get businesses: $e');
    }
  }

  // Get business by ID
  Future<Business> getBusinessById(String id) async {
    try {
      final response = await Api.get('businesses/$id');
      print("Business response: ${response}");
      return Business.fromJson(response);
    } catch (e) {
      print("Error getting business by ID: $e");
      throw Exception('Failed to get business: $e');
    }
  }

  // Update business
  Future<Business> updateBusiness(String id, Business business) async {
    try {
      final response = await _dio.put(
        '/api/businesses/$id',
        data: business.toJson(),
      );
      return Business.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update business: $e');
    }
  }

  // Update subscription
  Future<Business> updateSubscription(
    String id,
    String status,
    String plan,
    DateTime? endsAt,
  ) async {
    try {
      final response = await _dio.put(
        '/api/businesses/$id/subscription',
        data: {
          'subscriptionStatus': status,
          'subscriptionPlan': plan,
          'subscriptionEndsAt': endsAt?.toIso8601String(),
        },
      );
      return Business.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update subscription: $e');
    }
  }

  // Get business stats
  Future<Map<String, dynamic>> getBusinessStats(String id) async {
    try {
      final response = await Api.get('businesses/$id/stats');
      return response;
    } catch (e) {
      throw Exception('Failed to get business stats: $e');
    }
  }

  Future<Map<String, SubscriptionPlan>> getSubscriptionPlans() async {
    final response = await Api.get('subscription/plans');
    return Map<String, SubscriptionPlan>.fromEntries(
      (response as List).map((plan) => MapEntry(
        plan['name'],
        SubscriptionPlan.fromJson(plan),
      )),
    );
  }

  Future<String?> createCheckoutSession(String planName) async {
    final response = await Api.post('subscription/checkout', {
      'planName': planName,
    });
    return response['checkoutUrl'];
  }
} 