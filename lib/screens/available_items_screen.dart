import 'package:flutter/material.dart';
import 'package:inventory_frontend/widgets/fraction_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/screens/owner/transactions_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:inventory_frontend/screens/salesman/sell_item_screen.dart';

class AvailableItemsScreen extends StatefulWidget {
  final String? shopId;
  const AvailableItemsScreen({Key? key, this.shopId}) : super(key: key);

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
    await availableItemProvider.fetchAvailableItems(shopId: widget.shopId);

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

  void _onSellItem(dynamic availableItem, dynamic selectedFraction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SellItemScreen(
          preSelectedAvailableItem: availableItem,
          preSelectedAvailableFraction: selectedFraction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Widget content = _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AvailableItemProvider>(
              builder: (context, availableItemProvider, child) {
                if (availableItemProvider.availableItems.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noItemsFound,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: availableItem.item?.name ?? l10n.unknownItem,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.black,
                                              ),
                                            ),
                                            if (availableItem.shop?.name != null && availableItem.shop!.name.isNotEmpty)
                                              TextSpan(
                                                text: ' (${availableItem.shop!.name})',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 14,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.soldPrice(double.parse(selectedFraction.sellingPrice.toStringAsFixed(2))),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2,
                                        size: 14,
                                        color: Colors.blue[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${displayedQuantity.toStringAsFixed(2)} ${selectedFraction.name}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: Row(
                                  children: [
                                    if (itemFractions.isNotEmpty)
                                      Expanded(
                                        child: FractionDropdown(
                                          fractions: itemFractions,
                                          selectedFractionId: selectedFractionId,
                                          onChanged: (value) => _updateSelectedFraction(availableItem.id, value),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.history, size: 20),
                                      onPressed: () => _navigateToTransactions(availableItem),
                                      tooltip: l10n.viewTransactions,
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton.icon(
                                      onPressed: () => _onSellItem(availableItem, selectedFraction),
                                      icon: const Icon(Icons.point_of_sale, size: 16),
                                      label: Text(l10n.sellItem, style: const TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(minimumSize: const Size(60, 28), padding: const EdgeInsets.symmetric(horizontal: 6)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );

    // If shopId is provided, don't show Scaffold or AppBar (for embedding in tabs)
    if (widget.shopId != null) {
      return content;
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.availableItems),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAvailableItems,
            ),
          ],
        ),
        body: content,
      );
    }
  }
} 
