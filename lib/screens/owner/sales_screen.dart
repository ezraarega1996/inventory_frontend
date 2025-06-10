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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }
  
  Future<void> _loadSales() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    await context.read<SalesProvider>().fetchSales();
    if (mounted) {
      setState(() { _isLoading = false; });
    }
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
      final salesProvider = context.read<SalesProvider>();
      final success = await salesProvider.deleteSale(id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale deleted successfully'))
        );
        await _loadSales();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(salesProvider.error ?? 'An error occurred'))
        );
      }
    }
  }
  
  void _viewSaleDetails(int index) {
    final salesProvider = context.read<SalesProvider>();
    final sale = salesProvider.sales[index];
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaleDetailScreen(sale: sale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      bottomNavigationBar: Consumer<SalesProvider>(
        builder: (context, salesProvider, child) {
          final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
          final today = DateTime.now();
          final todaySales = salesProvider.sales.where((sale) {
            final saleDate = sale.createdAt;
            return saleDate.year == today.year &&
                saleDate.month == today.month &&
                saleDate.day == today.day;
          }).toList();
          final todayAmount = todaySales.fold<double>(
            0.0,
            (sum, sale) => sum + (sale.soldPrice ?? 0),
          );
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Sales:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${todayAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SalesProvider>(
              builder: (context, salesProvider, child) {
                if (salesProvider.sales.isEmpty) {
                  return const Center(child: Text('No sales found'));
                }
                return RefreshIndicator(
                  onRefresh: _loadSales,
                  child: ListView.builder(
                    itemCount: salesProvider.sales.length,
                    itemBuilder: (context, index) {
                      final sale = salesProvider.sales[index];
                      final itemFractions = sale.item?.fractions ?? [];
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
                                        Text('${sale.item?.name}(${sale.salesman?.name ?? 'Unknown Salesman'})'),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text('Quantity: ${sale.quantity * sale.fraction!.ratio / selectedFraction!.ratio} ${selectedFraction.name}'),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text('Amount: \$${sale.soldPrice}'),
                                            ),
                                            Expanded(
                                              child: sale.available_items_count != null
                                                ? Text('Available: ${sale.available_items_count! * sale.fraction!.ratio / selectedFraction.ratio} ${selectedFraction.name}')
                                                : const SizedBox(),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(sale.createdAt)}'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (itemFractions.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (value) {
                                          if (value == 'delete') {
                                            _deleteSale(sale.id);
                                          } else {
                                            setState(() {
                                              _selectedFractionIds[sale.id] = value;
                                            });
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          ...itemFractions.map((fraction) => PopupMenuItem<String>(
                                            value: fraction.id,
                                            child: Text('View as ${fraction.name}'),
                                          )),
                                          const PopupMenuDivider(),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
                );
              },
            ),
    );
  }
}
