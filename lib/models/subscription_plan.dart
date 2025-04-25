class SubscriptionPlan {
  final String displayName;
  final double price;
  final String currency;
  final List<String> features;

  SubscriptionPlan({
    required this.displayName,
    required this.price,
    required this.currency,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      displayName: json['displayName'],
      price: json['price'].toDouble(),
      currency: json['currency'],
      features: List<String>.from(json['features']),
    );
  }
} 