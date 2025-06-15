import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/bought.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/providers/bought_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/providers/user_provider.dart';
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
  final Map<String, String> _selectedFractionIds = {}; // boughtId -> fractionId
  DateTime? _expiryDate;
  String? _editingBoughtId;
  String? _selectedItemId;
  String? _selectedFractionId;
  String? _selectedSalesmanId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
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

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    await Future.wait([
      context.read<BoughtProvider>().fetchBoughts(),
      context.read<ItemProvider>().fetchItems(),
      context.read<UserProvider>().fetchUsers(),
    ]);
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadBoughts() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    await context.read<BoughtProvider>().fetchBoughts();
    if (mounted) {
      setState(() { _isLoading = false; });
    }
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
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                        onChanged: _isSubmitting ? null : (value) {
                          setDialogState(() { _selectedSalesmanId = value; });
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
                        onChanged: _isSubmitting ? null : (value) {
                          setDialogState(() {
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
                          orElse: () => Item(id: '', name: '', categoryId: '', fractions: []),
                        );
                        if (item.fractions == null || item.fractions!.isEmpty) {
                          return const Text('No fractions available for this item', style: TextStyle(color: Colors.red));
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Select Fraction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                          Text(fraction.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Ratio: ${fraction.ratio} | Price: \$${fraction.price}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    );
                                  }).toList() ?? [],
                                  onChanged: _isSubmitting ? null : (value) {
                                    setDialogState(() {
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
                    const Text('Please select a fraction to continue', style: TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fractionPurchasePriceController,
                    labelText: 'Purchase Price',
                    keyboardType: TextInputType.number,
                    enabled: !_isSubmitting,
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
                    enabled: !_isSubmitting,
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
                    enabled: !_isSubmitting,
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
                    enabled: !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(_expiryDate == null ? 'Select Expiry Date' : 'Expiry Date: ${DateFormat('MMM dd, yyyy').format(_expiryDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    enabled: !_isSubmitting,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() { _expiryDate = date; });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () {
                setState(() { _isSubmitting = false; });
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isSubmitting ? null : () async {
                if (!_formKey.currentState!.validate()) return;
                if (_selectedFractionId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a fraction')));
                  return;
                }
                
                setState(() { _isSubmitting = true; });
                setDialogState(() {});
                
                try {
                  final boughtProvider = context.read<BoughtProvider>();
                  final itemProvider = context.read<ItemProvider>();
                  final item = itemProvider.items.firstWhere((item) => item.id == _selectedItemId);
                  final fraction = item.fractions?.firstWhere((f) => f.id == _selectedFractionId);
                  if (fraction == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected fraction not found')));
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
                      SnackBar(content: Text('Bought item ${_editingBoughtId == null ? 'added' : 'updated'} successfully'))
                    );
                    await _loadBoughts();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(boughtProvider.error ?? 'An error occurred'))
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() { _isSubmitting = false; });
                  }
                }
              },
              child: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Reset state when dialog is closed
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    });
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
      final boughtProvider = context.read<BoughtProvider>();
      final success = await boughtProvider.deleteBought(id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bought item deleted successfully')));
        await _loadBoughts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(boughtProvider.error ?? 'An error occurred')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bought Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBoughts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<BoughtProvider>(
              builder: (context, boughtProvider, child) {
                if (boughtProvider.boughts.isEmpty) {
                  return const Center(child: Text('No bought items found'));
                }
                return RefreshIndicator(
                  onRefresh: _loadBoughts,
                  child: ListView.builder(
                    itemCount: boughtProvider.boughts.length,
                    itemBuilder: (context, index) {
                      final bought = boughtProvider.boughts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            String selectedFractionId = _selectedFractionIds[bought.id] ?? bought.fraction?.id ?? '';
                            Fraction? selectedFraction = bought.item?.fractions?.firstWhere((f) => f.id == selectedFractionId);
                            Bought? fractionBought = boughtProvider.boughts.firstWhere(
                              (b) => b.itemId == bought.itemId && b.fractionId == selectedFractionId,
                              orElse: () => bought,
                            );
                            return ListTile(
                              title: Text(bought.item?.name ?? 'Unknown Item'),
                              subtitle: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('salesman: ${bought.salesman?.name ?? 'Unknown Salesman'}'),
                                                  Text('Quantity: ${bought.quantity * bought.fraction!.ratio / selectedFraction!.ratio} ${selectedFraction?.name ?? ""}'),
                                                  Text('Available items: ${bought.available_items_count! * bought.fraction!.ratio / selectedFraction.ratio} ${selectedFraction.name ?? ""}'),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Location: ${bought.location}'),
                                                  Text('Created: ${dateFormat.format(bought.createdTime)}'),
                                                  if (bought.expiryDate != null)
                                                    Text('Expiry: ${dateFormat.format(bought.expiryDate!)}'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showAddEditDialog(
                                                  id: fractionBought.id,
                                                  itemId: fractionBought.itemId,
                                                  fractionId: fractionBought.fractionId,
                                                  fractionPurchasePrice: fractionBought.fractionPurchasePrice,
                                                  fractionSoldPrice: fractionBought.fractionSoldPrice,
                                                  quantity: fractionBought.quantity,
                                                  location: fractionBought.location,
                                                  expiryDate: fractionBought.expiryDate,
                                                  salesmanId: fractionBought.salesmanId,
                                                );
                                              } else if (value == 'delete') {
                                                _deleteBought(fractionBought.id);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: ListTile(
                                                  leading: Icon(Icons.edit, color: Colors.blue),
                                                  title: Text('Edit', style: TextStyle(color: Colors.blue)),
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: ListTile(
                                                  leading: Icon(Icons.delete, color: Colors.red),
                                                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if ((bought.item?.fractions ?? []).isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.swap_horiz, size: 18, color: Colors.blueGrey),
                                                    DropdownButtonHideUnderline(
                                                      child: DropdownButton<String>(
                                                        value: selectedFractionId,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                                        items: bought.item!.fractions!.map((fraction) {
                                                          return DropdownMenuItem<String>(
                                                            value: fraction.id,
                                                            child: Row(
                                                              children: [
                                                                Text(fraction.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                                const SizedBox(width: 8),
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _selectedFractionIds[bought.id] = value!;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
