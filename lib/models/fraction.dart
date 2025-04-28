class Fraction {
  final String id;
  final String name;
  final double ratio;
  final double price;
  final String itemId;
  final bool isUnit;
  
  Fraction({
    required this.id,
    required this.name,
    required this.ratio,
    required this.price,
    required this.itemId,
    this.isUnit = false,
  });
  
  factory Fraction.fromJson(Map<String, dynamic> json) {
    return Fraction(
      id: json['id'],
      name: json['name'],
      ratio: json['ratio'].toDouble(),
      price: json['price'].toDouble(),
      itemId: json['itemId'],
      isUnit: json['isUnit'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ratio': ratio,
      'price': price,
      'itemId': itemId,
      'isUnit': isUnit,
    };
  }
}
