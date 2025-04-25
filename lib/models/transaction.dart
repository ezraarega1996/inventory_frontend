import 'package:inventory_frontend/models/item.dart';

class ItemTransaction {
  final String id;
  final String fractionName;
  final double fractionPurchasePrice;
  final double fractionSoldPrice;
  final double quantity;
  final String location;
  final DateTime? expiryDate;
  final DateTime createdTime;
  final String itemId;
  final Item? item;
  
  ItemTransaction({
    required this.id,
    required this.fractionName,
    required this.fractionPurchasePrice,
    required this.fractionSoldPrice,
    required this.quantity,
    required this.location,
    this.expiryDate,
    required this.createdTime,
    required this.itemId,
    this.item,
  });
  
  factory ItemTransaction.fromJson(Map<String, dynamic> json) {
    return ItemTransaction(
      id: json['id'],
      fractionName: json['fractionName'],
      fractionPurchasePrice: json['fractionPurchasePrice'].toDouble(),
      fractionSoldPrice: json['fractionSoldPrice'].toDouble(),
      quantity: json['quantity'].toDouble(),
      location: json['location'],
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      createdTime: DateTime.parse(json['createdTime']),
      itemId: json['itemId'],
      item: json['Item'] != null ? Item.fromJson(json['Item']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fractionName': fractionName,
      'fractionPurchasePrice': fractionPurchasePrice,
      'fractionSoldPrice': fractionSoldPrice,
      'quantity': quantity,
      'location': location,
      'expiryDate': expiryDate?.toIso8601String(),
      'itemId': itemId,
    };
  }
}
