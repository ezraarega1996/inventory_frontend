import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/screens/admin/businesses_screen.dart';
import 'package:inventory_frontend/screens/admin/users_screen.dart';
import 'package:inventory_frontend/screens/auth/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  
  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen())
    );
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return const BusinessesScreen();
      case 1:
        return const UsersScreen();
      default:
        return const BusinessesScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _getScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.business),
            label: l10n.businessesLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: l10n.users,
          ),
        ],
      ),
    );
  }
}
