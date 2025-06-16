import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/category_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _editingCategoryId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    await context.read<CategoryProvider>().fetchCategories();
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }
  
  void _showAddEditDialog({String? id, String? name}) {
    _editingCategoryId = id;
    _nameController.text = name ?? '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_editingCategoryId == null ? 'Add Category' : 'Edit Category'),
          content: Form(
            key: _formKey,
            child: CustomTextField(
              controller: _nameController,
              labelText: 'Category Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
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
                  final categoryProvider = context.read<CategoryProvider>();
                  bool success;
                  
                  if (_editingCategoryId == null) {
                    success = await categoryProvider.createCategory(_nameController.text.trim());
                  } else {
                    success = await categoryProvider.updateCategory(_editingCategoryId!, _nameController.text.trim());
                  }
                  
                  if (!mounted) return;
                  
                  Navigator.of(context).pop();
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Category ${_editingCategoryId == null ? 'added' : 'updated'} successfully'))
                    );
                    await _loadCategories();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(categoryProvider.error ?? 'An error occurred'))
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
  
  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category? This action cannot be undone.'),
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
      final categoryProvider = context.read<CategoryProvider>();
      final success = await categoryProvider.deleteCategory(id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully'))
        );
        await _loadCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(categoryProvider.error ?? 'An error occurred'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                if (categoryProvider.categories.isEmpty) {
                  return const Center(child: Text('No categories found'));
                }
                return RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: ListView.builder(
                    itemCount: categoryProvider.categories.length,
                    itemBuilder: (context, index) {
                      final category = categoryProvider.categories[index];
                      return ListTile(
                        title: Text(category.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditDialog(
                                id: category.id,
                                name: category.name,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteCategory(category.id),
                            ),
                          ],
                        ),
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
