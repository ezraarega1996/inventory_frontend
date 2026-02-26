import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/category_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/screens/owner/item_detail_screen.dart';
import 'package:inventory_frontend/screens/owner/categories_screen.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';

class ItemsScreen extends StatefulWidget {
  final String? initialCategoryId;
  final bool autoOpenAdd;
  const ItemsScreen({super.key, this.initialCategoryId, this.autoOpenAdd = false});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fractionNameController = TextEditingController();
  final _ratioController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  String? _selectedCategoryId;
  String? _editingItemId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
    if (widget.autoOpenAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAddEditDialog();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fractionNameController.dispose();
    _ratioController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
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

  Future<void> _navigateAndAddCategory(StateSetter setDialogState) async {
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => const CategoriesScreen(),
        settings: const RouteSettings(arguments: true),
      ),
    );
    if (result != null && mounted) {
      await context.read<CategoryProvider>().fetchCategories();
      setDialogState(() { _selectedCategoryId = result; });
    }
  }

  void _showAddEditDialog({String? id, String? name, String? categoryId}) {
    final l10n = AppLocalizations.of(context)!;
    _editingItemId = id;
    _nameController.text = name ?? '';
    _fractionNameController.clear();
    _ratioController.clear();
    _sellingPriceController.clear();
    _purchasePriceController.clear();
    _selectedCategoryId = categoryId ?? (id == null ? widget.initialCategoryId : null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_editingItemId == null ? l10n.addNew : l10n.edit),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _nameController,
                  labelText: l10n.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.required;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, child) {
                          return DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: l10n.select,
                              border: const OutlineInputBorder(),
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
                                return l10n.required;
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSubmitting ? null : () => _navigateAndAddCategory(setDialogState),
                      icon: const Icon(Icons.add),
                      tooltip: 'Add new category',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_editingItemId == null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Unit Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add the primary selling unit for this item. eg. Piece, Box, Bottle, Kilogram, litre, etc.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fractionNameController,
                    labelText: 'Unit Name',
                    hintText: 'e.g., Piece, Box, Bottle, Kilogram',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Unit name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _ratioController,
                    labelText: 'Ratio',
                    hintText: 'e.g., 1 for single unit, 12 for dozen, 100 for pack of 100',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ratio is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _sellingPriceController,
                    labelText: 'Selling Price',
                    hintText: 'Price per unit when selling to customers (e.g., 10.50)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selling price is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _purchasePriceController,
                    labelText: 'Purchase Price',
                    hintText: 'Cost per unit when buying from suppliers (e.g., 7.25)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Purchase price is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ],
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
                
                setState(() { _isSubmitting = true; });
                setDialogState(() {});
                
                try {
                  final itemProvider = context.read<ItemProvider>();
                  bool success;
                  
                  if (_editingItemId == null) {
                    // Create item first
                    success = await itemProvider.createItem(
                      _nameController.text.trim(),
                      _selectedCategoryId!,
                      [],
                    );
                    
                    if (success) {
                      // Find the newly created item
                      final newItem = itemProvider.items
                          .where((i) => i.name.trim() == _nameController.text.trim())
                          .firstOrNull;
                      
                      if (newItem != null) {
                        // Create the fraction for the new item
                        final fractionSuccess = await itemProvider.createFraction(
                          newItem.id,
                          _fractionNameController.text.trim(),
                          double.parse(_ratioController.text),
                          double.parse(_sellingPriceController.text),
                          double.parse(_purchasePriceController.text),
                          isUnit: true,
                        );
                        
                        if (!fractionSuccess) {
                          throw Exception(itemProvider.error ?? 'Failed to create unit');
                        }
                      }
                    }
                  } else {
                    success = await itemProvider.updateItem(
                      _editingItemId!,
                      _nameController.text.trim(),
                      _selectedCategoryId!,
                    );
                  }
                  
                  if (!mounted) return;
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.success))
                    );
                    await _loadAll();
                    // If we were opened from BoughtsScreen (autoOpenAdd), return the new item ID and close
                    if (widget.autoOpenAdd && mounted) {
                      final newItemId = itemProvider.items
                          .where((i) => i.name.trim() == _nameController.text.trim())
                          .firstOrNull
                          ?.id;
                      if (newItemId != null) {
                        Navigator.of(context).pop(newItemId);
                        return;
                      }
                    }
                    // Navigate to item details after successful creation
                    if (_editingItemId == null && mounted) {
                      final newItem = itemProvider.items
                          .where((i) => i.name.trim() == _nameController.text.trim())
                          .firstOrNull;
                      if (newItem != null) {
                        Navigator.of(context).pop(); // Close dialog first
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(item: newItem),
                          ),
                        );
                        return;
                      }
                    }
                    if (mounted) Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(itemProvider.error ?? l10n.error))
                    );
                    if (mounted) Navigator.of(context).pop();
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

  Future<void> _deleteItem(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDelete),
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

    if (confirm == true) {
      final itemProvider = context.read<ItemProvider>();
      final success = await itemProvider.deleteItem(id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.success))
        );
        await _loadAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(itemProvider.error ?? l10n.error))
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
    final l10n = AppLocalizations.of(context)!;
    final items = context.watch<ItemProvider>().items;
    final filteredItems = widget.initialCategoryId != null
        ? items.where((item) => item.categoryId == widget.initialCategoryId).toList()
        : items;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialCategoryId != null
            ? l10n.items
            : l10n.items),
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
                if (filteredItems.isEmpty) {
                  return Center(child: Text(l10n.noData));
                }
                return RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.category?.name ?? ''),
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
