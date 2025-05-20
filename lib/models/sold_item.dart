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
  final User? salesman;
  final double? available_items_count;


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
    this.salesman,
    this.available_items_count,
  });

  factory SoldItem.fromJson(Map<String, dynamic> json) {
    print("SoldItem.fromJson: $json");
    return SoldItem(
      id: json['id'],
      itemId: json['itemId'],
      fractionId: json['fractionId'],

      quantity: (json['quantity'] == null)
          ? 0.0
          : (json['quantity'] is int)
              ? (json['quantity'] as int).toDouble()
              : json['quantity'],
      soldPrice: (json['amount'] == null)
          ? 0.0
          : (json['amount'] is int)
              ? (json['amount'] as int).toDouble()
              : json['amount'],
      businessId: json['businessId'],
      salesmanId: json['salesmanId'],
      createdAt: DateTime.parse(json['createdAt']),
      item: json['Item'] != null ? Item.fromJson(json['Item']) : null,
      fraction: json['Item']?['fractions'] != null && json['Item']?['fractions'].isNotEmpty 
          ? Fraction.fromJson(json['Item']['fractions'].firstWhere(
              (f) => f['id'] == json['fractionId'],
              orElse: () => null,
            ))
          : null,
      salesman: json['salesman'] != null ? User.fromJson(json['salesman']) : null,
      available_items_count: json['available_items_count'] != null ? double.tryParse(json['available_items_count'].toString()) : null,
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
      'salesman': salesman?.toJson(),
    };
  }

  @override
  String toString() {
    return 'SoldItem(id: $id, itemId: $itemId, fractionId: $fractionId, quantity: $quantity, soldPrice: $soldPrice, businessId: $businessId, salesmanId: $salesmanId, createdAt: $createdAt, fraction: $fraction, item: $item)';
  }
}
