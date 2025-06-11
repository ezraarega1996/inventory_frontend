import 'package:flutter/material.dart';
import 'package:inventory_frontend/screens/salesman/salesman_dashboard.dart';
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
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;

  // Memoized providers
  late final ItemProvider _itemProvider;
  late final AvailableItemProvider _availableItemProvider;
  late final SalesProvider _salesProvider;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
    _setupPreSelectedValues();
    _loadData();
  }

  void _initializeProviders() {
    _itemProvider = Provider.of<ItemProvider>(context, listen: false);
    _availableItemProvider = Provider.of<AvailableItemProvider>(context, listen: false);
    _salesProvider = Provider.of<SalesProvider>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  void _setupPreSelectedValues() {
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
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _itemProvider.fetchItems(),
        _availableItemProvider.fetchAvailableItems(),
      ], eagerError: true);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _error = 'Failed to load data. Please try again.';
      });
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _fetchAvailableQuantity() async {
    if (_selectedItem == null || _selectedFraction == null) return;

    try {
      final availableQuantity = await _salesProvider.getAvailableQuantity(
        _selectedItem!.id,
        _selectedFraction!.id,
      );

      if (!mounted) return;

      setState(() {
        _availableQuantity = double.parse(availableQuantity.toStringAsFixed(2));
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = 'Failed to fetch available quantity. Please try again.';
      });
      debugPrint('Error fetching available quantity: $e');
    }
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItem == null || _selectedFraction == null) {
      _showErrorSnackBar('Please select an item and fraction');
      return;
    }

    final quantity = double.parse(_quantityController.text);
    if (quantity > _availableQuantity) {
      _showErrorSnackBar('Available quantity is $_availableQuantity');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _salesProvider.createSale({
        'itemId': _selectedItem!.id,
        'fractionId': _selectedFraction!.id,
        'quantity': quantity,
        'amount': _expectedAmount,
      });

      if (!mounted) return;

      if (success) {
        _showSuccessSnackBar('Item sold successfully');
        _resetForm();
      } else {
        _showErrorSnackBar(_salesProvider.error ?? 'An error occurred');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to process sale. Please try again.');
      debugPrint('Error processing sale: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _quantityController.clear();
      _expectedAmount = 0;
      _availableQuantity = 0;
      _selectedItem = null;
      _selectedFraction = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<Item> _getAssignedItems() {
    final availableItems = _availableItemProvider.getAvailableItemsForSalesman(_authProvider.user!.id);
    return _itemProvider.items.where((item) {
      return availableItems.any((availableItem) => availableItem.itemId == item.id);
    }).toList();
  }

  void _handleItemChange(Item? value) {
    setState(() {
      _selectedItem = value;
      _selectedFraction = null;
      _quantityController.clear();
      _expectedAmount = 0;
      _availableQuantity = 0;
    });
  }

  void _handleFractionChange(Fraction? value) {
    setState(() {
      _selectedFraction = value;
      _updateExpectedAmount();
      _fetchAvailableQuantity();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final assignedItems = _getAssignedItems();

    if (assignedItems.isEmpty) {
      return const Center(
        child: Text(
          'No items assigned to you',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

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
                onChanged: _handleItemChange,
                validator: (value) => value == null ? 'Please select an item' : null,
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
                  onChanged: _handleFractionChange,
                  validator: (value) => value == null ? 'Please select a fraction' : null,
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
                onPressed: _isSubmitting ? () {} : _sellItem,
                text: _isSubmitting ? 'Processing...' : 'Sell Item',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
