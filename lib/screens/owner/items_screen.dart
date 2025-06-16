import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/category_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/screens/owner/item_detail_screen.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedCategoryId;
  String? _editingItemId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    final itemProvider = context.read<ItemProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    await Future.wait([
      itemProvider.fetchItems(),
      categoryProvider.fetchCategories(),
    ]);
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  void _showAddEditDialog({String? id, String? name, String? categoryId}) {
    _editingItemId = id;
    _nameController.text = name ?? '';
    _selectedCategoryId = categoryId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Select Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categoryProvider.categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: _isSubmitting ? null : (value) {
                        setDialogState(() { _selectedCategoryId = value; });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    );
                  },
                ),
              ],
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
                
                setState(() { _isSubmitting = true; });
                setDialogState(() {});
                
                try {
                  final itemProvider = context.read<ItemProvider>();
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
                    await _loadAll();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(itemProvider.error ?? 'An error occurred'))
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

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: const Text(
              'Are you sure you want to delete this item? This action cannot be undone.',
            ),
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
      final itemProvider = context.read<ItemProvider>();
      final success = await itemProvider.deleteItem(id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
        await _loadAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(itemProvider.error ?? 'An error occurred')),
        );
      }
    }
  }

  void _viewItemDetails(Item item) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ItemProvider>(
              builder: (context, itemProvider, child) {
                if (itemProvider.items.isEmpty) {
                  return const Center(child: Text('No items found'));
                }
                return RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView.builder(
                    itemCount: itemProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = itemProvider.items[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.category?.name ?? 'No category'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddEditDialog(
                                id: item.id,
                                name: item.name,
                                categoryId: item.categoryId,
                              );
                            } else if (value == 'delete') {
                              _deleteItem(item.id);
                            }
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Edit'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete),
                                    title: Text('Delete'),
                                  ),
                                ),
                              ],
                        ),
                        onTap: () => _viewItemDetails(item),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
