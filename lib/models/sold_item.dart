import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/user.dart';
import 'package:inventory_frontend/models/fraction.dart';

class SoldItem {
  final String id;
  final DateTime soldTime;
  final double quantity;
  final String fractionId;
  final double amount;
  final double expectedAmount;
  final bool existing;
  final String status;
  final DateTime createdTime;
  final String itemId;
  final String salesmanId;
  final Item? item;
  final User? salesman;
  final Fraction? fraction;
  
  SoldItem({
    required this.id,
    required this.soldTime,
    required this.quantity,
    required this.fractionId,
    required this.amount,
    required this.expectedAmount,
    required this.existing,
    required this.status,
    required this.createdTime,
    required this.itemId,
    required this.salesmanId,
    this.item,
    this.salesman,
    this.fraction,
  });
  
  factory SoldItem.fromJson(Map<String, dynamic> json) {
    Fraction? fraction;
    if (json['Item']?['Fractions'] != null) {
      final fractions = List<Fraction>.from(
        json['Item']['Fractions'].map((x) => Fraction.fromJson(x))
      );
      fraction = fractions.firstWhere(
        (f) => f.id == json['fractionId'],
        orElse: () => fractions.first,
      );
    } else if (json['fraction'] != null) {
      fraction = Fraction.fromJson(json['fraction']);
    }
    
    return SoldItem(
      id: json['id'],
      soldTime: DateTime.parse(json['soldTime']),
      quantity: json['quantity'].toDouble(),
      fractionId: json['fractionId'],
      amount: json['amount'].toDouble(),
      expectedAmount: json['expectedAmount'].toDouble(),
      existing: json['existing'],
      status: json['status'],
      createdTime: DateTime.parse(json['createdTime']),
      itemId: json['itemId'],
      salesmanId: json['salesmanId'],
      item: json['Item'] != null ? Item.fromJson(json['Item']) : null,
      salesman: json['salesman'] != null ? User.fromJson(json['salesman']) : null,
      fraction: fraction,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'fractionId': fractionId,
      'amount': amount,
      'expectedAmount': expectedAmount,
      'status': status,
      'itemId': itemId,
    };
  }
}
