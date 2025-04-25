import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';

class FractionManagementScreen extends StatefulWidget {
  final Item item;

  const FractionManagementScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<FractionManagementScreen> createState() => _FractionManagementScreenState();
}

class _FractionManagementScreenState extends State<FractionManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ratioController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ratioController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addFraction() async {
    if (!_formKey.currentState!.validate()) return;

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final success = await itemProvider.createFraction(
      widget.item.id,
      _nameController.text,
      double.parse(_ratioController.text),
      double.parse(_priceController.text),
    );

    if (success) {
      _nameController.clear();
      _ratioController.clear();
      _priceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fraction added successfully')),
      );
    }
  }

  Future<void> _updateFraction(Fraction fraction) async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final success = await itemProvider.updateFraction(
      fraction.id,
      _nameController.text,
      double.parse(_ratioController.text),
      double.parse(_priceController.text),
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fraction updated successfully')),
      );
    }
  }

  Future<void> _deleteFraction(Fraction fraction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fraction'),
        content: const Text('Are you sure you want to delete this fraction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final success = await itemProvider.deleteFraction(fraction.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fraction deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Fractions - ${widget.item.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Fraction Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _ratioController,
                    labelText: 'Ratio',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a ratio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _priceController,
                    labelText: 'Price',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    onPressed: _addFraction,
                    text: 'Add Fraction',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Existing Fractions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ItemProvider>(
                builder: (context, itemProvider, child) {
                  final item = itemProvider.items
                      .firstWhere((i) => i.id == widget.item.id);
                  final fractions = item.fractions ?? [];

                  if (fractions.isEmpty) {
                    return const Center(
                      child: Text('No fractions added yet'),
                    );
                  }

                  return ListView.builder(
                    itemCount: fractions.length,
                    itemBuilder: (context, index) {
                      final fraction = fractions[index];
                      return Card(
                        child: ListTile(
                          title: Text(fraction.name),
                          subtitle: Text(
                            'Ratio: ${fraction.ratio}, Price: \$${fraction.price}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _nameController.text = fraction.name;
                                  _ratioController.text = fraction.ratio.toString();
                                  _priceController.text = fraction.price.toString();
                                  _updateFraction(fraction);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteFraction(fraction),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 