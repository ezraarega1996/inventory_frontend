import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/business_provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/screens/auth/login_screen.dart';
import 'package:inventory_frontend/screens/owner/categories_screen.dart';
import 'package:inventory_frontend/screens/owner/items_screen.dart';
import 'package:inventory_frontend/screens/owner/sales_screen.dart';
import 'package:inventory_frontend/screens/owner/subscription_screen.dart';
import 'package:inventory_frontend/screens/owner/users_screen.dart';
import 'package:inventory_frontend/screens/owner/boughts_screen.dart';
import 'package:inventory_frontend/screens/owner/available_items_screen.dart';
import 'package:inventory_frontend/widgets/dashboard_card.dart';
import 'package:inventory_frontend/widgets/dashboard_chart.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({Key? key}) : super(key: key);

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

Future<void> _loadDashboardData() async {
  if (!mounted) return;
  
  setState(() {
    _isLoading = true;
  });

  final salesProvider = context.read<SalesProvider>();
  final authProvider = context.read<AuthProvider>();
  final businessProvider = context.read<BusinessProvider>();

  await salesProvider.fetchDashboardStats();
  await salesProvider.fetchTodaySales(); // <-- Add this line
  if (authProvider.user?.businessId != null) {
    await businessProvider.loadCurrentBusiness(
      authProvider.user!.businessId!,
    );
  }

  if (mounted) {
    setState(() {
      _isLoading = false;
    });
  }
}

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen())
    );
  }

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const SalesScreen();
      case 2:
        return const ItemsScreen();
      case 3:
        return const CategoriesScreen();
      case 4:
        return const UsersScreen();
      case 5:
        return const SubscriptionScreen();
      case 6:
        return const BoughtsScreen();
      case 7:
        return const AvailableItemsScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Consumer2<SalesProvider, BusinessProvider>(
      builder: (context, salesProvider, businessProvider, child) {
        final stats = salesProvider.dashboardStats;
        final business = businessProvider.currentBusiness;

        return RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadDashboardData,
                    ),
                  ],
                ),
                if (business != null && business.subscriptionStatus == 'trial') ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.amber.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trial Period',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your trial ends on ${_formatDate(business.trialEndsAt)}. Upgrade to a paid plan to continue using all features.',
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 5; // Switch to subscription screen
                              });
                            },
                            child: const Text('View Plans'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

            // Add this section for today's sales by salesman
            const Text(
              "Today's Sales by Salesman",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (salesProvider.todaySalesData.isEmpty)
              const Text('No sales recorded today.'),
            ...salesProvider.todaySalesData.map((salesData) => Card(
                  child: ListTile(
                    title: Text(salesData.salesmanName ?? 'Unknown'),
                    trailing: Text(
                      '₹${salesData.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )),
                
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (stats != null)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DashboardCard(
                              title: 'Total Sales',
                              value: '\$${stats['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
                              icon: Icons.attach_money,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DashboardCard(
                              title: 'Sales Count',
                              value: '${stats['salesCount'] ?? 0}',
                              icon: Icons.shopping_cart,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Sales Trend (Last 30 Days)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: DashboardChart(data: stats['salesByDay'] ?? []),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Top Selling Items',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (stats['topItems'] as List?)?.length ?? 0,
                        itemBuilder: (context, index) {
                          final item = (stats['topItems'] as List)[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                item['Item']['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Quantity: ${item['totalQuantity']}'),
                              trailing: Text(
                                '\$${item['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        final business = businessProvider.currentBusiness;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(business?.name ?? 'Owner Dashboard'),
          ),
          drawer: _buildDrawer(),
          body: _getScreen(),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Users'),
            selected: _selectedIndex == 4,
            onTap: () {
              setState(() {
                _selectedIndex = 4;
              });
              Navigator.pop(context);
            },
          ),
                    ListTile(
            leading: Icon(Icons.category),
            title: Text('Categories'),
            selected: _selectedIndex == 3,
            onTap: () {
              setState(() {
                _selectedIndex = 3;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.inventory),
            title: Text('Items'),
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_basket),
            title: Text('Stored Items'),
            selected: _selectedIndex == 6,
            onTap: () {
              setState(() {
                _selectedIndex = 6;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.inventory_2),
            title: Text('Available Items'),
            selected: _selectedIndex == 7,
            onTap: () {
              setState(() {
                _selectedIndex = 7;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Sales'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.card_membership),
            title: Text('Subscription'),
            selected: _selectedIndex == 5,
            onTap: () {
              setState(() {
                _selectedIndex = 5;
              });
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
  }
}
