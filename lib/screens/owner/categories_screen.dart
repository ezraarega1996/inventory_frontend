import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/category_provider.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _editingCategoryId;
  
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
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.fetchCategories();
  }
  
  void _showAddEditDialog({String? id, String? name}) {
    _editingCategoryId = id;
    _nameController.text = name ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _saveCategory,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(categoryProvider.error ?? 'An error occurred'))
        );
      }
    }
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
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final success = await categoryProvider.deleteCategory(id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(categoryProvider.error ?? 'An error occurred'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: categoryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoryProvider.categories.isEmpty
            ? const Center(child: Text('No categories found'))
            : ListView.builder(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
