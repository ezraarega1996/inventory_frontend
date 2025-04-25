import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  
  const ItemDetailScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ratioController = TextEditingController();
  final _priceController = TextEditingController();
  String? _editingFractionId;
  
  @override
  void dispose() {
    _nameController.dispose();
    _ratioController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  void _showAddEditFractionDialog({String? id, String? name, double? ratio, double? price}) {
    _editingFractionId = id;
    _nameController.text = name ?? '';
    _ratioController.text = ratio?.toString() ?? '';
    _priceController.text = price?.toString() ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingFractionId == null ? 'Add Fraction' : 'Edit Fraction'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: 'Fraction Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a fraction name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _ratioController,
                labelText: 'Ratio',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a ratio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _priceController,
                labelText: 'Price',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _saveFraction,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveFraction() async {
    if (_formKey.currentState!.validate()) {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      bool success;
      
      if (_editingFractionId == null) {
        success = await itemProvider.createFraction(
          widget.item.id,
          _nameController.text.trim(),
          double.parse(_ratioController.text),
          double.parse(_priceController.text),
        );
      } else {
        success = await itemProvider.updateFraction(
          _editingFractionId!,
          _nameController.text.trim(),
          double.parse(_ratioController.text),
          double.parse(_priceController.text),
        );
      }
      
      if (!mounted) return;
      
      Navigator.of(context).pop();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fraction ${_editingFractionId == null ? 'added' : 'updated'} successfully'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(itemProvider.error ?? 'An error occurred'))
        );
      }
    }
  }
  
  Future<void> _deleteFraction(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fraction'),
        content: const Text('Are you sure you want to delete this fraction? This action cannot be undone.'),
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
    
    if (confirm == true) {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final success = await itemProvider.deleteFraction(id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fraction deleted successfully'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(itemProvider.error ?? 'An error occurred'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final item = itemProvider.items.firstWhere((i) => i.id == widget.item.id);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Item Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Name:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(item.name),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Category:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(item.category?.name ?? 'No category'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fractions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CustomButton(
                  text: 'Add Fraction',
                  icon: Icons.add,
                  onPressed: () => _showAddEditFractionDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (item.fractions == null || item.fractions!.isEmpty)
              const Center(
                child: Text('No fractions found for this item'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: item.fractions!.length,
                itemBuilder: (context, index) {
                  final fraction = item.fractions![index];
                  return Card(
                    child: ListTile(
                      title: Text(fraction.name),
                      subtitle: Text('Ratio: ${fraction.ratio}, Price: \$${fraction.price}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showAddEditFractionDialog(
                              id: fraction.id,
                              name: fraction.name,
                              ratio: fraction.ratio,
                              price: fraction.price,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteFraction(fraction.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
