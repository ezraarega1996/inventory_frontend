import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
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
  final _amountController = TextEditingController();
  
  Item? _selectedItem;
  Fraction? _selectedFraction;
  double _expectedAmount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadItems();
    
    // Set pre-selected values if provided
    _selectedItem = widget.preSelectedItem;
    _selectedFraction = widget.preSelectedFraction;
    
    if (_selectedFraction != null) {
      _updateExpectedAmount();
    }
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  
  Future<void> _loadItems() async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    await itemProvider.fetchItems();
  }
  
  void _updateExpectedAmount() {
    if (_selectedFraction != null && _quantityController.text.isNotEmpty) {
      try {
        final quantity = double.parse(_quantityController.text);
        setState(() {
          _expectedAmount = _selectedFraction!.price * quantity;
          _amountController.text = _expectedAmount.toString();
        });
      } catch (e) {
        setState(() {
          _expectedAmount = 0;
        });
      }
    } else {
      setState(() {
        _expectedAmount = 0;
      });
    }
  }
  
  Future<void> _sellItem() async {
    if (_formKey.currentState!.validate()) {
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      
      final saleData = {
        'itemId': _selectedItem!.id,
        'quantity': double.parse(_quantityController.text),
        'fractionName': _selectedFraction!.name,
        'amount': double.parse(_amountController.text),
        'expectedAmount': _expectedAmount,
      };
      
      final success = await salesProvider.createSale(saleData);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale completed successfully'))
        );
        
        // Reset form
        _quantityController.clear();
        _amountController.clear();
        setState(() {
          if (widget.preSelectedItem == null) {
            _selectedItem = null;
          }
          if (widget.preSelectedFraction == null) {
            _selectedFraction = null;
          }
          _expectedAmount = 0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(salesProvider.error ?? 'An error occurred'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.preSelectedItem == null)
                DropdownButtonFormField<Item>(
                  value: _selectedItem,
                  decoration: const InputDecoration(
                    labelText: 'Select Item',
                    border: OutlineInputBorder(),
                  ),
                  items: itemProvider.items.map((item) {
                    return DropdownMenuItem<Item>(
                      value: item,
                      child: Text(item.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItem = value;
                      _selectedFraction = null;
                      _expectedAmount = 0;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an item';
                    }
                    return null;
                  },
                ),
              if (widget.preSelectedItem == null)
                const SizedBox(height: 16),
              if (_selectedItem != null)
                DropdownButtonFormField<Fraction>(
                  value: _selectedFraction,
                  decoration: const InputDecoration(
                    labelText: 'Select Fraction',
                    border: OutlineInputBorder(),
                  ),
                  items: (_selectedItem?.fractions ?? []).map((fraction) {
                    return DropdownMenuItem<Fraction>(
                      value: fraction,
                      child: Text('${fraction.name} - \$${fraction.price}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFraction = value;
                      _updateExpectedAmount();
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a fraction';
                    }
                    return null;
                  },
                ),
              if (_selectedItem != null)
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
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                labelText: 'Amount Received',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_expectedAmount > 0)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expected Amount:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${_expectedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Complete Sale',
                isLoading: salesProvider.isLoading,
                onPressed: _sellItem,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
