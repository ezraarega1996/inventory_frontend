import 'package:inventory_frontend/models/fraction.dart';

class ItemBought {
  final String id;
  final String itemId;
  final String fractionId;
  final double quantity;
  final double fractionPurchasePrice;
  final double fractionSoldPrice;
  final DateTime? expiryDate;
  final String businessId;
  final String? salesmanId;
  final DateTime createdAt;
  final Fraction? fraction;
  final String? availableItemId;
  final double? available_items_count;

  ItemBought({
    required this.id,
    required this.itemId,
    required this.fractionId,
    required this.quantity,
    required this.fractionPurchasePrice,
    required this.fractionSoldPrice,
    this.expiryDate,
    required this.businessId,
    this.salesmanId,
    required this.createdAt,
    this.fraction,
    this.availableItemId,
    this.available_items_count,
  });

  factory ItemBought.fromJson(Map<String, dynamic> json) {
    print('Parsing ItemBought: $json'); // Debug log
    return ItemBought(
      id: json['id'],
      itemId: json['itemId'],
      fractionId: json['fractionId'],
      quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
      fractionPurchasePrice: double.tryParse(json['fractionPurchasePrice'].toString()) ?? 0.0,
      fractionSoldPrice: double.tryParse(json['fractionSoldPrice'].toString()) ?? 0.0,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      businessId: json['businessId'],
      salesmanId: json['salesmanId'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['createdTime'] ?? DateTime.now().toIso8601String()),
      fraction: json['fraction'] != null ? Fraction.fromJson(json['fraction']) : null,
      availableItemId: json['availableItemId'],
      available_items_count: json['available_items_count'] != null ? double.tryParse(json['available_items_count'].toString()) : null,
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
      'expiryDate': expiryDate?.toIso8601String(),
      'businessId': businessId,
      'salesmanId': salesmanId,
      'createdAt': createdAt.toIso8601String(),
      'fraction': fraction?.toJson(),
      'availableItemId': availableItemId,
      'available_items_count': available_items_count,
    };
  }

  @override
  String toString() {
    return 'ItemBought(id: $id, itemId: $itemId, fractionId: $fractionId, quantity: $quantity, fractionPurchasePrice: $fractionPurchasePrice, fractionSoldPrice: $fractionSoldPrice, expiryDate: $expiryDate, businessId: $businessId, salesmanId: $salesmanId, createdAt: $createdAt, fraction: $fraction, availableItemId: $availableItemId, available_items_count: $available_items_count)';
  }
} 