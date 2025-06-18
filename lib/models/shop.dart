import 'package:inventory_frontend/models/user.dart';

class Shop {
  final String id;
  final String name;
  final String address;
  final String businessId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<User>? salespeople;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.businessId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.salespeople,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      businessId: json['businessId'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      salespeople: json['salespeople'] != null
          ? (json['salespeople'] as List)
              .map((user) => User.fromJson(user))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'businessId': businessId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'salespeople': salespeople?.map((user) => user.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Shop(id: $id, name: $name, address: $address, businessId: $businessId, isActive: $isActive)';
  }
} 