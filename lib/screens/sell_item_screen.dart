import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_frontend/utils/api.dart';
import 'dart:convert';
import '../models/available_item.dart';
import '../models/item.dart';
import '../models/fraction.dart';
import '../config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SellItemScreen extends StatefulWidget {
  final String token;
  final String userId;
  final String businessId;

  const SellItemScreen({
    Key? key,
    required this.token,
    required this.userId,
    required this.businessId,
  }) : super(key: key);

  @override
  State<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  List<AvailableItem> availableItems = [];
  List<Item> items = [];
  List<Fraction> fractions = [];
  String? selectedItemId;
  String? selectedFractionId;
  final quantityController = TextEditingController();
  final soldPriceController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final availableItemsResponse = await Api.get("available-items");
      if (availableItemsResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(availableItemsResponse.body);
        setState(() {
          availableItems = data.map((item) => AvailableItem.fromJson(item)).toList();
        });
      }

      final itemsResponse = await http.get(
        Uri.parse('$baseUrl/items'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (itemsResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(itemsResponse.body);
        setState(() {
          items = data.map((item) => Item.fromJson(item)).toList();
        });
      }

      final fractionsResponse = await http.get(
        Uri.parse('$baseUrl/fractions'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (fractionsResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(fractionsResponse.body);
        setState(() {
          fractions = data.map((fraction) => Fraction.fromJson(fraction)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingData(e.toString()))),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createSale() async {
    try {
      final availableItem = availableItems.firstWhere(
        (item) => item.itemId == selectedItemId,
        orElse: () => AvailableItem(
          id: '',
          itemId: selectedItemId!,
          quantity: 0,
          businessId: widget.businessId,
          salesmanId: widget.userId,
          soldPrice: 0,
        ),
      );

      final response = await http.post(
        Uri.parse('$baseUrl/sell'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'itemId': selectedItemId,
          'quantity': double.parse(quantityController.text),
          'fractionId': selectedFractionId,
          'businessId': widget.businessId,
          'salesmanId': widget.userId,
          'soldPrice': double.parse(soldPriceController.text),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saleCreatedSuccessfully)),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorCreatingSale(response.body))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorCreatingSale(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sellItem),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedItemId,
                    decoration: InputDecoration(
                      labelText: l10n.item,
                      border: const OutlineInputBorder(),
                    ),
                    items: items.map((item) {
                      return DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedItemId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedFractionId,
                    decoration: InputDecoration(
                      labelText: l10n.fraction,
                      border: const OutlineInputBorder(),
                    ),
                    items: fractions.map((fraction) {
                      return DropdownMenuItem(
                        value: fraction.id,
                        child: Text(fraction.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedFractionId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: l10n.quantityLabel,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: soldPriceController,
                    decoration: InputDecoration(
                      labelText: l10n.soldPriceLabel,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createSale,
                    child: Text(l10n.createSale),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    soldPriceController.dispose();
    super.dispose();
  }
} 