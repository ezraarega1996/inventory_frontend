class SalesData {
  final String salesmanId;
  final String salesmanName;
  final double totalAmount;
  final int totalTransactions;

  SalesData({
    required this.salesmanId,
    required this.salesmanName,
    required this.totalAmount,
    required this.totalTransactions,
  });

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      salesmanId: json['salesmanId'].toString(),
      salesmanName: json['salesmanName'] ?? 'Unknown',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'SalesData(salesmanId: $salesmanId, salesmanName: $salesmanName, totalAmount: $totalAmount, totalTransactions: $totalTransactions)';
  }
} 