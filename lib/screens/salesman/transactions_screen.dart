import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/bought.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/providers/bought_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    final availableItemProvider = context.read<AvailableItemProvider>();
    await availableItemProvider.fetchAvailableItemTransactions(widget.availableItem.id);

    if (!mounted) return;

    setState(() {
      _transactions = _getCombinedTransactions();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getCombinedTransactions() {
    final List<Map<String, dynamic>> transactions = [];
    final availableItem = context.read<AvailableItemProvider>()
        .getAvailableItem(widget.availableItem.id);

    if (availableItem?.boughtTransactions != null) {
      for (var transaction in availableItem!.boughtTransactions!) {
        transactions.add({
          'type': 'bought',
          'transaction': transaction,
          'date': transaction.createdAt,
        });
      }
    }

    if (availableItem?.soldTransactions != null) {
      for (var transaction in availableItem!.soldTransactions!) {
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
    final l10n = AppLocalizations.of(context)!;
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

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionsFor(widget.availableItem.item?.name ?? l10n.unknownItem)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
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
                            widget.availableItem.item?.name ?? l10n.unknownItem,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.availableQuantity(displayedQuantity, selectedFraction?.name ?? ""),
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            l10n.soldPrice(double.parse(selectedFraction.sellingPrice.toStringAsFixed(2))),
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
                          Container(
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noTransactionsFound,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
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
                          
                          // Format to 2 decimal places for display
                          final formattedQuantity = double.parse(convertedQuantity.toStringAsFixed(2));
                          final formattedAvailableQty = double.parse(convertedAvailableQty.toStringAsFixed(2));

                          return Card(
                            color: isBought ? Colors.blue.shade50 : Colors.green.shade50,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                isBought ? Icons.shopping_cart : Icons.point_of_sale,
                                color: isBought ? Colors.blue : Colors.green,
                              ),
                              title: Text(
                                isBought ? l10n.bought : l10n.sold,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isBought ? Colors.blue : Colors.green,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isBought)
                                    Text(l10n.boughtBy(trans.salesman?.name ?? l10n.unknownSalesman)),
                                  if (!isBought)
                                    Text(l10n.soldBy(trans.salesman?.name ?? l10n.unknownSalesman)),
                                  Text(
                                    l10n.quantity(formattedQuantity, selectedFraction?.name ?? ''),
                                  ),
                                  Text(
                                    l10n.availableQuantity(formattedAvailableQty, selectedFraction?.name ?? ''),
                                  ),
                                  Text(
                                    dateFormat.format(transaction['date']),
                                    style: const TextStyle(fontSize: 12),
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