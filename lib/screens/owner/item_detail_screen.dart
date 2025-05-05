import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/screens/owner/fraction_management_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  
  const ItemDetailScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  @override
  Widget build(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'fractions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FractionManagementScreen(item: item),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Manage Fractions'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (item.fractions == null || item.fractions!.isEmpty)
              const Center(
                child: Text('No fractions added yet'),
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
                      subtitle: Text('Ratio: ${fraction.ratio}, Price: \$${fraction.price}'),
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
