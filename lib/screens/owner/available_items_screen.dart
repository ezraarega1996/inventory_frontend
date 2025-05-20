import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';

class AvailableItemsScreen extends StatefulWidget {
  const AvailableItemsScreen({Key? key}) : super(key: key);

  @override
  State<AvailableItemsScreen> createState() => _AvailableItemsScreenState();
}

class _AvailableItemsScreenState extends State<AvailableItemsScreen> {
  final Map<String, String> _selectedFractionIds = {}; // availableItemId -> fractionId

  @override
  void initState() {
    super.initState();
    _loadAvailableItems();
  }

  Future<void> _loadAvailableItems() async {
    final availableItemProvider = Provider.of<AvailableItemProvider>(context, listen: false);
    await availableItemProvider.fetchAvailableItems();
  }

  @override
  Widget build(BuildContext context) {
    final availableItemProvider = Provider.of<AvailableItemProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Items'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailableItems,
        child: availableItemProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : availableItemProvider.availableItems.isEmpty
                ? const Center(child: Text('No available items found'))
                : ListView.builder(
                    itemCount: availableItemProvider.availableItems.length,
                    // Add this at the top of your _AvailableItemsScreenState class
              // Inside your ListView.builder:
              itemBuilder: (context, index) {
                final availableItem = availableItemProvider.availableItems[index];
                final itemFractions = availableItem.item?.fractions ?? [];
                String selectedFractionId = _selectedFractionIds[availableItem.id] ?? (itemFractions.isNotEmpty ? itemFractions.first.id : '');
                Fraction? selectedFraction = itemFractions.firstWhere(
                  (f) => f.id == selectedFractionId,
                );

                // Calculate displayed quantity if you want to convert based on fraction
                final displayedQuantity = selectedFraction != null
                    ? availableItem.quantity / selectedFraction.ratio
                    : availableItem.quantity;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(availableItem.item?.name ?? 'Unknown Item'),
                    subtitle: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item details
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quantity: $displayedQuantity ${selectedFraction?.name ?? ""}'),
                              Text('Sold Price: ${availableItem.soldPrice}'),
                              Text('Salesman: ${availableItem.salesman?.name ?? 'Unknown Salesman'}'),
                            ],
                          ),
                        ),
                        // Dropdown
                        if (itemFractions.isNotEmpty)
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: DropdownButton<String>(
                                value: selectedFractionId,
                                items: itemFractions.map((fraction) {
                                  return DropdownMenuItem<String>(
                                    value: fraction.id,
                                    child: Text(fraction.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedFractionIds[availableItem.id] = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }
                  ),
      ),
    );
  }
} 