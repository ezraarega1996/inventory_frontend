import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/bought.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/providers/bought_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/providers/shop_provider.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:inventory_frontend/widgets/fraction_dropdown.dart';

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
  final _fractionIdController = TextEditingController();
  final Map<String, String> _selectedFractionIds = {}; // boughtId -> fractionId
  DateTime? _expiryDate;
  String? _editingBoughtId;
  String? _selectedItemId;
  String? _selectedFractionId;
  String? _selectedShopId;
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
    _fractionIdController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    await Future.wait([
      context.read<BoughtProvider>().fetchBoughts(),
      context.read<ItemProvider>().fetchItems(),
      context.read<ShopProvider>().getShops(),
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
    DateTime? expiryDate,
    String? shopId,
  }) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _editingBoughtId = id;
      _selectedItemId = itemId;
      _selectedFractionId = fractionId;
      _selectedShopId = shopId;
      _fractionNameController.text = fractionId ?? '';
      _fractionPurchasePriceController.text = fractionPurchasePrice?.toString() ?? '';
      _fractionSoldPriceController.text = fractionSoldPrice?.toString() ?? '';
      _quantityController.text = quantity?.toString() ?? '';
      _expiryDate = expiryDate;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_editingBoughtId == null ? l10n.addBoughtItem : l10n.editBoughtItem),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<ShopProvider>(
                    builder: (context, shopProvider, child) {
                      final shops = shopProvider.shops.where((shop) => shop.isActive).toList();
                      return DropdownButtonFormField<String>(
                        value: _selectedShopId,
                        decoration: InputDecoration(
                          labelText: l10n.selectShop,
                          border: const OutlineInputBorder(),
                        ),
                        items: shops.map((shop) {
                          return DropdownMenuItem<String>(
                            value: shop.id,
                            child: Text(shop.name),
                          );
                        }).toList(),
                        onChanged: _isSubmitting ? null : (value) {
                          setDialogState(() { _selectedShopId = value; });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.required;
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
                        decoration: InputDecoration(
                          labelText: l10n.selectItem,
                          border: const OutlineInputBorder(),
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
                            return l10n.required;
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
                          return Text(l10n.noFractionsAvailable, style: const TextStyle(color: Colors.red));
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.selectFraction, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  hint: Text(l10n.chooseFraction),
                                  items: item.fractions?.map((fraction) {
                                    return DropdownMenuItem<String>(
                                      value: fraction.id,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(fraction.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text('${l10n.ratio}: ${fraction.ratio} | ${l10n.soldPriceLabel}: ₹${fraction.sellingPrice}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    );
                                  }).toList() ?? [],
                                  onChanged: _isSubmitting ? null : (value) {
                                    setDialogState(() {
                                      _selectedFractionId = value;
                                      final fraction = item.fractions?.firstWhere((f) => f.id == value);
                                      if (fraction != null) {
                                        _fractionPurchasePriceController.text = fraction.purchasePrice.toString();
                                        _fractionSoldPriceController.text = fraction.sellingPrice.toString();
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
                    Text(l10n.selectFractionToContinue, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fractionPurchasePriceController,
                    labelText: l10n.purchasePrice,
                    keyboardType: TextInputType.number,
                    enabled: !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
                      }
                      if (double.tryParse(value) == null) {
                        return l10n.invalidNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fractionSoldPriceController,
                    labelText: l10n.soldPriceLabel,
                    keyboardType: TextInputType.number,
                    enabled: !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
                      }
                      if (double.tryParse(value) == null) {
                        return l10n.invalidNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _quantityController,
                    labelText: l10n.quantityLabel,
                    keyboardType: TextInputType.number,
                    enabled: !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
                      }
                      if (double.tryParse(value) == null) {
                        return l10n.invalidNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(_expiryDate == null ? l10n.selectExpiryDate : '${l10n.expiryDate}: ${DateFormat('MMM dd, yyyy').format(_expiryDate!)}'),
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
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: _isSubmitting ? null : () async {
                if (!_formKey.currentState!.validate()) return;
                if (_selectedFractionId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectFractionToContinue)));
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noFractionsAvailable)));
                    return;
                  }

                  // Parse new prices from the form
                  final newPurchasePrice = double.parse(_fractionPurchasePriceController.text);
                  final newSellingPrice = double.parse(_fractionSoldPriceController.text);

                  // If prices have changed, update them in the fractions table first
                  bool fractionUpdateSuccess = true;
                  if (fraction.purchasePrice != newPurchasePrice || fraction.sellingPrice != newSellingPrice) {
                    fractionUpdateSuccess = await itemProvider.updateFraction(
                      fraction.id,
                      fraction.name,
                      fraction.ratio,
                      newSellingPrice,
                      newPurchasePrice,
                      isUnit: fraction.isUnit,
                    );
                  }

                  if (!fractionUpdateSuccess) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(itemProvider.error ?? l10n.error)),
                    );
                    return;
                  }

                  bool success;
                  if (_editingBoughtId == null) {
                    success = await boughtProvider.createBought(
                      itemId: _selectedItemId!,
                      fractionId: _selectedFractionId!,
                      fractionPurchasePrice: newPurchasePrice,
                      fractionSoldPrice: newSellingPrice,
                      quantity: double.parse(_quantityController.text),
                      expiryDate: _expiryDate,
                      shopId: _selectedShopId,
                    );
                  } else {
                    success = await boughtProvider.updateBought(
                      id: _editingBoughtId!,
                      fractionId: _selectedFractionId!,
                      fractionPurchasePrice: newPurchasePrice,
                      fractionSoldPrice: newSellingPrice,
                      quantity: double.parse(_quantityController.text),
                      expiryDate: _expiryDate,
                      shopId: _selectedShopId,
                    );
                  }
                  
                  if (!mounted) return;
                  
                  Navigator.of(context).pop();
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.success))
                    );
                    await _loadBoughts();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(boughtProvider.error ?? l10n.error))
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
                : Text(l10n.save),
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBoughtItem),
        content: Text(l10n.confirmDeleteBought),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final boughtProvider = context.read<BoughtProvider>();
      final success = await boughtProvider.deleteBought(id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.success)));
        await _loadBoughts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(boughtProvider.error ?? l10n.error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.boughtItems),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBoughts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<BoughtProvider, ItemProvider>(
              builder: (context, boughtProvider, itemProvider, child) {
                if (boughtProvider.boughts.isEmpty) {
                  return Center(child: Text(l10n.noBoughtItems));
                }
                return RefreshIndicator(
                  onRefresh: _loadBoughts,
                  child: ListView.builder(
                    itemCount: boughtProvider.boughts.length,
                    itemBuilder: (context, index) {
                      final bought = boughtProvider.boughts[index];
                      final item = bought.item ?? itemProvider.items.firstWhere(
                        (i) => i.id == bought.itemId,
                        orElse: () => Item(id: '', name: '', categoryId: '', fractions: []),
                      );
                      final itemFractions = item.fractions ?? [];
                      // Default to bought's fractionId if not set
                      final selectedFractionId = _selectedFractionIds[bought.id] ?? (itemFractions.isNotEmpty ? bought.fractionId : '');
                      final boughtFraction = itemFractions.firstWhere(
                        (f) => f.id == bought.fractionId,
                        orElse: () => itemFractions.isNotEmpty
                            ? itemFractions.first
                            : Fraction(id: '', name: '', ratio: 1, sellingPrice: 0, purchasePrice: 0, itemId: ''),
                      );
                      final selectedFraction = itemFractions.firstWhere(
                        (f) => f.id == selectedFractionId,
                        orElse: () => itemFractions.isNotEmpty
                            ? itemFractions.first
                            : Fraction(id: '', name: '', ratio: 1, sellingPrice: 0, purchasePrice: 0, itemId: ''),
                      );
                      double? displayedQuantity = bought.quantity;
                      double? displayedAvailableCount = bought.available_items_count;
                      if (boughtFraction != null && selectedFraction != null) {
                        displayedQuantity = bought.quantity * boughtFraction.ratio / selectedFraction.ratio;
                        if (bought.available_items_count != null) {
                          displayedAvailableCount = bought.available_items_count! * boughtFraction.ratio / selectedFraction.ratio;
                        }
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(bought.item?.name ?? l10n.unknownItem),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${l10n.shop}: ${bought.shop?.name ?? l10n.unknownShop}'),
                              //Text("${l10n.quantity}: $displayedQuantity ${selectedFraction.name}"),
                              Text(l10n.quantity((displayedQuantity ?? 0), selectedFraction?.name ?? '')),
                              Text(l10n.availableQuantity(displayedAvailableCount ?? 0, selectedFraction?.name ?? '')),
                              if (bought.expiryDate != null)
                                Text('${l10n.expiry}: ${DateFormat('yyyy-MM-dd').format(bought.expiryDate!)}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (itemFractions.isNotEmpty)
                                FractionDropdown(
                                  fractions: itemFractions,
                                  selectedFractionId: selectedFractionId,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedFractionIds[bought.id] = value;
                                    });
                                  },
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showAddEditDialog(
                                  id: bought.id,
                                  itemId: bought.itemId,
                                  fractionId: bought.fractionId,
                                  fractionPurchasePrice: bought.fractionPurchasePrice,
                                  fractionSoldPrice: bought.fractionSoldPrice,
                                  quantity: bought.quantity,
                                  expiryDate: bought.expiryDate,
                                  shopId: bought.shopId,
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
