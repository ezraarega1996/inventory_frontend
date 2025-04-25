import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/screens/salesman/sell_item_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final Item item;
  
  const ItemDetailScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      'Item Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Name:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(item.name),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Category:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(item.category?.name ?? 'No category'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Fractions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (item.fractions == null || item.fractions!.isEmpty)
              const Center(
                child: Text('No fractions available for this item'),
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
                      subtitle: Text('Ratio: ${fraction.ratio}'),
                      trailing: Text('\$${fraction.price}'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SellItemScreen(
                              preSelectedItem: item,
                              preSelectedFraction: fraction,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SellItemScreen(
                preSelectedItem: item,
              ),
            ),
          );
        },
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Sell This Item'),
      ),
    );
  }
}
