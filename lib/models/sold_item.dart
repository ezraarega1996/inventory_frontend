import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/user.dart';

class SoldItem {
  final String id;
  final DateTime soldTime;
  final double quantity;
  final String fractionName;
  final double amount;
  final double expectedAmount;
  final bool existing;
  final String status;
  final DateTime createdTime;
  final String itemId;
  final String salesmanId;
  final Item? item;
  final User? salesman;
  
  SoldItem({
    required this.id,
    required this.soldTime,
    required this.quantity,
    required this.fractionName,
    required this.amount,
    required this.expectedAmount,
    required this.existing,
    required this.status,
    required this.createdTime,
    required this.itemId,
    required this.salesmanId,
    this.item,
    this.salesman,
  });
  
  factory SoldItem.fromJson(Map<String, dynamic> json) {
    return SoldItem(
      id: json['id'],
      soldTime: DateTime.parse(json['soldTime']),
      quantity: json['quantity'].toDouble(),
      fractionName: json['fractionName'],
      amount: json['amount'].toDouble(),
      expectedAmount: json['expectedAmount'].toDouble(),
      existing: json['existing'],
      status: json['status'],
      createdTime: DateTime.parse(json['createdTime']),
      itemId: json['itemId'],
      salesmanId: json['salesmanId'],
      item: json['Item'] != null ? Item.fromJson(json['Item']) : null,
      salesman: json['salesman'] != null ? User.fromJson(json['salesman']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'fractionName': fractionName,
      'amount': amount,
      'expectedAmount': expectedAmount,
      'status': status,
      'itemId': itemId,
    };
  }
}
