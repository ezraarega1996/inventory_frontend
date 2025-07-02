import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:inventory_frontend/providers/user_provider.dart';
import 'package:inventory_frontend/providers/shop_provider.dart';
import 'package:inventory_frontend/models/shop.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _editingUserId;
  String? _selectedShopId;
  bool _obscurePassword = true;
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadShops();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    final userProvider = context.read<UserProvider>();
    await userProvider.fetchUsers();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadShops() async {
    final shopProvider = context.read<ShopProvider>();
    await shopProvider.getShops();
  }

  void _showAddEditDialog({
    String? id,
    String? name,
    String? phone,
    String? location,
    String? username,
    String? shopId,
  }) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _editingUserId = id;
      _selectedShopId = shopId;
      _nameController.text = name ?? '';
      _phoneController.text = phone ?? '';
      _locationController.text = location ?? '';
      _usernameController.text = username ?? '';
      _passwordController.text = '';
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_editingUserId == null ? l10n.addNew : l10n.edit),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: _nameController,
                    labelText: l10n.name,
                    enabled: !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    labelText: l10n.phone,
                    keyboardType: TextInputType.phone,
                    enabled: !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _locationController,
                    labelText: l10n.location,
                    enabled: !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _usernameController,
                    labelText: l10n.username,
                    enabled: _editingUserId == null && !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: l10n.password,
                    obscureText: _obscurePassword,
                    enabled: !_isSubmitting,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: _isSubmitting ? null : () {
                        setDialogState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (_editingUserId == null && (value == null || value.isEmpty)) {
                        return l10n.required;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Consumer<ShopProvider>(
                    builder: (context, shopProvider, child) {
                      final shops = shopProvider.shops;
                      return DropdownButtonFormField<String>(
                        value: _selectedShopId,
                        decoration: const InputDecoration(
                          labelText: 'Shop (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('No shop assigned'),
                          ),
                          ...shops.map((shop) {
                            return DropdownMenuItem<String>(
                              value: shop.id,
                              child: Text(shop.name),
                            );
                          }).toList(),
                        ],
                        onChanged: _isSubmitting ? null : (value) {
                          setDialogState(() {
                            _selectedShopId = value;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
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
                  final userProvider = context.read<UserProvider>();
                  bool success;
                  
                  final userData = {
                    'name': _nameController.text.trim(),
                    'phone': _phoneController.text.trim(),
                    'location': _locationController.text.trim(),
                    'role': 'salesman',
                  };
                  
                  // Add shopId if selected
                  if (_selectedShopId != null) {
                    userData['shopId'] = _selectedShopId!;
                  }
                  
                  if (_editingUserId == null) {
                    userData['username'] = _usernameController.text.trim();
                    userData['password'] = _passwordController.text;
                    success = await userProvider.createUser(userData);
                  } else {
                    if (_passwordController.text.isNotEmpty) {
                      userData['password'] = _passwordController.text;
                    }
                    success = await userProvider.updateUser(_editingUserId!, userData);
                  }
                  
                  if (!mounted) return;
                  
                  Navigator.of(context).pop();
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.success))
                    );
                    await _loadUsers();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(userProvider.error ?? l10n.error))
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
  
  Future<void> _deleteUser(String id) async {
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
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.deleteUser(id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.success))
        );
        _loadUsers(); // Reload users after successful deletion
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userProvider.error ?? l10n.error))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.users),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final users = userProvider.users.where((user) => user.role == 'salesman').toList();
                
                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noSalespeopleFound,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.usernameWithValue(user.username)),
                              Text(l10n.phoneWithValue(user.phone)),
                              Text(l10n.locationWithValue(user.location)),
                              Consumer<ShopProvider>(
                                builder: (context, shopProvider, child) {
                                  Shop? shop;
                                  if (user.shopId != null) {
                                    try {
                                      shop = shopProvider.shops.firstWhere(
                                        (s) => s.id == user.shopId,
                                      );
                                    } catch (e) {
                                      shop = null;
                                    }
                                  }
                                  return Text(
                                    l10n.shopWithValue(
                                      shop?.name ?? l10n.noShopAssigned,
                                    ),
                                    style: TextStyle(
                                      color: shop != null ? Colors.green : Colors.grey,
                                      fontWeight: shop != null ? FontWeight.bold : FontWeight.normal,
                                   
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: _isSubmitting ? null : () => _showAddEditDialog(
                                  id: user.id,
                                  name: user.name,
                                  phone: user.phone,
                                  location: user.location,
                                  username: user.username,
                                  shopId: user.shopId,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: _isSubmitting ? null : () => _deleteUser(user.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading || _isSubmitting ? null : () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
