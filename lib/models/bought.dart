import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/fraction.dart';

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
  });
  
  factory Bought.fromJson(Map<String, dynamic> json) {
    return Bought(
      id: json['id'],
      fractionId: json['fractionId'],
      fractionPurchasePrice: json['fractionPurchasePrice'].toDouble(),
      fractionSoldPrice: json['fractionSoldPrice'].toDouble(),
      quantity: json['quantity'].toDouble(),
      location: json['location'],
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      createdTime: DateTime.parse(json['createdTime']),
      itemId: json['itemId'],
      item: json['Item'] != null ? Item.fromJson(json['Item']) : null,
      fraction: json['Item']?['Fractions'] != null && json['Item']?['Fractions'].isNotEmpty 
          ? Fraction.fromJson(json['Item']['Fractions'].firstWhere(
              (f) => f['id'] == json['fractionId'],
              orElse: () => null,
            ))
          : null,
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
    };
  }
} 