import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/widgets/fraction_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class AvailableItemsScreen extends StatefulWidget {
  const AvailableItemsScreen({super.key});

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
    final availableItemProvider = Provider.of<AvailableItemProvider>(
      context,
      listen: false,
    );

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

  Widget _buildFractionDropdown(List<Fraction> fractions, String itemId) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          value: _selectedFractionIds[itemId] ?? fractions.first.id,
          items:
              fractions.map((fraction) {
                return DropdownMenuItem<String>(
                  value: fraction.id,
                  child: Row(
                    children: [
                      Icon(Icons.scale, color: Colors.blue.shade400, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        fraction.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFractionIds[itemId] = value!;
            });
          },
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final availableItemProvider = Provider.of<AvailableItemProvider>(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Get items assigned to this salesman
    final assignedItems =
        itemProvider.items.where((item) {
          final availableItems = availableItemProvider
              .getAvailableItemsForSalesman(authProvider.user!.id);
          return availableItems.any(
            (availableItem) => availableItem.itemId == item.id,
          );
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Items'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : assignedItems.isEmpty
              ? const Center(
                child: Text(
                  'No items assigned to you',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

                    final transactions = _getCombinedTransactions(
                      availableItem,
                    );

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
                        subtitle: Builder(
                          builder: (context) {
                            final selectedFractionId =
                                _selectedFractionIds[item.id] ??
                                item.fractions!.first.id;
                            final selectedFraction = item.fractions!.firstWhere(
                              (f) => f.id == selectedFractionId,
                            );

                            // Convert available quantity to selected fraction
                            num convertAvailableQty(num quantity) {
                              // Find the base fraction (ratio == 1)
                              final baseFraction = item.fractions!.firstWhere(
                                (f) => f.ratio == 1,
                                orElse: () => item.fractions!.first,
                              );
                              // Convert to base, then to selected
                              final baseQty = quantity * baseFraction.ratio;
                              return baseQty / selectedFraction.ratio;
                            }

                            final convertedAvailableQty = convertAvailableQty(
                              availableItem.quantity,
                            );
                            // Show sold price below available quantity
                            final soldPriceText = Text(
                              'Sold Price: ${availableItem.soldPrice.toStringAsFixed(2)} ETB',
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Quantity: ${convertedAvailableQty.toStringAsFixed(2)} ${selectedFraction.name}',
                                ),
                                soldPriceText,
                              ],
                            );
                          },
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Transaction History',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (item.fractions != null &&
                                        item.fractions!.isNotEmpty)
                                      FractionDropdown(
                                        fractions: item.fractions!,
                                        selectedFractionId:
                                            _selectedFractionIds[item.id] ??
                                            item.fractions!.first.id,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedFractionIds[item.id] =
                                                value;
                                          });
                                        },
                                      ),

                                    CustomButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/sell-item',
                                          arguments: {
                                            'preSelectedItem': item,
                                            'preSelectedFraction': item
                                                .fractions
                                                ?.firstWhere(
                                                  (f) =>
                                                      f.id ==
                                                      _selectedFractionIds[item
                                                          .id],
                                                  orElse:
                                                      () =>
                                                          item.fractions!.first,
                                                ),
                                          },
                                        );
                                      },
                                      text: 'Sell Item',
                                    ),
                                  ],
                                ),
                                if (transactions.isEmpty)
                                  const Text('No transactions found')
                                else
                                  Builder(
                                    builder: (context) {
                                      final selectedFractionId =
                                          _selectedFractionIds[item.id] ??
                                          item.fractions!.first.id;
                                      final selectedFraction = item.fractions!
                                          .firstWhere(
                                            (f) => f.id == selectedFractionId,
                                          );

                                      // Helper to convert quantity to selected fraction
                                      num convertToSelectedFraction(
                                        num quantity,
                                        String fromFractionId,
                                      ) {
                                        final fromFraction = item.fractions!
                                            .firstWhere(
                                              (f) => f.id == fromFractionId,
                                              orElse: () => selectedFraction,
                                            );
                                        if (fromFraction.id ==
                                            selectedFraction.id) {
                                          return quantity;
                                        }
                                        // Convert to base, then to selected
                                        final baseQty =
                                            quantity * fromFraction.ratio;
                                        return baseQty / selectedFraction.ratio;
                                      }

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (transactions.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: Text(
                                                'Quantities shown in: ${selectedFraction.name}',
                                                style: const TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: transactions.length,
                                            itemBuilder: (context, index) {
                                              final transaction =
                                                  transactions[index];
                                              final isBought =
                                                  transaction['type'] ==
                                                  'bought';
                                              final dynamic trans =
                                                  transaction['transaction'];
                                              final fromFractionId =
                                                  trans.fractionId ??
                                                  trans.fraction?.id ??
                                                  selectedFraction.id;
                                              final convertedQty =
                                                  convertToSelectedFraction(
                                                    trans.quantity,
                                                    fromFractionId,
                                                  );
                                              final convertedAvailableQty =
                                                  convertToSelectedFraction(
                                                    trans.available_items_count,
                                                    fromFractionId,
                                                  );

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
                                                    isBought
                                                        ? 'Bought'
                                                        : 'Sold',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          isBought
                                                              ? Colors.blue
                                                              : Colors.green,
                                                    ),
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Quantity: ${convertedQty.toStringAsFixed(2)}',
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            selectedFraction
                                                                .name,
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Available: ${convertedAvailableQty.toStringAsFixed(2)}',
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            selectedFraction
                                                                .name,
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        'Price: ${(isBought ? trans.fractionSoldPrice : trans.soldPrice).toStringAsFixed(2)} ETB',
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
