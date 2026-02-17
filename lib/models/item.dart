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
  print('Item.fromJson: $json');
  try {
    List<Fraction>? fractionsList;

    if (json['fractions'] != null) {
      fractionsList = List<Fraction>.from(
        json['fractions'].map((x) => Fraction.fromJson(x)),
      );
    }

    return Item(
      id: json['id'],
      name: json['name'],
      categoryId: json['categoryId'] ?? "Unknown",
      category: json['Category'] != null
          ? Category.fromJson(json['Category'])
          : null,
      fractions: fractionsList,
    );
  } catch (e) {
    print('Error parsing Item from JSON: $e');
    return Item(
      id: "",
      name: 'Unknown',
      categoryId: "",
      category: null,
      fractions: [],
    );
  }
}

  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
    };
  }

  @override
  String toString() {
    return 'Item(id: $id, name: $name, categoryId: $categoryId, category: $category, fractions: $fractions)';
  }
}
