import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/widgets/fraction_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/models/item_bought.dart';
import 'package:inventory_frontend/models/sold_item.dart';

class AvailableItemsScreen extends StatefulWidget {
  const AvailableItemsScreen({Key? key}) : super(key: key);

  @override
  State<AvailableItemsScreen> createState() => _AvailableItemsScreenState();
}

class _AvailableItemsScreenState extends State<AvailableItemsScreen> {
  final Map<String, String> _selectedFractionIds = {}; // availableItemId -> fractionId
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableItems();
  }

  Future<void> _loadAvailableItems() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    final availableItemProvider = context.read<AvailableItemProvider>();
    await availableItemProvider.fetchAvailableItems();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateSelectedFraction(String availableItemId, String fractionId) {
    setState(() {
      _selectedFractionIds[availableItemId] = fractionId;
    });
  }

  List<Map<String, dynamic>> _getCombinedTransactions(dynamic availableItem) {
    final List<Map<String, dynamic>> transactions = [];

    if (availableItem.boughtTransactions != null) {
      for (var transaction in availableItem.boughtTransactions!) {
        transactions.add({
          'type': 'bought',
          'transaction': transaction,
          'date': transaction.createdAt,
        });
      }
    }

    if (availableItem.soldTransactions != null) {
      for (var transaction in availableItem.soldTransactions!) {
        transactions.add({
          'type': 'sold',
          'transaction': transaction,
          'date': transaction.createdAt,
        });
      }
    }

    transactions.sort((a, b) => b['date'].compareTo(a['date']));
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableItems,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AvailableItemProvider>(
              builder: (context, availableItemProvider, child) {
                if (availableItemProvider.availableItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'No available items found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                return RefreshIndicator(
        onRefresh: _loadAvailableItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: availableItemProvider.availableItems.length,
              itemBuilder: (context, index) {
                final availableItem = availableItemProvider.availableItems[index];
                final itemFractions = availableItem.item?.fractions ?? [];
                      final selectedFractionId = _selectedFractionIds[availableItem.id] ?? 
                          (itemFractions.isNotEmpty ? itemFractions.first.id : '');
                      final selectedFraction = itemFractions.firstWhere(
                  (f) => f.id == selectedFractionId,
                        orElse: () => itemFractions.first,
                );

                final displayedQuantity = selectedFraction != null
                    ? availableItem.quantity / selectedFraction.ratio
                    : availableItem.quantity;

                      final transactions = _getCombinedTransactions(availableItem);
                return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          title: Text(
                            "${availableItem.item?.name ?? 'Unknown Item'} (${availableItem.salesman?.name ?? 'Unknown Salesman'})",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Quantity: ${displayedQuantity.toStringAsFixed(2)} ${selectedFraction?.name ?? ""}',
                              ),
                              Text(
                                'Sold Price: \$${availableItem.soldPrice.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Salesman: ${availableItem.salesman?.name ?? 'Unknown Salesman'}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Transaction History',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                        if (itemFractions.isNotEmpty)
                                        FractionDropdown(
                                          fractions: itemFractions,
                                          selectedFractionId: selectedFractionId,
                                          onChanged: (value) => _updateSelectedFraction(availableItem.id, value),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (transactions.isEmpty)
                                    const Text('No transactions found')
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: transactions.length,
                                      itemBuilder: (context, index) {
                                        final transaction = transactions[index];
                                        final isBought = transaction['type'] == 'bought';
                                        final dynamic trans = transaction['transaction'];
                                        final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

                                        final transactionFraction = itemFractions.firstWhere(
                                          (f) => f.id == trans.fractionId,
                                          orElse: () => itemFractions.first,
                                        );

                                        double convertedQuantity = trans.quantity;
                                        if (transactionFraction != null && selectedFraction != null) {
                                          convertedQuantity = trans.quantity * transactionFraction.ratio / selectedFraction.ratio;
                                        }
                                        double convertedAvailableQty = trans.available_items_count;
                                        if (transactionFraction != null && selectedFraction != null) {
                                          convertedAvailableQty = trans.available_items_count * transactionFraction.ratio / selectedFraction.ratio;
                                        }


                                        return Card(
                                          color: isBought ? Colors.blue.shade50 : Colors.green.shade50,
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            leading: Icon(
                                              isBought ? Icons.shopping_cart : Icons.point_of_sale,
                                              color: isBought ? Colors.blue : Colors.green,
                                            ),
                                            title: Text(
                                              isBought ? 'Bought' : 'Sold',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isBought ? Colors.blue : Colors.green,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Quantity: ${convertedQuantity.toStringAsFixed(2)} ${selectedFraction?.name ?? ''}',
                                                ),

                                                Text(
                                                  'Price: \$${(isBought ? trans.fractionSoldPrice : trans.soldPrice).toStringAsFixed(2)}',
                                                ),
                                                  Text(
                                                    'Available Quantity: ${convertedAvailableQty.toStringAsFixed(2)} ${selectedFraction?.name ?? ''}',
                                                  ),
                                                Text(
                                                  'Date: ${dateFormat.format(trans.createdAt)}',
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                            ),
                          ),
                      ],
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
