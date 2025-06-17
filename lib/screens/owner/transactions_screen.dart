import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/bought.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/providers/bought_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/models/available_item.dart';

class TransactionsScreen extends StatefulWidget {
  final AvailableItem availableItem;
  
  const TransactionsScreen({
    Key? key,
    required this.availableItem,
  }) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final Map<String, String> _selectedFractionIds = {}; // availableItemId -> fractionId

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
    final selectedFractionId = _selectedFractionIds[widget.availableItem.id] ?? 
        (itemFractions.isNotEmpty ? itemFractions.first.id : '');
    final selectedFraction = itemFractions.firstWhere(
      (f) => f.id == selectedFractionId,
      orElse: () => itemFractions.first,
    );

    final displayedQuantity = selectedFraction != null
        ? widget.availableItem.quantity / selectedFraction.ratio
        : widget.availableItem.quantity;

    final transactions = _getCombinedTransactions();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions - ${widget.availableItem.item?.name ?? 'Unknown Item'}'),
      ),
      body: Column(
        children: [
          // Item summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    // Item information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.availableItem.item?.name ?? 'Unknown Item'} (${widget.availableItem.salesman?.name ?? 'Unknown Salesman'})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Available Quantity: ${displayedQuantity.toStringAsFixed(2)} ${selectedFraction?.name ?? ""}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Sold Price: \$${widget.availableItem.soldPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    // Fraction selector
                    if (itemFractions.isNotEmpty)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.swap_horiz, size: 16),
                          const SizedBox(height: 4),
                          DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          value: _selectedFractionIds[widget.availableItem.id] ?? itemFractions.first.id,
          items: itemFractions.map((fraction) {
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
              _selectedFractionIds[widget.availableItem.id] = value!;
            });
          },
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
        ),
      ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Transactions list
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
          ),
        ],
      ),
    );
  }
} 