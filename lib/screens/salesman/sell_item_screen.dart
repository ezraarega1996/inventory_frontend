import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';

class SellItemScreen extends StatefulWidget {
  final Item? preSelectedItem;
  final Fraction? preSelectedFraction;
  
  const SellItemScreen({
    Key? key,
    this.preSelectedItem,
    this.preSelectedFraction,
  }) : super(key: key);

  @override
  State<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  
  Item? _selectedItem;
  Fraction? _selectedFraction;
  double _expectedAmount = 0;
  double _availableQuantity = 0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Set pre-selected values if provided
    _selectedItem = widget.preSelectedItem;
    _selectedFraction = widget.preSelectedFraction;
    
    if (_selectedFraction != null) {
      _updateExpectedAmount();
      _fetchAvailableQuantity();
    }
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final availableItemProvider = Provider.of<AvailableItemProvider>(context, listen: false);
    await Future.wait([
      itemProvider.fetchItems(),
      availableItemProvider.fetchAvailableItems(),
    ]);
  }

  Future<void> _fetchAvailableQuantity() async {
    if (_selectedItem == null || _selectedFraction == null) return;

    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final availableQuantity = await salesProvider.getAvailableQuantity(
      _selectedItem!.id,
      _selectedFraction!.id,
    );

    setState(() {
      _availableQuantity = availableQuantity;
    });
  }

  void _updateExpectedAmount() {
    if (_selectedFraction == null || _quantityController.text.isEmpty) {
      setState(() {
        _expectedAmount = 0;
      });
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    setState(() {
      _expectedAmount = quantity * _selectedFraction!.price;
    });
  }

  Future<void> _sellItem() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedItem == null || _selectedFraction == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an item and fraction')),
        );
        return;
      }

      final quantity = double.parse(_quantityController.text);
      if (quantity > _availableQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Available quantity is $_availableQuantity')),
        );
        return;
      }

      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      final success = await salesProvider.createSale({
        'itemId': _selectedItem!.id,
        'fractionId': _selectedFraction!.id,
        'quantity': quantity,
        'amount': _expectedAmount,
      });
      print("Sale created: $success");
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item sold successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(salesProvider.error ?? 'An error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final availableItemProvider = Provider.of<AvailableItemProvider>(context);

    // Get items assigned to this salesman
    final assignedItems = itemProvider.items.where((item) {
      final availableItems = availableItemProvider.getAvailableItemsForSalesman(authProvider.user!.id);
      return availableItems.any((availableItem) => availableItem.itemId == item.id);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Item>(
                value: _selectedItem,
                decoration: const InputDecoration(
                  labelText: 'Select Item',
                  border: OutlineInputBorder(),
                ),
                items: assignedItems.map((item) {
                  return DropdownMenuItem<Item>(
                    value: item,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedItem = value;
                    _selectedFraction = null;
                    _quantityController.clear();
                    _expectedAmount = 0;
                    _availableQuantity = 0;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an item';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedItem != null)
                DropdownButtonFormField<Fraction>(
                  value: _selectedFraction,
                  decoration: const InputDecoration(
                    labelText: 'Select Fraction',
                    border: OutlineInputBorder(),
                  ),
                  items: _selectedItem!.fractions?.map((fraction) {
                    return DropdownMenuItem<Fraction>(
                      value: fraction,
                      child: Text('${fraction.name} - \$${fraction.price}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFraction = value;
                      _updateExpectedAmount();
                      _fetchAvailableQuantity();
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a fraction';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _quantityController,
                labelText: 'Quantity',
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateExpectedAmount(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity';
                  }
                  final quantity = double.tryParse(value);
                  if (quantity == null) {
                    return 'Please enter a valid number';
                  }
                  if (quantity <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  if (quantity > _availableQuantity) {
                    return 'Available quantity is $_availableQuantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Available Quantity: $_availableQuantity',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Expected Amount: \$${_expectedAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: _sellItem,
                text: 'Sell Item',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
