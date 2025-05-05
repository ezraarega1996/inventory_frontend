import 'package:inventory_frontend/models/business.dart';
class User {
  final String id;
  final String name;
  final String phone;
  final String location;
  final String username;
  final String email;
  final String role;
  final String? businessId;
  final Business? business;
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
    this.business,
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
      business: json['business'] != null ? Business.fromJson(json['business']) : null,
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
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, phone: $phone, location: $location, username: $username, email: $email, role: $role, businessId: $businessId, isActive: $isActive)';
  }
}
