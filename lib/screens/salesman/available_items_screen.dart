import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/widgets/fraction_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/models/item_bought.dart';
import 'package:inventory_frontend/models/sold_item.dart';
import 'package:inventory_frontend/screens/available_item_detail_screen.dart';

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
          items: fractions.map((fraction) {
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
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Available Quantity: ${availableItem.quantity}\nSold Price: \$${availableItem.soldPrice.toStringAsFixed(2)}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AvailableItemDetailScreen(
                                availableItem: availableItem,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
