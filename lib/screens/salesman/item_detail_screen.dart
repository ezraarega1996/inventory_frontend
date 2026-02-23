import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/screens/salesman/sell_item_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  
  const ItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isLoading = false;

  void _navigateToSellScreen([Fraction? fraction]) {
    setState(() {
      _isLoading = true;
    });

    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SellItemScreen(
          ),
        ),
      );
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorNavigatingToSellScreen(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.itemDetails,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '${l10n.name}:',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text(widget.item.name),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '${l10n.category}:',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text(widget.item.category?.name ?? l10n.noCategory),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.availableFractions,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.item.fractions == null || widget.item.fractions!.isEmpty)
                    Center(
                      child: Text(l10n.noFractionsAvailableForItem),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.item.fractions!.length,
                      itemBuilder: (context, index) {
                        final fraction = widget.item.fractions![index];
                        return Card(
                          child: ListTile(
                            title: Text(fraction.name),
                            subtitle: Text('${l10n.ratio}: ${fraction.ratio}'),
                            trailing: Text('\$${fraction.sellingPrice}'),
                            onTap: () => _navigateToSellScreen(fraction),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () => _navigateToSellScreen(),
        icon: const Icon(Icons.shopping_cart),
        label: Text(l10n.sellThisItem),
      ),
    );
  }
}
