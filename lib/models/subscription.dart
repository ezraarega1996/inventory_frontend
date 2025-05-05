class SubscriptionPlan {
  final String name;
  final String displayName;
  final double price;
  final String currency;
  final List<String> features;
  final Map<String, dynamic> limits;
  
  SubscriptionPlan({
    required this.name,
    required this.displayName,
    required this.price,
    required this.currency,
    required this.features,
    required this.limits,
  });
  
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json, String name) {
    return SubscriptionPlan(
      name: name,
      displayName: json['name'],
      price: json['price'].toDouble(),
      currency: json['currency'],
      features: List<String>.from(json['features']),
      limits: json['limits'],
    );
  }

  @override
  String toString() {
    return 'SubscriptionPlan(name: $name, displayName: $displayName, price: $price, currency: $currency, features: $features, limits: $limits)';
  }
}
