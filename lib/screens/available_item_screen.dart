import 'package:flutter/material.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/providers/user_provider.dart';
import 'package:inventory_frontend/screens/available_item_detail_screen.dart';

class AvailableItemScreen extends StatefulWidget {
  const AvailableItemScreen({Key? key}) : super(key: key);

  @override
  State<AvailableItemScreen> createState() => _AvailableItemScreenState();
}

class _AvailableItemScreenState extends State<AvailableItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _soldPriceController = TextEditingController();
  String? _selectedSalesmanId;

  @override
  void initState() {
    super.initState();
    _loadAvailableItems();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _soldPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableItems() async {
    final availableItemProvider = Provider.of<AvailableItemProvider>(
      context,
      listen: false,
    );
    await availableItemProvider.fetchAvailableItems();
  }

  Future<void> _assignToSalesman(AvailableItem availableItem) async {
    if (_formKey.currentState!.validate()) {
      final quantity = double.parse(_quantityController.text);
      final soldPrice = double.parse(_soldPriceController.text);

      if (quantity > availableItem.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantity cannot be greater than available quantity (${availableItem.quantity})',
            ),
          ),
        );
        return;
      }

      final availableItemProvider = Provider.of<AvailableItemProvider>(
        context,
        listen: false,
      );
      final success = await availableItemProvider.assignToSalesman(
        availableItem.id,
        _selectedSalesmanId!,
        quantity,
        soldPrice,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item assigned to salesman successfully'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(availableItemProvider.error ?? 'An error occurred'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableItemProvider = Provider.of<AvailableItemProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableItems,
          ),
        ],
      ),
      body:
          availableItemProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : availableItemProvider.availableItems.isEmpty
              ? const Center(child: Text('No available items'))
              : ListView.builder(
                itemCount: availableItemProvider.availableItems.length,
                itemBuilder: (context, index) {
                  final availableItem =
                      availableItemProvider.availableItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        "${availableItem.item?.name ?? 'Unknown Item'} (${availableItem.salesman?.name ?? 'Unknown Salesman'})",
                      ),
                      subtitle: Text('Quantity: ${availableItem.quantity}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => AvailableItemDetailScreen(
                                  availableItem: availableItem,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
