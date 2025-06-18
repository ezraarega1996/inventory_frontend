import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

    final l10n = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l10n.fractionAddedSuccessfully)),
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
    final l10n = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l10n.unitUpdatedSuccessfully)),
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteUnit),
        content: Text(l10n.confirmDeleteUnit),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final itemProvider = context.read<ItemProvider>();
      final success = await itemProvider.deleteFraction(fraction.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.unitDeletedSuccessfully)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageUnitsFor(widget.item.name)),
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
                    labelText: l10n.unitName,
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
                    controller: _priceController,
                    labelText: l10n.price,
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
                  const SizedBox(height: 16),
                  CustomButton(
                    onPressed: _addFraction,
                    text: l10n.addUnit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.existingUnits,
              style: const TextStyle(
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
                    return Center(
                      child: Text(l10n.noUnitsAddedYet),
                    );
                  }

                  return ListView.builder(
                    itemCount: fractions.length,
                    itemBuilder: (context, index) {
                      final fraction = fractions[index];
                      return Card(
                        child: ListTile(
                          title: Text(fraction.name),
                          subtitle: Text(l10n.ratioAndPrice(fraction.ratio, fraction.price)),
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