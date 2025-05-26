import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';
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
  final Map<String, String> _selectedFractionIds =
      {}; // availableItemId -> fractionId

  @override
  void initState() {
    super.initState();
    _loadAvailableItems();
  }

  Future<void> _loadAvailableItems() async {
    final availableItemProvider = Provider.of<AvailableItemProvider>(
      context,
      listen: false,
    );
    await availableItemProvider.fetchAvailableItems();
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
    final availableItemProvider = Provider.of<AvailableItemProvider>(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

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
      body: RefreshIndicator(
        onRefresh: _loadAvailableItems,
        child:
            availableItemProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : availableItemProvider.availableItems.isEmpty
                ? const Center(child: Text('No available items found'))
                : ListView.builder(
                  itemCount: availableItemProvider.availableItems.length,
                  itemBuilder: (context, index) {
                    final availableItem =
                        availableItemProvider.availableItems[index];
                    final itemFractions = availableItem.item?.fractions ?? [];
                    String selectedFractionId =
                        _selectedFractionIds[availableItem.id] ??
                        (itemFractions.isNotEmpty
                            ? itemFractions.first.id
                            : '');
                    Fraction? selectedFraction = itemFractions.firstWhere(
                      (f) => f.id == selectedFractionId,
                      orElse: () => itemFractions.first,
                    );

                    // Calculate displayed quantity if you want to convert based on fraction
                    final displayedQuantity =
                        selectedFraction != null
                            ? availableItem.quantity / selectedFraction.ratio
                            : availableItem.quantity;

                    final transactions = _getCombinedTransactions(
                      availableItem,
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          "${availableItem.item?.name ?? 'Unknown Item'} (${availableItem.salesman?.name ?? 'Unknown Salesman'})",
                        ),
                        subtitle: Text(
                          'Available Quantity: $displayedQuantity ${selectedFraction?.name ?? ""}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item details
                                Text(
                                  'Item: ${availableItem.item?.name ?? 'Unknown'}',
                                ),
                                Text(
                                  'Available Quantity: $displayedQuantity ${selectedFraction?.name ?? ""}',
                                ),
                                Text(
                                  'Sold Price: \$${availableItem.soldPrice.toStringAsFixed(2)}',
                                ),
                                Text(
                                  'Salesman: ${availableItem.salesman?.name ?? 'Unknown Salesman'}',
                                ),

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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: transactions.length,
                                    itemBuilder: (context, index) {
                                      final transaction = transactions[index];
                                      final isBought =
                                          transaction['type'] == 'bought';
                                      final dynamic trans =
                                          transaction['transaction'];

                                      return Card(
                                        color:
                                            isBought
                                                ? Colors.blue.shade50
                                                : Colors.green.shade50,
                                        child: ListTile(
                                          leading: Icon(
                                            isBought
                                                ? Icons.shopping_cart
                                                : Icons.point_of_sale,
                                            color:
                                                isBought
                                                    ? Colors.blue
                                                    : Colors.green,
                                          ),
                                          title: Text(
                                            isBought ? 'Bought' : 'Sold',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isBought
                                                      ? Colors.blue
                                                      : Colors.green,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Quantity: ${trans.quantity}',
                                              ),
                                              Text(
                                                'Fraction: ${trans.fraction?.name ?? (availableItem.item?.fractions?.firstWhere((f) => f.id == trans.fractionId, orElse: () => Fraction(id: '', name: 'Unknown', ratio: 1, price: 0, itemId: '')).name ?? 'Unknown')}',
                                              ),
                                              Text(
                                                'Price: \$${(isBought ? trans.fractionSoldPrice : trans.soldPrice).toStringAsFixed(2)}',
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

                                const SizedBox(height: 16),
                                if (itemFractions.isNotEmpty)
                                  DropdownButton<String>(
                                    value: selectedFractionId,
                                    items:
                                        itemFractions.map((fraction) {
                                          return DropdownMenuItem<String>(
                                            value: fraction.id,
                                            child: Text(fraction.name),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFractionIds[availableItem.id] =
                                            value!;
                                      });
                                    },
                                  ),
                                // Show converted quantity and price for each fraction
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      itemFractions.map((fraction) {
                                        // Calculate quantity and price for this fraction
                                        final convertedQuantity =
                                            availableItem.quantity /
                                            fraction.ratio;
                                        final convertedPrice =
                                            availableItem.soldPrice *
                                            fraction.ratio;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: Text(
                                            'As ${fraction.name}: ${convertedQuantity.toStringAsFixed(2)} @ \$${convertedPrice.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color:
                                                  fraction.id ==
                                                          selectedFractionId
                                                      ? Colors.blue
                                                      : Colors.black,
                                              fontWeight:
                                                  fraction.id ==
                                                          selectedFractionId
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                        );
                                      }).toList(),
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
