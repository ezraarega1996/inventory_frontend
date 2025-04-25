import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/screens/owner/sale_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  void initState() {
    super.initState();
    _loadSales();
  }
  
  Future<void> _loadSales() async {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    await salesProvider.fetchSales();
  }
  
  Future<void> _deleteSale(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sale'),
        content: const Text('Are you sure you want to delete this sale? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      final success = await salesProvider.deleteSale(id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale deleted successfully'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(salesProvider.error ?? 'An error occurred'))
        );
      }
    }
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
                          Text('Sold by: ${sale.salesman?.name ?? 'Unknown'}'),
                          Text('Date: ${dateFormat.format(sale.soldTime)}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteSale(sale.id),
                          ),
                        ],
                      ),
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
