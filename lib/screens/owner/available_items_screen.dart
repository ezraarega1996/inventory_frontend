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
                                Text(
                                  'Sold Price: \$${availableItem.soldPrice.toStringAsFixed(2)}',
                                ),
                                Text(
                                  'Salesman: ${availableItem.salesman?.name ?? 'Unknown Salesman'}',
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
                                      onChanged: (value) {
                                        setState(() {
                                      _selectedFractionIds[availableItem.id] = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                if (transactions.isEmpty)
                                  const Text('No transactions found')
                                else                              // ...existing code...
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: transactions.length,
                                  itemBuilder: (context, index) {
                                    final transaction = transactions[index];
                                    final isBought = transaction['type'] == 'bought';
                                    final dynamic trans = transaction['transaction'];

                                    // Get the original fraction of the transaction
                                    final Fraction? transactionFraction = itemFractions.firstWhere(
                                      (f) => f.id == trans.fractionId,
                                      orElse: () => itemFractions.first,
                                    );

                                    // Convert quantity to selected fraction
                                    double convertedQuantity = trans.quantity;
                                    if (transactionFraction != null && selectedFraction != null) {
                                      convertedQuantity = trans.quantity * transactionFraction.ratio / selectedFraction.ratio;
                                    }

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
                                            Text(
                                              'Quantity: ${convertedQuantity.toStringAsFixed(2)} ${selectedFraction?.name ?? ''}',
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
