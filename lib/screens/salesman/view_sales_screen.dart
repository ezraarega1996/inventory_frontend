import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/screens/salesman/sale_detail_screen.dart';

class ViewSalesScreen extends StatefulWidget {
  const ViewSalesScreen({Key? key}) : super(key: key);

  @override
  State<ViewSalesScreen> createState() => _ViewSalesScreenState();
}

class _ViewSalesScreenState extends State<ViewSalesScreen> {
  @override
  void initState() {
    super.initState();
    _loadSales();
  }
  
  Future<void> _loadSales() async {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    await salesProvider.fetchUserSales();
  }
  
  void _viewSaleDetails(int index) {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final sale = salesProvider.sales[index];
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaleDetailScreen(sale: sale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSales,
        child: salesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : salesProvider.sales.isEmpty
            ? const Center(child: Text('No sales found'))
            : ListView.builder(
                itemCount: salesProvider.sales.length,
                itemBuilder: (context, index) {
                  final sale = salesProvider.sales[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(sale.item?.name ?? 'Unknown Item'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fraction: ${sale.fractionId}'),
                          Text('Quantity: ${sale.quantity}'),
                          Text('Amount: \$${sale.amount}'),
                          Text('Date: ${dateFormat.format(sale.soldTime)}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _viewSaleDetails(index),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
