import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/user.dart';
import 'package:inventory_frontend/models/item_bought.dart';
import 'package:inventory_frontend/models/sold_item.dart';

class AvailableItem {
  final String id;
  final String itemId;
  final String businessId;
  final double quantity;
  final double soldPrice;
  final String? salesmanId;
  final Item? item;
  final User? salesman;
  final List<ItemBought>? boughtTransactions;
  final List<SoldItem>? soldTransactions;

  AvailableItem({
    required this.id,
    required this.itemId,
    required this.businessId,
    required this.quantity,
    required this.soldPrice,
    this.salesmanId,
    this.item,
    this.salesman,
    this.boughtTransactions,
    this.soldTransactions,
  });

  factory AvailableItem.fromJson(Map<String, dynamic> json) {
    return AvailableItem(
      id: json['id'],
      itemId: json['itemId'],
      businessId: json['businessId'],

      quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
      soldPrice: double.tryParse(json['soldPrice'].toString()) ?? 0.0,
      salesmanId: json['salesmanId'],
      item: json['item'] != null ? Item.fromJson(json['item']) : null,
      salesman: json['salesman'] != null ? User.fromJson(json['salesman']) : null,
      boughtTransactions: json['boughtTransactions'] != null
          ? (json['boughtTransactions'] as List)
              .map((transaction) => ItemBought.fromJson(transaction))
              .toList()
          : null,
      soldTransactions: json['soldTransactions'] != null
          ? (json['soldTransactions'] as List)
              .map((transaction) => SoldItem.fromJson(transaction))
              .toList()
          : null,
      
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'businessId': businessId,
      'quantity': quantity,
      'soldPrice': soldPrice,
      'salesmanId': salesmanId,
      'item': item?.toJson(),
      'salesman': salesman?.toJson(),
      'boughtTransactions': boughtTransactions?.map((transaction) => transaction.toJson()).toList(),
      'soldTransactions': soldTransactions?.map((transaction) => transaction.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'AvailableItem(id: $id, itemId: $itemId, businessId: $businessId, quantity: $quantity, soldPrice: $soldPrice, salesmanId: $salesmanId, item: $item, salesman: $salesman, boughtTransactions: $boughtTransactions, soldTransactions: $soldTransactions)';
  }
} 