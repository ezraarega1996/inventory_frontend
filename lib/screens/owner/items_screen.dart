import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    _editingItemId = id;
    _nameController.text = name ?? '';
    _selectedCategoryId = categoryId;

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
                Consumer<CategoryProvider>(
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
                      SnackBar(content: Text(l10n.success))
                    );
                    await _loadAll();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(itemProvider.error ?? l10n.error))
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.items),
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
                  return Center(child: Text(l10n.noData));
                }
                return RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView.builder(
                    itemCount: itemProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = itemProvider.items[index];
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
