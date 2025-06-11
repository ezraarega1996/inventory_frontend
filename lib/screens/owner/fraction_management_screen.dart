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
  bool _isUnit = false;
  bool _hasUnitFraction = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUnitFraction();
  }

  void _checkUnitFraction() {
    final itemProvider = context.read<ItemProvider>();
    final item = itemProvider.items.firstWhere((i) => i.id == widget.item.id);
    _hasUnitFraction = item.fractions?.any((f) => f.isUnit) ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ratioController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addFraction() async {
    if (!_formKey.currentState!.validate()) return;

    final itemProvider = context.read<ItemProvider>();
    try {
      final success = await itemProvider.createFraction(
        widget.item.id,
        _nameController.text,
        double.parse(_ratioController.text),
        double.parse(_priceController.text),
        isUnit: _isUnit,
      );

      if (success) {
        _nameController.clear();
        _ratioController.clear();
        _priceController.clear();
        setState(() => _isUnit = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fraction added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateFraction(Fraction fraction) async {
    final itemProvider = context.read<ItemProvider>();
    try {
      final success = await itemProvider.updateFraction(
        fraction.id,
        _nameController.text,
        double.parse(_ratioController.text),
        double.parse(_priceController.text),
        isUnit: _isUnit,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unit updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFraction(Fraction fraction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete unit'),
        content: const Text('Are you sure you want to delete this unit?'),
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
      final itemProvider = context.read<ItemProvider>();
      final success = await itemProvider.deleteFraction(fraction.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unit deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Units - ${widget.item.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkUnitFraction,
          ),
        ],
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
                    labelText: 'Unit Name',
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
                  const SizedBox(height: 16),
                  CustomButton(
                    onPressed: _addFraction,
                    text: 'Add Unit',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Existing Units',
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
                      child: Text('No units added yet'),
                    );
                  }

                  return ListView.builder(
                    itemCount: fractions.length,
                    itemBuilder: (context, index) {
                      final fraction = fractions[index];
                      return Card(
                        child: ListTile(
                          title: Text(fraction.name),
                          subtitle: Text('Ratio: ${fraction.ratio}, Price: \$${fraction.price}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _nameController.text = fraction.name;
                                  _ratioController.text = fraction.ratio.toString();
                                  _priceController.text = fraction.price.toString();
                                  _isUnit = fraction.isUnit;
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