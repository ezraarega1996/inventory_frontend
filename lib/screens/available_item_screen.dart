import 'package:flutter/material.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/providers/user_provider.dart';

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
    final availableItemProvider = Provider.of<AvailableItemProvider>(context, listen: false);
    await availableItemProvider.fetchAvailableItems();
  }

  Future<void> _assignToSalesman(AvailableItem availableItem) async {
    if (_formKey.currentState!.validate()) {
      final quantity = double.parse(_quantityController.text);
      final soldPrice = double.parse(_soldPriceController.text);

      if (quantity > availableItem.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity cannot be greater than available quantity (${availableItem.quantity})')),
        );
        return;
      }

      final availableItemProvider = Provider.of<AvailableItemProvider>(context, listen: false);
      final success = await availableItemProvider.assignToSalesman(
        availableItem.id,
        _selectedSalesmanId!,
        quantity,
        soldPrice,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item assigned to salesman successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(availableItemProvider.error ?? 'An error occurred')),
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
      body: availableItemProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : availableItemProvider.availableItems.isEmpty
              ? const Center(child: Text('No available items'))
              : ListView.builder(
                  itemCount: availableItemProvider.availableItems.length,
                  itemBuilder: (context, index) {
                    final availableItem = availableItemProvider.availableItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        title: Text(availableItem.item?.name ?? 'Unknown Item'),
                        subtitle: Text('Quantity: ${availableItem.quantity}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Item: ${availableItem.item?.name ?? 'Unknown'}'),
                                Text('Available Quantity: ${availableItem.quantity}'),
                                Text('Sold Price: \$${availableItem.soldPrice.toStringAsFixed(2)}'),
                                if (availableItem.salesman != null)
                                  Text('Assigned to: ${availableItem.salesman?.name ?? 'Unknown'}'),
                                
                                const SizedBox(height: 16),
                                const Text(
                                  'Bought Transactions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (availableItem.boughtTransactions?.isEmpty ?? true)
                                  const Text('No bought transactions')
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: availableItem.boughtTransactions?.length ?? 0,
                                    itemBuilder: (context, index) {
                                      final transaction = availableItem.boughtTransactions![index];
                                      return ListTile(
                                        title: Text('Quantity: ${transaction.quantity}'),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Fraction: ${transaction.fraction?.name ?? 'Unknown'}'),
                                            Text('Price: \$${transaction.fractionSoldPrice.toStringAsFixed(2)}'),
                                            Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(transaction.createdAt)}'),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                const SizedBox(height: 16),
                                const Text(
                                  'Sold Transactions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (availableItem.soldTransactions?.isEmpty ?? true)
                                  const Text('No sold transactions')
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: availableItem.soldTransactions?.length ?? 0,
                                    itemBuilder: (context, index) {
                                      final transaction = availableItem.soldTransactions![index];
                                      return ListTile(
                                        title: Text('Quantity: ${transaction.quantity}'),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Fraction: ${transaction.fraction?.name ?? 'Unknown'}'),
                                            Text('Price: \$${transaction.soldPrice.toStringAsFixed(2)}'),
                                            Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(transaction.createdAt)}'),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                if (authProvider.user?.role == 'admin' && availableItem.salesman == null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 16),
                                      CustomButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Assign to Salesman'),
                                              content: Form(
                                                key: _formKey,
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    DropdownButtonFormField<String>(
                                                      value: _selectedSalesmanId,
                                                      decoration: const InputDecoration(
                                                        labelText: 'Select Salesman',
                                                        border: OutlineInputBorder(),
                                                      ),
                                                      items: userProvider.users
                                                          .where((user) => user.role == 'salesman')
                                                          .map((user) {
                                                        return DropdownMenuItem<String>(
                                                          value: user.id,
                                                          child: Text(user.name),
                                                        );
                                                      }).toList(),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _selectedSalesmanId = value;
                                                        });
                                                      },
                                                      validator: (value) {
                                                        if (value == null) {
                                                          return 'Please select a salesman';
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
                                                        final quantity = double.tryParse(value);
                                                        if (quantity == null) {
                                                          return 'Please enter a valid number';
                                                        }
                                                        if (quantity <= 0) {
                                                          return 'Quantity must be greater than 0';
                                                        }
                                                        if (quantity > availableItem.quantity) {
                                                          return 'Quantity cannot be greater than available quantity';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),
                                                    CustomTextField(
                                                      controller: _soldPriceController,
                                                      labelText: 'Sold Price',
                                                      keyboardType: TextInputType.number,
                                                      validator: (value) {
                                                        if (value == null || value.isEmpty) {
                                                          return 'Please enter a sold price';
                                                        }
                                                        final price = double.tryParse(value);
                                                        if (price == null) {
                                                          return 'Please enter a valid number';
                                                        }
                                                        if (price <= 0) {
                                                          return 'Price must be greater than 0';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    _assignToSalesman(availableItem);
                                                  },
                                                  child: const Text('Assign'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        text: 'Assign to Salesman',
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
} 