import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/screens/auth/login_screen.dart';
import 'package:inventory_frontend/screens/salesman/sell_item_screen.dart';
import 'package:inventory_frontend/screens/salesman/view_sales_screen.dart';
import 'package:inventory_frontend/screens/available_items_screen.dart';
import 'package:inventory_frontend/widgets/dashboard_card.dart';
import 'package:inventory_frontend/widgets/language_selector.dart';
import 'package:inventory_frontend/screens/summary_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SalesmanDashboard extends StatefulWidget {
  const SalesmanDashboard({super.key});

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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToLoadDashboard(e.toString()))),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToLogout(e.toString()))),
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
      case 4:
        final authProvider = context.read<AuthProvider>();
        final shopId = authProvider.user?.shopId ?? authProvider.user?.shop?.id;
        print("shopId is: $shopId");
        
        return SummaryScreen(
          fixedShopId: shopId,
          allowShopSwitch: false,
        );
      default:
        return _buildDashboard();
    }
  }
  
  Widget _buildDashboard() {
    final l10n = AppLocalizations.of(context)!;
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
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.dashboard,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadDashboardData,
                          ),
                        ],
                      ),
                    DashboardCard(
                      title: l10n.totalSales,
                      value: '\$${salesProvider.totalSales?.toStringAsFixed(2) ?? '0.00'}',
                      icon: Icons.point_of_sale,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: l10n.totalItemsSold,
                      value: '${salesProvider.totalItemsSold ?? 0}',
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: l10n.todaysSales,
                      value: '\$${salesProvider.todaySales?.toStringAsFixed(2) ?? '0.00'}',
                      icon: Icons.today,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        final authProvider = context.read<AuthProvider>();
                        final shopId = authProvider.user?.shopId ?? authProvider.user?.shop?.id;
                        print("shopId is: $shopId");
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SummaryScreen(
                              fixedShopId: shopId,
                              allowShopSwitch: false,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.table_chart),
                      label: Text(l10n.transactions),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Text(authProvider.user?.name ?? l10n.salesmanDashboard);
          },
        ),
        actions: const [
          LanguageSelector(),
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
                          authProvider.user?.name.substring(0, 1).toUpperCase() ?? 'S',
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        authProvider.user?.name ?? l10n.salesmanDashboard,
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
                  title: Text(l10n.dashboard),
                  selected: _selectedIndex == 0,
                  selectedColor: Colors.blue,
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                  title: Text(l10n.sellItem),
                  selected: _selectedIndex == 2,
                  selectedColor: Colors.orange,
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.green),
                  title: Text(l10n.availableItems),
                  selected: _selectedIndex == 1,
                  selectedColor: Colors.green,
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.purple),
                  title: Text(l10n.salesHistory),
                  selected: _selectedIndex == 3,
                  selectedColor: Colors.purple,
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart, color: Colors.teal),
                  title: Text("Summary"),
                  selected: _selectedIndex == 4,
                  selectedColor: Colors.teal,
                  onTap: () {
                    setState(() => _selectedIndex = 4);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(l10n.logout),
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
