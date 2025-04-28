import 'package:inventory_frontend/models/item.dart';

class AvailableItem {
  final String id;
  final String itemId;
  final double quantity;
  final double soldPrice;
  final Item? item;
  
  AvailableItem({
    required this.id,
    required this.itemId,
    required this.quantity,
    required this.soldPrice,
    this.item,
  });
  
  factory AvailableItem.fromJson(Map<String, dynamic> json) {
    return AvailableItem(
      id: json['id'],
      itemId: json['itemId'],
      quantity: json['quantity'].toDouble(),
      soldPrice: json['soldPrice'].toDouble(),
      item: json['Item'] != null ? Item.fromJson(json['Item']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'quantity': quantity,
      'soldPrice': soldPrice,
    };
  }
} 