import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/bought.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/user.dart';
import 'package:inventory_frontend/providers/bought_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/providers/user_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';

class BoughtsScreen extends StatefulWidget {
  const BoughtsScreen({Key? key}) : super(key: key);

  @override
  State<BoughtsScreen> createState() => _BoughtsScreenState();
}

class _BoughtsScreenState extends State<BoughtsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fractionNameController = TextEditingController();
  final _fractionPurchasePriceController = TextEditingController();
  final _fractionSoldPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _fractionIdController = TextEditingController();
  DateTime? _expiryDate;
  String? _editingBoughtId;
  String? _selectedItemId;
  String? _selectedFractionId;
  String? _selectedSalesmanId;

  @override
  void initState() {
    super.initState();
    _loadBoughts();
    _loadItems();
    _loadUsers();
  }

  @override
  void dispose() {
    _fractionNameController.dispose();
    _fractionPurchasePriceController.dispose();
    _fractionSoldPriceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _fractionIdController.dispose();
    super.dispose();
  }

  Future<void> _loadBoughts() async {
    final boughtProvider = Provider.of<BoughtProvider>(context, listen: false);
    await boughtProvider.fetchBoughts();
  }

  Future<void> _loadItems() async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    await itemProvider.fetchItems();
  }

  Future<void> _loadUsers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchUsers();
  }

  void _showAddEditDialog({
    String? id,
    String? itemId,
    String? fractionId,
    double? fractionPurchasePrice,
    double? fractionSoldPrice,
    double? quantity,
    String? location,
    DateTime? expiryDate,
    String? salesmanId,
  }) {
    setState(() {
      _editingBoughtId = id;
      _selectedItemId = itemId;
      _selectedFractionId = fractionId;
      _selectedSalesmanId = salesmanId;
      _fractionNameController.text = fractionId ?? '';
      _fractionPurchasePriceController.text = fractionPurchasePrice?.toString() ?? '';
      _fractionSoldPriceController.text = fractionSoldPrice?.toString() ?? '';
      _quantityController.text = quantity?.toString() ?? '';
      _locationController.text = location ?? '';
      _expiryDate = expiryDate;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_editingBoughtId == null ? 'Add Bought Item' : 'Edit Bought Item'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final salesmen = userProvider.users.where((user) => user.role == 'salesman').toList();
                      return DropdownButtonFormField<String>(
                        value: _selectedSalesmanId,
                        decoration: const InputDecoration(
                          labelText: 'Select Salesman',
                          border: OutlineInputBorder(),
                        ),
                        items: salesmen.map((salesman) {
                          return DropdownMenuItem<String>(
                            value: salesman.id,
                            child: Text(salesman.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {                  
                            _selectedSalesmanId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a salesman';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer<ItemProvider>(
                    builder: (context, itemProvider, child) {
                      return DropdownButtonFormField<String>(
                        value: _selectedItemId,
                        decoration: const InputDecoration(
                          labelText: 'Select Item',
                          border: OutlineInputBorder(),
                        ),
                        items: itemProvider.items.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedItemId = value;
                            _selectedFractionId = null;
                            _fractionNameController.clear();
                            _fractionPurchasePriceController.clear();
                            _fractionSoldPriceController.clear();
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an item';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedItemId != null)
                    Consumer<ItemProvider>(
                      builder: (context, itemProvider, child) {
                        final item = itemProvider.items.firstWhere(
                          (item) => item.id == _selectedItemId,
                          orElse: () => Item(
                            id: '',
                            name: '',
                            categoryId: '',
                            fractions: [],
                          ),
                        );
                        
                        if (item.fractions == null || item.fractions!.isEmpty) {
                          return const Text(
                            'No fractions available for this item',
                            style: TextStyle(color: Colors.red),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Fraction',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedFractionId,
                                  hint: const Text('Choose a fraction'),
                                  items: item.fractions?.map((fraction) {
                                    return DropdownMenuItem<String>(
                                      value: fraction.id,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fraction.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Ratio: ${fraction.ratio} | Price: \$${fraction.price}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList() ?? [],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedFractionId = value;
                                      final fraction = item.fractions?.firstWhere((f) => f.id == value);
                                      if (fraction != null) {
                                        _fractionPurchasePriceController.text = fraction.price.toString();
                                        _fractionSoldPriceController.text = fraction.price.toString();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  if (_selectedFractionId == null)
                    const Text(
                      'Please select a fraction to continue',
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fractionPurchasePriceController,
                    labelText: 'Purchase Price',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a purchase price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fractionSoldPriceController,
                    labelText: 'Sold Price',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a sold price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _quantityController,
                    labelText: 'Quantity',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a quantity';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _locationController,
                    labelText: 'Location',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(_expiryDate == null
                        ? 'Select Expiry Date'
                        : 'Expiry Date: ${DateFormat('MMM dd, yyyy').format(_expiryDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _expiryDate = date;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _saveBought,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBought() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFractionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a fraction')),
        );
        return;
      }

      final boughtProvider = Provider.of<BoughtProvider>(context, listen: false);
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      
      final item = itemProvider.items.firstWhere((item) => item.id == _selectedItemId);
      final fraction = item.fractions?.firstWhere((f) => f.id == _selectedFractionId);
      
      if (fraction == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected fraction not found')),
        );
        return;
      }

      bool success;

      if (_editingBoughtId == null) {
        success = await boughtProvider.createBought(
          itemId: _selectedItemId!,
          fractionId: _selectedFractionId!,
          fractionPurchasePrice: double.parse(_fractionPurchasePriceController.text),
          fractionSoldPrice: double.parse(_fractionSoldPriceController.text),
          quantity: double.parse(_quantityController.text),
          location: _locationController.text.trim(),
          expiryDate: _expiryDate,
          salesmanId: _selectedSalesmanId,
        );
      } else {
        success = await boughtProvider.updateBought(
          id: _editingBoughtId!,
          fractionId: _selectedFractionId!,
          fractionPurchasePrice: double.parse(_fractionPurchasePriceController.text),
          fractionSoldPrice: double.parse(_fractionSoldPriceController.text),
          quantity: double.parse(_quantityController.text),
          location: _locationController.text.trim(),
          expiryDate: _expiryDate,
          salesmanId: _selectedSalesmanId,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bought item ${_editingBoughtId == null ? 'added' : 'updated'} successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(boughtProvider.error ?? 'An error occurred'),
          ),
        );
      }
    }
  }

  Future<void> _deleteBought(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bought Item'),
        content: const Text('Are you sure you want to delete this bought item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final boughtProvider = Provider.of<BoughtProvider>(context, listen: false);
      final success = await boughtProvider.deleteBought(id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bought item deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(boughtProvider.error ?? 'An error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boughtProvider = Provider.of<BoughtProvider>(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bought Items'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBoughts,
        child: boughtProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : boughtProvider.boughts.isEmpty
                ? const Center(child: Text('No bought items found'))
                : ListView.builder(
                    itemCount: boughtProvider.boughts.length,
                    itemBuilder: (context, index) {
                      final bought = boughtProvider.boughts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(bought.item?.name ?? 'Unknown Item'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fraction: ${bought.fraction?.name ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text('Quantity: ${bought.quantity}'),
                              Text('Location: ${bought.location}'),
                              Text('Created: ${dateFormat.format(bought.createdTime)}'),
                              if (bought.expiryDate != null)
                                Text('Expiry: ${dateFormat.format(bought.expiryDate!)}'),
                              if (bought.salesman != null)
                                Text('Salesman: ${bought.salesman?.name ?? 'Unknown'}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showAddEditDialog(
                                  id: bought.id,
                                  itemId: bought.itemId,
                                  fractionId: bought.fractionId,
                                  fractionPurchasePrice: bought.fractionPurchasePrice,
                                  fractionSoldPrice: bought.fractionSoldPrice,
                                  quantity: bought.quantity,
                                  location: bought.location,
                                  expiryDate: bought.expiryDate,
                                  salesmanId: bought.salesmanId,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteBought(bought.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
} 