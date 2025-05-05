import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/user.dart';

class Bought {
  final String id;
  final String fractionId;
  final double fractionPurchasePrice;
  final double fractionSoldPrice;
  final double quantity;
  final String location;
  final DateTime? expiryDate;
  final DateTime createdTime;
  final String itemId;
  final Item? item;
  final Fraction? fraction;
  final String? salesmanId;
  final User? salesman;
  
  Bought({
    required this.id,
    required this.fractionId,
    required this.fractionPurchasePrice,
    required this.fractionSoldPrice,
    required this.quantity,
    required this.location,
    this.expiryDate,
    required this.createdTime,
    required this.itemId,
    this.item,
    this.fraction,
    this.salesmanId,
    this.salesman,
  });
  
  factory Bought.fromJson(Map<String, dynamic> json) {
    return Bought(
      id: json['id'] ?? '',
      fractionId: json['fractionId'] ?? '',
      fractionPurchasePrice: (json['fractionPurchasePrice'] is num) ? (json['fractionPurchasePrice'] as num).toDouble() : 0.0,
      fractionSoldPrice: (json['fractionSoldPrice'] is num) ? (json['fractionSoldPrice'] as num).toDouble() : 0.0,
      quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
      location: json['location'] ?? '',
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      createdTime: DateTime.parse(json['createdTime'] ?? DateTime.now().toIso8601String()),
      itemId: json['itemId'] ?? '',
      item: json['Item'] != null ? Item.fromJson(json['Item']) : null,
      fraction: json['Item']?['fractions'] != null && json['Item']?['fractions'].isNotEmpty 
          ? Fraction.fromJson(json['Item']['fractions'].firstWhere(
              (f) => f['id'] == json['fractionId'],
              orElse: () => null,
            ))
          : null,
      salesmanId: json['salesmanId'],
      salesman: json['salesman'] != null ? User.fromJson(json['salesman']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fractionId': fractionId,
      'fractionPurchasePrice': fractionPurchasePrice,
      'fractionSoldPrice': fractionSoldPrice,
      'quantity': quantity,
      'location': location,
      'expiryDate': expiryDate?.toIso8601String(),
      'itemId': itemId,
      'salesmanId': salesmanId,
    };
  }

  @override
  String toString() {
    return 'Bought(id: $id, fractionId: $fractionId, fractionPurchasePrice: $fractionPurchasePrice, fractionSoldPrice: $fractionSoldPrice, quantity: $quantity, location: $location, expiryDate: $expiryDate, createdTime: $createdTime, itemId: $itemId, item: $item, fraction: $fraction, salesmanId: $salesmanId, salesman: $salesman)';
  }
} 