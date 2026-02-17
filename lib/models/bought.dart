import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/shop.dart';

class Bought {
  final String id;
  final String fractionId;
  final double fractionPurchasePrice;
  final double fractionSoldPrice;
  final double quantity;
  final DateTime? expiryDate;
  final DateTime createdTime;
  final String itemId;
  final Item? item;
  final Fraction? fraction;
  final String? shopId;
  final Shop? shop;
  final double? available_items_count;
  
  
  Bought({
    required this.id,
    required this.fractionId,
    required this.fractionPurchasePrice,
    required this.fractionSoldPrice,
    required this.quantity,
    this.expiryDate,
    required this.createdTime,
    required this.itemId,
    this.item,
    this.fraction,
    this.shopId,
    this.shop,
    this.available_items_count,
  });
  
  factory Bought.fromJson(Map<String, dynamic> json) {
    return Bought(
      id: json['id'] ?? '',
      fractionId: json['fractionId'] ?? '',
      fractionPurchasePrice: (json['fractionPurchasePrice'] is num)
          ? (json['fractionPurchasePrice'] as num).toDouble()
          : double.tryParse(json['fractionPurchasePrice']?.toString() ?? '') ?? 0.0,
      fractionSoldPrice: (json['fractionSoldPrice'] is num)
          ? (json['fractionSoldPrice'] as num).toDouble()
          : double.tryParse(json['fractionSoldPrice']?.toString() ?? '') ?? 0.0,
      quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
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
      shopId: json['shopId'],
      shop: json['Shop'] != null ? Shop.fromJson(json['Shop']) : null,
      available_items_count: json['available_items_count'] != null ? double.tryParse(json['available_items_count'].toString()) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fractionId': fractionId,
      'fractionPurchasePrice': fractionPurchasePrice,
      'fractionSoldPrice': fractionSoldPrice,
      'quantity': quantity,
      'expiryDate': expiryDate?.toIso8601String(),
      'itemId': itemId,
      'shopId': shopId,
    };
  }

  @override
  String toString() {
    return 'Bought(id: $id, fractionId: $fractionId, fractionPurchasePrice: $fractionPurchasePrice, fractionSoldPrice: $fractionSoldPrice, quantity: $quantity, expiryDate: $expiryDate, createdTime: $createdTime, itemId: $itemId, item: $item, fraction: $fraction, shopId: $shopId, shop: $shop)';
  }
} 