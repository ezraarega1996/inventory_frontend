import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SellItemScreen extends StatefulWidget {

  final AvailableItem? preSelectedAvailableItem;
  final Fraction? preSelectedAvailableFraction;
  
  const SellItemScreen({
    Key? key,
    this.preSelectedAvailableItem,
    this.preSelectedAvailableFraction,
  }) : super(key: key);

  @override
  State<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  
  AvailableItem? _selectedAvailableItem;
  Fraction? _selectedFraction;
  double _expectedAmount = 0;
  double _profit = 0;
  double _availableQuantity = 0;
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;

  // Memoized providers
  late final AvailableItemProvider _availableItemProvider;
  late final SalesProvider _salesProvider;
  late final ItemProvider _itemProvider;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
    _loadData();
  }

  void _initializeProviders() {
    _availableItemProvider = Provider.of<AvailableItemProvider>(context, listen: false);
    _salesProvider = Provider.of<SalesProvider>(context, listen: false);
    _itemProvider = Provider.of<ItemProvider>(context, listen: false);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _availableItemProvider.fetchAvailableItems(),
      ], eagerError: true);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // Setup pre-selected values after data is loaded
      _setupPreSelectedValues();
      // Debug: print assigned items
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load data. Please try again.';
      });
      debugPrint('Error loading data: $e');
    }
  }

  void _setupPreSelectedValues() {
    // Priority: preSelectedAvailableItem and preSelectedAvailableFraction
    if (widget.preSelectedAvailableItem != null) {
      final assignedItems = _getAssignedItems();
      try {
        final matching = assignedItems.firstWhere(
          (item) => item.id == widget.preSelectedAvailableItem!.id,
        );
        _selectedAvailableItem = matching;
      } catch (e) {
        // No match found, leave as null
      }
    }

    if (_selectedAvailableItem != null) {
      if (widget.preSelectedAvailableFraction != null) {
        final fractions = _selectedAvailableItem!.item?.fractions ?? [];
        try {
          final matchingFraction = fractions.firstWhere(
            (f) => f.id == widget.preSelectedAvailableFraction!.id,
          );
          _selectedFraction = matchingFraction;
          _updatePriceFields(matchingFraction);
          _updateExpectedAmount();
          _fetchAvailableQuantity();
        } catch (e) {
          // No match found, leave as null
        }
      }
    }
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchAvailableQuantity() async {
    if (_selectedAvailableItem == null || _selectedFraction == null) return;

    try {
      final availableQuantity = _selectedAvailableItem!.quantity / _selectedFraction!.ratio;
      if (!mounted) return;

      setState(() {
        _availableQuantity = double.parse(availableQuantity.toStringAsFixed(2));
      });
      print("available quantity: $availableQuantity");      
      print("available quantity state: $_availableQuantity");      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to fetch available quantity. Please try again.';
        _availableQuantity = 0;
      });
      debugPrint('Error fetching available quantity: $e');
    }
  }

  void _updateExpectedAmount() {
    if (_selectedFraction == null || _quantityController.text.isEmpty) {
      setState(() {
        _expectedAmount = 0;
        _profit = 0;
      });
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? _selectedFraction!.sellingPrice;
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? _selectedFraction!.purchasePrice;

    setState(() {
      _expectedAmount = quantity * sellingPrice;
      _profit = (sellingPrice - purchasePrice) * quantity;
    });
  }

  Future<void> _sellItem() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAvailableItem == null || _selectedFraction == null) {
      _showErrorSnackBar(l10n.pleaseSelectItemAndFraction);
      return;
    }

    final quantity = double.parse(_quantityController.text);
    final sellingPrice = double.tryParse(_sellingPriceController.text);
    final purchasePrice = double.tryParse(_purchasePriceController.text);

    if (sellingPrice == null || purchasePrice == null) {
      _showErrorSnackBar(l10n.pleaseEnterValidNumber);
      return;
    }

    if (quantity > _availableQuantity) {
      _showErrorSnackBar(l10n.availableQuantityIs(_availableQuantity));
      return;
    }

    setState(() { _isSubmitting = true; });
    try {
      await _maybeUpdateFractionPrices(
        sellingPrice,
        purchasePrice,
      );

      final success = await _salesProvider.createSale({
        'itemId': _selectedAvailableItem!.item!.id,
        'shopId': _selectedAvailableItem!.shopId,
        'fractionId': _selectedFraction!.id,
        'quantity': quantity,
        'amount': _expectedAmount,
        'profit': _profit,
      });

      if (!mounted) return;

      if (success) {
        _showSuccessSnackBar(l10n.itemSoldSuccessfully);
        _resetForm();
        await Provider.of<AvailableItemProvider>(context, listen: false).fetchAvailableItems();
      } else {
        _showErrorSnackBar(_salesProvider.error ?? l10n.failedToProcessSale);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(l10n.failedToProcessSale);
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
      _selectedAvailableItem = null;
      _selectedFraction = null;
    });
    _updatePriceFields(null);
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

  List<AvailableItem> _getAssignedItems() {
    return _availableItemProvider.availableItems;
  }

  void _handleItemChange(AvailableItem? value) {
    setState(() {
      _selectedAvailableItem = value;
      _selectedFraction = null;
      _quantityController.clear();
      _expectedAmount = 0;
      _availableQuantity = 0;
    });
    _updatePriceFields(null);
  }

  void _updatePriceFields(Fraction? fraction) {
    if (fraction == null) {
      _sellingPriceController.clear();
      _purchasePriceController.clear();
      return;
    }
    _sellingPriceController.text = fraction.sellingPrice.toStringAsFixed(2);
    _purchasePriceController.text = fraction.purchasePrice.toStringAsFixed(2);
    _updateExpectedAmount();
  }

  Future<void> _maybeUpdateFractionPrices(double newSellingPrice, double newPurchasePrice) async {
    final fraction = _selectedFraction;
    if (fraction == null) return;

    final sellingChanged = (newSellingPrice - fraction.sellingPrice).abs() > 0.0001;
    final purchaseChanged = (newPurchasePrice - fraction.purchasePrice).abs() > 0.0001;

    if (!sellingChanged && !purchaseChanged) return;

    final updated = await _itemProvider.updateFraction(
      fraction.id,
      fraction.name,
      fraction.ratio,
      newSellingPrice,
      newPurchasePrice,
      isUnit: fraction.isUnit,
    );

    if (!updated) {
      throw Exception('Failed to update fraction prices');
    }

    setState(() {
      _selectedFraction = Fraction(
        id: fraction.id,
        name: fraction.name,
        ratio: fraction.ratio,
        sellingPrice: newSellingPrice,
        purchasePrice: newPurchasePrice,
        itemId: fraction.itemId,
        isUnit: fraction.isUnit,
      );
    });
  }

  void _handleFractionChange(Fraction? value) {
    if (value == null) {
      setState(() {
        _selectedFraction = null;
        _expectedAmount = 0;
        _availableQuantity = 0;
      });
      _updatePriceFields(null);
      return;
    }

    setState(() {
      _selectedFraction = value;
      _expectedAmount = 0;
      _availableQuantity = 0;
    });
    _updatePriceFields(value);

    // Use Future.microtask to ensure the state update is complete before fetching
    Future.microtask(() async {
      try {
        await _fetchAvailableQuantity();
        if (mounted) {
          _updateExpectedAmount();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to update available quantity';
          });
        }
        debugPrint('Error in fraction change: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
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
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final availableItems = _availableItemProvider.availableItems;
    final assignedItems = availableItems;

    if (assignedItems.isEmpty) {
      return Center(
        child: Text(
          l10n.noItemsAssignedToYou,
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    final availableQuantity = _availableQuantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sellItem),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<AvailableItem>(
                value: _selectedAvailableItem,
                decoration: InputDecoration(
                  labelText: l10n.selectItem,
                  border: const OutlineInputBorder(),
                ),
                items: assignedItems.map((availableItem) {
                  return DropdownMenuItem<AvailableItem>(
                    value: availableItem,
                    child: Text(availableItem.item!.name),
                  );
                }).toList(),
                onChanged: _isSubmitting ? null : _handleItemChange,
                validator: (value) => value == null ? l10n.pleaseSelectItem : null,
              ),
              const SizedBox(height: 16),
              if (_selectedAvailableItem != null)
                DropdownButtonFormField<Fraction>(
                  value: _selectedFraction,
                  decoration: InputDecoration(
                    labelText: l10n.selectUnit,
                    border: const OutlineInputBorder(),
                  ),
                  items: _selectedAvailableItem!.item!.fractions?.map((fraction) {
                    return DropdownMenuItem<Fraction>(
                      value: fraction,
                      child: Text('${fraction.name} - \$${fraction.sellingPrice}'),
                    );
                  }).toList(),
                  onChanged: _isSubmitting ? null : _handleFractionChange,
                  validator: (value) => value == null ? l10n.pleaseSelectUnit : null,
                ),
              if (_selectedFraction != null) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _sellingPriceController,
                  labelText: l10n.soldPriceLabel,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !_isSubmitting,
                  onChanged: (_) => _updateExpectedAmount(),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _purchasePriceController,
                  labelText: l10n.purchasePrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !_isSubmitting,
                ),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                controller: _quantityController,
                labelText: l10n.quantityLabel,
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateExpectedAmount(),
                enabled: !_isSubmitting,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterQuantity;
                  }
                  final quantity = double.tryParse(value);
                  if (quantity == null) {
                    return l10n.pleaseEnterValidNumber;
                  }
                  if (quantity <= 0) {
                    return l10n.quantityMustBeGreaterThanZero;
                  }
                  if (quantity > availableQuantity) {
                    return l10n.availableQuantityIs(availableQuantity);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.availableQuantityWithLoading(availableQuantity.toString()),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.expectedAmountWithCurrency(_expectedAmount.toStringAsFixed(2)),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedFraction != null)
                Text(
                  'Profit: ${l10n.currencySymbol}${_profit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: _isSubmitting ? null : () { _sellItem(); },
                text: _isSubmitting ? l10n.processing : l10n.sellItem,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
