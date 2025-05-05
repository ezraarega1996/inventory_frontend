import 'package:inventory_frontend/models/fraction.dart';

class ItemBought {
  final String id;
  final String itemId;
  final String fractionId;
  final double quantity;
  final double fractionPurchasePrice;
  final double fractionSoldPrice;
  final String? location;
  final DateTime? expiryDate;
  final String businessId;
  final String? salesmanId;
  final DateTime createdAt;
  final Fraction? fraction;

  ItemBought({
    required this.id,
    required this.itemId,
    required this.fractionId,
    required this.quantity,
    required this.fractionPurchasePrice,
    required this.fractionSoldPrice,
    this.location,
    this.expiryDate,
    required this.businessId,
    this.salesmanId,
    required this.createdAt,
    this.fraction,
  });

  factory ItemBought.fromJson(Map<String, dynamic> json) {
    return ItemBought(
      id: json['id'],
      itemId: json['itemId'],
      fractionId: json['fractionId'],
      quantity: json['quantity'].toDouble(),
      fractionPurchasePrice: json['fractionPurchasePrice'].toDouble(),
      fractionSoldPrice: json['fractionSoldPrice'].toDouble(),
      location: json['location'],
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      businessId: json['businessId'],
      salesmanId: json['salesmanId'],
      createdAt: DateTime.parse(json['createdAt']),
      fraction: json['fraction'] != null ? Fraction.fromJson(json['fraction']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'fractionId': fractionId,
      'quantity': quantity,
      'fractionPurchasePrice': fractionPurchasePrice,
      'fractionSoldPrice': fractionSoldPrice,
      'location': location,
      'expiryDate': expiryDate?.toIso8601String(),
      'businessId': businessId,
      'salesmanId': salesmanId,
      'createdAt': createdAt.toIso8601String(),
      'fraction': fraction?.toJson(),
    };
  }

  @override
  String toString() {
    return 'ItemBought(id: $id, itemId: $itemId, fractionId: $fractionId, quantity: $quantity, fractionPurchasePrice: $fractionPurchasePrice, fractionSoldPrice: $fractionSoldPrice, location: $location, expiryDate: $expiryDate, businessId: $businessId, salesmanId: $salesmanId, createdAt: $createdAt, fraction: $fraction)';
  }
} 