import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/user.dart';
import 'package:inventory_frontend/utils/api.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    print('Loading users...');
    setState(() {
      _isLoading = true;
      _error = null;
    });
    print("one");
    try {
      final response = await Api.get('users');
      print("two");
      setState(() {
        _users = List<User>.from(
          response.map((x) => User.fromJson(x))
        );
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading users: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _viewUserDetails(User user) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.viewingDetailsFor(user.name)))
    );
  }
  
  Future<void> _toggleUserStatus(User user) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await Api.put('users/${user.id}', {
        'isActive': !(user.isActive ?? true),
      });
      
      await _loadUsers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userStatusUpdatedSuccessfully))
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithDetails(_error ?? '')))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Text(l10n.errorWithDetails(_error!)))
            : _users.isEmpty
              ? Center(child: Text(l10n.noUsersFound))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(user.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.roleWithValue(user.role)),
                            Text(l10n.businessWithValue(user.business?.name ?? l10n.na)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                user.isActive ?? true ? Icons.toggle_on : Icons.toggle_off,
                                color: user.isActive ?? true ? Colors.green : Colors.grey,
                              ),
                              onPressed: () => _toggleUserStatus(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info),
                              onPressed: () => _viewUserDetails(user),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
