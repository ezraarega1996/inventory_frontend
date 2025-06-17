import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/widgets/fraction_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/screens/owner/transactions_screen.dart';

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

  void _navigateToTransactions(dynamic availableItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionsScreen(availableItem: availableItem),
      ),
    );
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

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: RichText(
                        text: TextSpan(
                          children: [
                                TextSpan(
                                  text: "${availableItem.item?.name ?? 'Unknown Item'} ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: "(${availableItem.salesman?.name ?? 'Unknown Salesman'})",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14, // Smaller font size
                                  ),
                                ),
                              ],
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
                            ],
                          ),
                          onTap: () => _navigateToTransactions(availableItem),
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
