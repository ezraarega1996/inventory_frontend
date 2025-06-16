import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class AvailableItemDetailScreen extends StatefulWidget {
  final AvailableItem availableItem;

  const AvailableItemDetailScreen({super.key, required this.availableItem});

  @override
  State<AvailableItemDetailScreen> createState() =>
      _AvailableItemDetailScreenState();
}

class _AvailableItemDetailScreenState extends State<AvailableItemDetailScreen> {
  String? _selectedFractionId;
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    if (widget.availableItem.item?.fractions?.isNotEmpty ?? false) {
      _selectedFractionId = widget.availableItem.item!.fractions!.first.id;
    }
  }

  List<Map<String, dynamic>> _getCombinedTransactions() {
    final List<Map<String, dynamic>> transactions = [];

    if (widget.availableItem.boughtTransactions != null) {
      for (var transaction in widget.availableItem.boughtTransactions!) {
        transactions.add({
          'type': 'bought',
          'transaction': transaction,
          'date': transaction.createdAt,
        });
      }
    }

    if (widget.availableItem.soldTransactions != null) {
      for (var transaction in widget.availableItem.soldTransactions!) {
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
    final itemFractions = widget.availableItem.item?.fractions ?? [];
    final selectedFraction = itemFractions.firstWhere(
      (f) => f.id == _selectedFractionId,
      orElse: () => itemFractions.first,
    );

    final displayedQuantity =
        selectedFraction != null
            ? widget.availableItem.quantity / selectedFraction.ratio
            : widget.availableItem.quantity;

    final transactions = _getCombinedTransactions();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.availableItem.item?.name ?? 'Unknown Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Item Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      'Name',
                      widget.availableItem.item?.name ?? 'Unknown',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Salesman',
                      widget.availableItem.salesman?.name ?? 'Not assigned',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Sold Price',
                      '${widget.availableItem.soldPrice.toStringAsFixed(2)} ETB',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Available Items Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Available Items',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    if (itemFractions.isEmpty)
                      const Center(child: Text('No units available'))
                    else
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedFractionId,
                            decoration: const InputDecoration(
                              labelText: 'Select Unit',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                itemFractions.map((fraction) {
                                  return DropdownMenuItem<String>(
                                    value: fraction.id,
                                    child: Text(fraction.name),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFractionId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Available Quantity: ${displayedQuantity.toStringAsFixed(2)} ${selectedFraction.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Base Price: ${selectedFraction.price.toStringAsFixed(2)} ETB',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transactions Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Transaction History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    if (transactions.isEmpty)
                      const Center(child: Text('No transactions found'))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final isBought = transaction['type'] == 'bought';
                          final dynamic trans = transaction['transaction'];
                          final transactionFraction = itemFractions.firstWhere(
                            (f) => f.id == trans.fractionId,
                            orElse: () => itemFractions.first,
                          );

                          double convertedQuantity = trans.quantity;
                          if (selectedFraction != null) {
                            convertedQuantity =
                                trans.quantity *
                                transactionFraction.ratio /
                                selectedFraction.ratio;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color:
                                isBought
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                            child: ListTile(
                              leading: Icon(
                                isBought
                                    ? Icons.add_circle
                                    : Icons.remove_circle,
                                color: isBought ? Colors.green : Colors.red,
                              ),
                              title: Text(
                                isBought ? 'Bought' : 'Sold',
                                style: TextStyle(
                                  color: isBought ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quantity: ${convertedQuantity.toStringAsFixed(2)} ${selectedFraction.name}',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
