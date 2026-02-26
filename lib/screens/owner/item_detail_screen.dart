import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/fraction_management_dialog.dart';
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemProvider = Provider.of<ItemProvider>(context);
    final item = itemProvider.items.firstWhere((i) => i.id == widget.item.id);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
      ),
      body: SingleChildScrollView(
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
                          l10n.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(item.name),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          l10n.category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(item.category?.name ?? l10n.noCategory),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.units,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => FractionManagementDialog(item: item),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.manageUnits),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (item.fractions == null || item.fractions!.isEmpty)
              Center(
                child: Text(l10n.noUnitsAddedYet),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: item.fractions!.length,
                itemBuilder: (context, index) {
                  final fraction = item.fractions![index];
                  return Card(
                    child: ListTile(
                      title: Text(fraction.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.ratioAndPrice(fraction.ratio, fraction.sellingPrice)),
                          const SizedBox(height: 4),
                          Text('${l10n.soldPriceLabel}: \$${fraction.sellingPrice.toStringAsFixed(2)}'),
                          Text('${l10n.purchasePrice}: \$${fraction.purchasePrice.toStringAsFixed(2)}'),
                          Text(
                            '${l10n.profitMargin}: ${fraction.sellingPrice == 0 ? 0 : ((fraction.sellingPrice - fraction.purchasePrice) / fraction.sellingPrice * 100).toStringAsFixed(2)}%',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
