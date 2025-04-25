import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/category_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/screens/owner/item_detail_screen.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({Key? key}) : super(key: key);

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedCategoryId;
  String? _editingItemId;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    
    await Future.wait([
      itemProvider.fetchItems(),
      categoryProvider.fetchCategories(),
    ]);
  }
  
  void _showAddEditDialog({String? id, String? name, String? categoryId}) {
    _editingItemId = id;
    _nameController.text = name ?? '';
    _selectedCategoryId = categoryId;
    
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingItemId == null ? 'Add Item' : 'Edit Item'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: 'Item Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categoryProvider.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
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
            onPressed: _saveItem,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      bool success;
      
      if (_editingItemId == null) {
        success = await itemProvider.createItem(
          _nameController.text.trim(),
          _selectedCategoryId!,
          [],
        );
      } else {
        success = await itemProvider.updateItem(
          _editingItemId!,
          _nameController.text.trim(),
          _selectedCategoryId!,
        );
      }
      
      if (!mounted) return;
      
      Navigator.of(context).pop();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item ${_editingItemId == null ? 'added' : 'updated'} successfully'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(itemProvider.error ?? 'An error occurred'))
        );
      }
    }
  }
  
  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
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
      final success = await itemProvider.deleteItem(id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(itemProvider.error ?? 'An error occurred'))
        );
      }
    }
  }
  
  void _viewItemDetails(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: itemProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : itemProvider.items.isEmpty
            ? const Center(child: Text('No items found'))
            : ListView.builder(
                itemCount: itemProvider.items.length,
                itemBuilder: (context, index) {
                  final item = itemProvider.items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.category?.name ?? 'No category'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showAddEditDialog(
                            id: item.id,
                            name: item.name,
                            categoryId: item.categoryId,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteItem(item.id),
                        ),
                      ],
                    ),
                    onTap: () => _viewItemDetails(item),
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
