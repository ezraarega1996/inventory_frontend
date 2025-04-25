import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/user_provider.dart';
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
  final _emailController = TextEditingController();
  String? _editingUserId;
  bool _obscurePassword = true;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchUsers();
  }
  
  void _showAddEditDialog({
    String? id,
    String? name,
    String? phone,
    String? location,
    String? username,
    String? email,
  }) {
    _editingUserId = id;
    _nameController.text = name ?? '';
    _phoneController.text = phone ?? '';
    _locationController.text = location ?? '';
    _usernameController.text = username ?? '';
    _passwordController.text = '';
    _emailController.text = email ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingUserId == null ? 'Add Salesperson' : 'Edit Salesperson'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _locationController,
                  labelText: 'Location',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _usernameController,
                  labelText: 'Username',
                  enabled: _editingUserId == null, // Only allow editing username when adding new user
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (_editingUserId == null && (value == null || value.isEmpty)) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _saveUser,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      bool success;
      
      final userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'salesman',
      };
      
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
          SnackBar(content: Text('Salesperson ${_editingUserId == null ? 'added' : 'updated'} successfully'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userProvider.error ?? 'An error occurred'))
        );
      }
    }
  }
  
  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Salesperson'),
        content: const Text('Are you sure you want to delete this salesperson? This action cannot be undone.'),
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
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.deleteUser(id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salesperson deleted successfully'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userProvider.error ?? 'An error occurred'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProvider.users.isEmpty
            ? const Center(child: Text('No salespeople found'))
            : ListView.builder(
                itemCount: userProvider.users.length,
                itemBuilder: (context, index) {
                  final user = userProvider.users[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(user.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Username: ${user.username}'),
                          Text('Email: ${user.email}'),
                          Text('Phone: ${user.phone}'),
                          Text('Location: ${user.location}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showAddEditDialog(
                              id: user.id,
                              name: user.name,
                              phone: user.phone,
                              location: user.location,
                              username: user.username,
                              email: user.email,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteUser(user.id),
                          ),
                        ],
                      ),
                      isThreeLine: true,
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
