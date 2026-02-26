import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FractionManagementDialog extends StatefulWidget {
  final Item item;

  const FractionManagementDialog({
    super.key,
    required this.item,
  });

  @override
  State<FractionManagementDialog> createState() => _FractionManagementDialogState();
}

class _FractionManagementDialogState extends State<FractionManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ratioController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  bool _isUnit = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ratioController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  Future<void> _addFraction() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final itemProvider = context.read<ItemProvider>();
    try {
      final success = await itemProvider.createFraction(
        widget.item.id,
        _nameController.text,
        double.parse(_ratioController.text),
        double.parse(_sellingPriceController.text),
        double.parse(_purchasePriceController.text),
        isUnit: _isUnit,
      );

      if (success) {
        _nameController.clear();
        _ratioController.clear();
        _sellingPriceController.clear();
        _purchasePriceController.clear();
        setState(() => _isUnit = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fractionAddedSuccessfully)),
        );
        Navigator.of(context).pop(); // Close dialog after successful addition
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.manageUnitsFor(widget.item.name),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Unit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.addPrimarySellingUnitDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  const SizedBox(height: 16),

                      CustomTextField(
                        controller: _nameController,
                        labelText: l10n.unitName,
                        hintText: 'e.g., Piece, Box, Bottle, Kilogram',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterName;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _ratioController,
                        labelText: l10n.ratio,
                        hintText: 'e.g., 1 for single unit, 12 for dozen, 100 for pack of 100',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterRatio;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.pleaseEnterValidNumber;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _sellingPriceController,
                        labelText: l10n.soldPriceLabel,
                        hintText: 'Price per unit when selling to customers (e.g., 10.50)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterPrice;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.pleaseEnterValidNumber;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _purchasePriceController,
                        labelText: l10n.purchasePrice,
                        hintText: 'Cost per unit when buying from suppliers (e.g., 7.25)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterPrice;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.pleaseEnterValidNumber;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        onPressed: _addFraction,
                        text: l10n.addUnit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
