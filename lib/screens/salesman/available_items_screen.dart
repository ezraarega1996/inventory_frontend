import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final availableItemProvider = Provider.of<AvailableItemProvider>(context);

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

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item details
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (item.fractions != null && item.fractions!.isNotEmpty)
                                      Builder(
                                        builder: (context) {
                                          String selectedFractionId = _selectedFractionIds[item.id] ?? item.fractions!.first.id;
                                          Fraction selectedFraction = item.fractions!.firstWhere(
                                            (f) => f.id == selectedFractionId,
                                            orElse: () => item.fractions!.first,
                                          );
                                          double fractionQuantity = availableItem.quantity / selectedFraction.ratio;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Quantity: ${fractionQuantity.toStringAsFixed(2)} ${selectedFraction.name}',
                                                style: const TextStyle(fontSize: 16, color: Colors.green),
                                              ),
                                              Text(
                                                'Price: \$${selectedFraction.price}',
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    const SizedBox(height: 16),
                                    CustomButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/sell-item',
                                          arguments: {
                                            'preSelectedItem': item,
                                          },
                                        );
                                      },
                                      text: 'Sell Item',
                                    ),
                                  ],
                                ),
                              ),
                              // Dropdown
                              if (item.fractions != null && item.fractions!.isNotEmpty)
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: DropdownButton<String>(
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
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
} 