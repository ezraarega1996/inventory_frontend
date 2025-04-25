import 'package:inventory_frontend/models/category.dart';
import 'package:inventory_frontend/models/fraction.dart';

class Item {
  final String id;
  final String name;
  final String categoryId;
  final Category? category;
  final List<Fraction>? fractions;
  
  Item({
    required this.id,
    required this.name,
    required this.categoryId,
    this.category,
    this.fractions,
  });
  
  factory Item.fromJson(Map<String, dynamic> json) {
    List<Fraction>? fractionsList;
    
    if (json['Fractions'] != null) {
      fractionsList = List<Fraction>.from(
        json['Fractions'].map((x) => Fraction.fromJson(x))
      );
    }
    
    return Item(
      id: json['id'],
      name: json['name'],
      categoryId: json['categoryId'],
      category: json['Category'] != null ? Category.fromJson(json['Category']) : null,
      fractions: fractionsList,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
    };
  }
}
