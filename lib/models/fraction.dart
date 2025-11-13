class Fraction {
  final String id;
  final String name;
  final double ratio;
  final double sellingPrice;
  final double purchasePrice;
  final String itemId;
  final bool isUnit;
  
  Fraction({
    required this.id,
    required this.name,
    required this.ratio,
    required this.sellingPrice,
    required this.purchasePrice,
    required this.itemId,
    this.isUnit = false,
  });
  
  factory Fraction.fromJson(Map<String, dynamic> json) {
    return Fraction(
      id: json['id'],
      name: json['name'],
      ratio: json['ratio'].toDouble(),
      sellingPrice: (json['sellingPrice'] ?? json['price']).toDouble(),
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      itemId: json['itemId'],
      isUnit: json['isUnit'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ratio': ratio,
      'sellingPrice': sellingPrice,
      'purchasePrice': purchasePrice,
      'itemId': itemId,
      'isUnit': isUnit,
    };
  }

  @override
  String toString() {
    return 'Fraction(id: $id, name: $name, ratio: $ratio, sellingPrice: $sellingPrice, purchasePrice: $purchasePrice, itemId: $itemId, isUnit: $isUnit)';
  }
}
