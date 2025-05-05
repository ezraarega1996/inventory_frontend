import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';

class AvailableItemsScreen extends StatefulWidget {
  const AvailableItemsScreen({Key? key}) : super(key: key);

  @override
  State<AvailableItemsScreen> createState() => _AvailableItemsScreenState();
}

class _AvailableItemsScreenState extends State<AvailableItemsScreen> {
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
                    itemBuilder: (context, index) {
                      final availableItem = availableItemProvider.availableItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(availableItem.item?.name ?? 'Unknown Item'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quantity: ${availableItem.quantity}'),
                              Text('Sold Price: ${availableItem.soldPrice}'),
                              Text('Salesman: ${availableItem.salesman?.name ?? 'Unknown Salesman'}'),]
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
} 