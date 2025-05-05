import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/user.dart';
import 'package:inventory_frontend/models/fraction.dart';

class SoldItem {
  final String id;
  final String itemId;
  final String fractionId;
  final double quantity;
  final double soldPrice;
  final String businessId;
  final String? salesmanId;
  final DateTime createdAt;
  final Fraction? fraction;
  final Item? item;

  SoldItem({
    required this.id,
    required this.itemId,
    required this.fractionId,
    required this.quantity,
    required this.soldPrice,
    required this.businessId,
    this.salesmanId,
    required this.createdAt,
    this.fraction,
    this.item,
  });

  factory SoldItem.fromJson(Map<String, dynamic> json) {
    return SoldItem(
      id: json['id'],
      itemId: json['itemId'],
      fractionId: json['fractionId'],

      quantity: (json['quantity'] is int) ? (json['quantity'] as int).toDouble() : json['quantity'],
      soldPrice: (json['soldPrice'] is int) ? (json['soldPrice'] as int).toDouble() : json['soldPrice'],
      businessId: json['businessId'],
      salesmanId: json['salesmanId'],
      createdAt: DateTime.parse(json['createdAt']),
      fraction: json['fraction'] != null ? Fraction.fromJson(json['fraction']) : null,
      item: json['item'] != null ? Item.fromJson(json['item']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'fractionId': fractionId,
      'quantity': quantity,
      'soldPrice': soldPrice,
      'businessId': businessId,
      'salesmanId': salesmanId,
      'createdAt': createdAt.toIso8601String(),
      'fraction': fraction?.toJson(),
      'item': item?.toJson(),
    };
  }

  @override
  String toString() {
    return 'SoldItem(id: $id, itemId: $itemId, fractionId: $fractionId, quantity: $quantity, soldPrice: $soldPrice, businessId: $businessId, salesmanId: $salesmanId, createdAt: $createdAt, fraction: $fraction, item: $item)';
  }
}
