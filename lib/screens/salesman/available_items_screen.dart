import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
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
  bool _isLoading = true;
  final Map<String, String> _selectedFractionIds = {}; // itemId -> fractionId

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final availableItemProvider = Provider.of<AvailableItemProvider>(context, listen: false);

    await Future.wait([
      itemProvider.fetchItems(),
      availableItemProvider.fetchAvailableItems(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getCombinedTransactions(dynamic availableItem) {
    final List<Map<String, dynamic>> transactions = [];
    
    // Add bought transactions
    if (availableItem.boughtTransactions != null) {
      for (var transaction in availableItem.boughtTransactions!) {
        transactions.add({
          'type': 'bought',
          'transaction': transaction,
          'date': transaction.createdAt,
        });
      }
    }
    
    // Add sold transactions
    if (availableItem.soldTransactions != null) {
      for (var transaction in availableItem.soldTransactions!) {
        transactions.add({
          'type': 'sold',
          'transaction': transaction,
          'date': transaction.createdAt,
        });
      }
    }
    
    // Sort by date in descending order (most recent first)
    transactions.sort((a, b) => b['date'].compareTo(a['date']));
    
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final availableItemProvider = Provider.of<AvailableItemProvider>(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Get items assigned to this salesman
    final assignedItems = itemProvider.items.where((item) {
      final availableItems = availableItemProvider.getAvailableItemsForSalesman(authProvider.user!.id);
      return availableItems.any((availableItem) => availableItem.itemId == item.id);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : assignedItems.isEmpty
              ? const Center(
                  child: Text(
                    'No items assigned to you',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: assignedItems.length,
                    itemBuilder: (context, index) {
                      final item = assignedItems[index];
                      final availableItem = availableItemProvider
                          .getAvailableItemsForSalesman(authProvider.user!.id)
                          .firstWhere((ai) => ai.itemId == item.id);

                      final transactions = _getCombinedTransactions(availableItem);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('Available Quantity: ${availableItem.quantity}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Item details
                                  Text('Item: ${item.name}'),
                                  Text('Available Quantity: ${availableItem.quantity}'),
                                  Text('Sold Price: \$${availableItem.soldPrice.toStringAsFixed(2)}'),
                                  
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Transaction History',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
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
                                        
                                        return Card(
                                          color: isBought ? Colors.blue.shade50 : Colors.green.shade50,
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
                                                Text('Quantity: ${trans.quantity}'),
                                                Text('Fraction: ${trans.fraction?.name ?? 'Unknown'}'),
                                                Text('Price: \$${(isBought ? trans.fractionSoldPrice : trans.soldPrice).toStringAsFixed(2)}'),
                                                Text('Date: ${dateFormat.format(trans.createdAt)}'),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                  const SizedBox(height: 16),
                                  if (item.fractions != null && item.fractions!.isNotEmpty)
                                    DropdownButton<String>(
                                      value: _selectedFractionIds[item.id] ?? item.fractions!.first.id,
                                      items: item.fractions!.map((fraction) {
                                        return DropdownMenuItem<String>(
                                          value: fraction.id,
                                          child: Text(fraction.name),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedFractionIds[item.id] = value!;
                                        });
                                      },
                                    ),
                                  const SizedBox(height: 8),
                                  CustomButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/sell-item',
                                        arguments: {
                                          'preSelectedItem': item,
                                          'preSelectedFraction': item.fractions?.firstWhere(
                                            (f) => f.id == _selectedFractionIds[item.id],
                                            orElse: () => item.fractions!.first,
                                          ),
                                        },
                                      );
                                    },
                                    text: 'Sell Item',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
} 