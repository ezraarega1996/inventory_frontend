import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/screens/owner/sale_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {

  final Map<String, String> _selectedFractionIds = {}; // boughtId -> fractionId

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

                // Get all fractions for this item
                final itemFractions = sale.item?.fractions ?? [];
                // // Track selected fraction per sale
                // String selectedFractionId = _selectedFractionIds[sale.id] ?? sale.fraction?.id ?? '';
                // Fraction selectedFraction = itemFractions.firstWhere(
                //   (f) => f.id == selectedFractionId,
                // );

                // // Find the sale record for this fraction (if any)
                // final fractionSale = salesProvider.sales.firstWhere(
                //   (s) => s.itemId == sale.itemId && s.fractionId == selectedFractionId,
                //   orElse: () => sale,
                // );

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      String selectedFractionId = _selectedFractionIds[sale.id] ?? sale.fraction?.id ?? '';
                      Fraction? selectedFraction = sale.item?.fractions?.firstWhere(
                      
                        (f) => f.id == selectedFractionId, 
                        );
                      return ListTile(
                        
                        subtitle: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Salesman: ${sale.salesman?.name ?? 'Unknown Salesman'}'),
                              Text('Quantity: ${sale.quantity * sale.fraction!.ratio / selectedFraction!.ratio} ${selectedFraction.name}'),
                              Text('Amount: \$${sale.soldPrice}'),
                              if (sale.available_items_count != null)
                              Text('Available items: ${sale.available_items_count! * sale.fraction!.ratio / selectedFraction.ratio} ${selectedFraction.name}'),
                              Text('Date: ${dateFormat.format(sale.createdAt)}'),
                            ],
                            ),
                          ),
                          if (itemFractions.isNotEmpty)
                            Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: DropdownButton<String>(
                              value: selectedFractionId,
                              items: itemFractions.map((fraction) {
                              return DropdownMenuItem<String>(
                                value: fraction.id,
                                child: Text(fraction.name),
                              );
                              }).toList(),
                              onChanged: (value) {
                              setState(() {
                                _selectedFractionIds[sale.id] = value!;
                              });
                              },
                            ),
                            ),
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
                      );
                    },
                  ),
                );
              },
            ),
      ),
    );
  }
}
