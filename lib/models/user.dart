import 'package:inventory_frontend/models/business.dart';
import 'package:inventory_frontend/models/shop.dart';

class User {
  final String id;
  final String name;
  final String phone;
  final String location;
  final String username;
  final String email;
  final String role;
  final String? businessId;
  final String? shopId;
  final Business? business;
  final Shop? shop;
  final bool isActive;
  
  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.username,
    required this.email,
    required this.role,
    this.businessId,
    this.shopId,
    this.business,
    this.shop,
    this.isActive = true,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      businessId: json['businessId'] ?? '',
      shopId: json['shopId'],
      business: json['business'] != null ? Business.fromJson(json['business']) : null,
      shop: json['shop'] != null ? Shop.fromJson(json['shop']) : null,
      isActive: json['isActive'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'location': location,
      'username': username,
      'email': email,
      'role': role,
      'businessId': businessId,
      'shopId': shopId,
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, phone: $phone, location: $location, username: $username, email: $email, role: $role, businessId: $businessId, shopId: $shopId, isActive: $isActive)';
  }
}
