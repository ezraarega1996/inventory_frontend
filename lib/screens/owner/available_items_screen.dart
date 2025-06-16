import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/widgets/fraction_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/providers/salesman_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/models/item_bought.dart';
import 'package:inventory_frontend/models/sold_item.dart';
import 'package:inventory_frontend/screens/owner/available_item_detail_screen.dart';

class AvailableItemsScreen extends StatefulWidget {
  const AvailableItemsScreen({super.key});

  @override
  State<AvailableItemsScreen> createState() => _AvailableItemsScreenState();
}

class _AvailableItemsScreenState extends State<AvailableItemsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final availableItemProvider = context.read<AvailableItemProvider>();
    final salesmanProvider = context.read<SalesmanProvider>();

    await Future.wait([
      availableItemProvider.fetchAvailableItems(),
      salesmanProvider.fetchSalesmen(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              : Consumer<AvailableItemProvider>(
                builder: (context, availableItemProvider, child) {
                  if (availableItemProvider.availableItems.isEmpty) {
                    return const Center(
                      child: Text(
                        'No available items found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: availableItemProvider.availableItems.length,
                      itemBuilder: (context, index) {
                        final availableItem =
                            availableItemProvider.availableItems[index];
                        final itemFractions =
                            availableItem.item?.fractions ?? [];
                        final selectedFraction =
                            itemFractions.isNotEmpty
                                ? itemFractions.first
                                : null;
                        final displayedQuantity =
                            selectedFraction != null
                                ? availableItem.quantity /
                                    selectedFraction.ratio
                                : availableItem.quantity;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => AvailableItemDetailScreen(
                                        availableItem: availableItem,
                                      ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              availableItem.item?.name ??
                                                  'Unknown Item',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Salesman: ${availableItem.salesman?.name ?? 'Not assigned'}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Available: ${displayedQuantity.toStringAsFixed(2)} ${selectedFraction?.name ?? ""}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${availableItem.soldPrice.toStringAsFixed(2)} ETB',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
