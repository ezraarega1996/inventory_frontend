import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/sold_item.dart';
import 'package:inventory_frontend/widgets/fraction_dropdown.dart';
import 'package:intl/intl.dart';

class AvailableItemDetailScreen extends StatefulWidget {
  final AvailableItem availableItem;

  const AvailableItemDetailScreen({Key? key, required this.availableItem})
    : super(key: key);

  @override
  State<AvailableItemDetailScreen> createState() =>
      _AvailableItemDetailScreenState();
}

class _AvailableItemDetailScreenState extends State<AvailableItemDetailScreen> {
  String? _selectedFractionId;

  @override
  void initState() {
    super.initState();
    if (widget.availableItem.item?.fractions?.isNotEmpty ?? false) {
      _selectedFractionId = widget.availableItem.item!.fractions!.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final item = widget.availableItem.item;
    final salesman = widget.availableItem.salesman;
    final selectedFraction = item?.fractions?.firstWhere(
      (f) => f.id == _selectedFractionId,
      orElse:
          () => Fraction(
            id: '',
            name: '',
            ratio: 1,
            price: 0,
            itemId: item?.id ?? '',
          ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(item?.name ?? 'Item Details')),
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
                      'Item Information',
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
                        Text(item?.name ?? 'Unknown'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Available Quantity:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text('${widget.availableItem.quantity}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Sold Price:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${widget.availableItem.soldPrice.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    if (salesman != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Assigned to:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(salesman.name),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (item?.fractions?.isNotEmpty ?? false) ...[
              const Text(
                'Available Fractions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FractionDropdown(
                fractions: item!.fractions!,
                selectedFractionId: _selectedFractionId ?? '',
                onChanged: (String? value) {
                  setState(() {
                    _selectedFractionId = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Transaction History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.availableItem.soldTransactions?.isEmpty ?? true)
              const Center(child: Text('No transactions found'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.availableItem.soldTransactions?.length ?? 0,
                itemBuilder: (context, index) {
                  final transaction =
                      widget.availableItem.soldTransactions![index];
                  return Card(
                    child: ListTile(
                      title: Text('Quantity: ${transaction.quantity}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${dateFormat.format(transaction.createdAt)}',
                          ),
                          Text(
                            'Price: \$${transaction.soldPrice.toStringAsFixed(2)}',
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
