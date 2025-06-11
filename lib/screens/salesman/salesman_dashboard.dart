import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/screens/auth/login_screen.dart';
import 'package:inventory_frontend/screens/salesman/sell_item_screen.dart';
import 'package:inventory_frontend/screens/salesman/view_items_screen.dart';
import 'package:inventory_frontend/screens/salesman/view_sales_screen.dart';
import 'package:inventory_frontend/screens/salesman/available_items_screen.dart';
import 'package:inventory_frontend/widgets/dashboard_card.dart';

class SalesmanDashboard extends StatefulWidget {
  const SalesmanDashboard({Key? key}) : super(key: key);

  @override
  State<SalesmanDashboard> createState() => _SalesmanDashboardState();
}

class _SalesmanDashboardState extends State<SalesmanDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    try {
      final salesProvider = context.read<SalesProvider>();
      await salesProvider.fetchDashboardStats();
      await salesProvider.fetchUserSales();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  
  Future<void> _logout() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen())
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  
  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const AvailableItemsScreen();
      case 2:
        return const SellItemScreen();
      case 3:
        return const ViewSalesScreen();
      default:
        return _buildDashboard();
    }
  }
  
  Widget _buildDashboard() {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, child) {
        return RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardCard(
                      title: 'Total Sales',
                      value: '\$${salesProvider.totalSales?.toStringAsFixed(2) ?? '0.00'}',
                      icon: Icons.point_of_sale,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'Total Items Sold',
                      value: '${salesProvider.totalItemsSold ?? 0}',
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'Today\'s Sales',
                      value: '\$${salesProvider.todaySales?.toStringAsFixed(2) ?? '0.00'}',
                      icon: Icons.today,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Text(authProvider.user?.name ?? 'Salesman Dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          authProvider.user?.name?.substring(0, 1).toUpperCase() ?? 'S',
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        authProvider.user?.name ?? 'Salesman',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        authProvider.user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard, color: Colors.blue),
                  title: const Text('Dashboard'),
                  selected: _selectedIndex == 0,
                  selectedColor: Colors.blue,
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                  title: const Text('Sell Item'),
                  selected: _selectedIndex == 2,
                  selectedColor: Colors.orange,
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.green),
                  title: const Text('Available Items'),
                  selected: _selectedIndex == 1,
                  selectedColor: Colors.green,
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.purple),
                  title: const Text('Sales History'),
                  selected: _selectedIndex == 3,
                  selectedColor: Colors.purple,
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  onTap: _logout,
                ),
              ],
            ),
          );
        },
      ),
      body: _getScreen(),
    );
  }
}
