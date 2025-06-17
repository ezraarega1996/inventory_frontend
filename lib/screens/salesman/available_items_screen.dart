import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/widgets/fraction_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/screens/salesman/transactions_screen.dart';

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

  void _updateSelectedFraction(String availableItemId, String fractionId) {
    setState(() {
      _selectedFractionIds[availableItemId] = fractionId;
    });
  }

  void _navigateToTransactions(dynamic availableItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionsScreen(availableItem: availableItem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final availableItemProvider = Provider.of<AvailableItemProvider>(context);

    // Get items assigned to this salesman
    final assignedItems = itemProvider.items.where((item) {
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
      body: _isLoading
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

                      final itemFractions = item.fractions ?? [];
                      final selectedFractionId = _selectedFractionIds[availableItem.id] ?? 
                          (itemFractions.isNotEmpty ? itemFractions.first.id : '');
                      final selectedFraction = itemFractions.firstWhere(
                        (f) => f.id == selectedFractionId,
                        orElse: () => itemFractions.first,
                      );

                      final displayedQuantity = selectedFraction != null
                          ? availableItem.quantity / selectedFraction.ratio
                          : availableItem.quantity;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(
                            item.name,
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (itemFractions.isNotEmpty)
                                FractionDropdown(
                                  fractions: itemFractions,
                                  selectedFractionId: selectedFractionId,
                                  onChanged: (value) => _updateSelectedFraction(availableItem.id, value),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.history),
                                onPressed: () => _navigateToTransactions(availableItem),
                                tooltip: 'View Transactions',
                              ),
                              IconButton(
                                icon: const Icon(Icons.sell),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/sell-item',
                                    arguments: {
                                      'preSelectedItem': item,
                                      'preSelectedFraction': item.fractions
                                          ?.firstWhere(
                                            (f) =>
                                                f.id ==
                                                _selectedFractionIds[availableItem.id],
                                            orElse: () =>
                                                item.fractions!.first,
                                          ),
                                    },
                                  );
                                },
                                tooltip: 'Sell Item',
                              ),
                            ],
                          ),
                          onTap: () => _navigateToTransactions(availableItem),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
} 
