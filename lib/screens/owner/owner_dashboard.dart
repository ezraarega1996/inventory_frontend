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
import 'package:inventory_frontend/widgets/dashboard_card.dart';
import 'package:inventory_frontend/widgets/dashboard_chart.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({Key? key}) : super(key: key);

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    
    await salesProvider.fetchDashboardStats();
    
    if (authProvider.user?.businessId != null) {
      await businessProvider.loadCurrentBusiness(authProvider.user!.businessId!);
    }
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
      default:
        return _buildDashboard();
    }
  }
  
  Widget _buildDashboard() {
    final salesProvider = Provider.of<SalesProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);
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
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
            if (salesProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (stats != null)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DashboardCard(
                          title: 'Total Sales',
                          value: '\$${stats['totalSales'] ?? 0}',
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: DashboardChart(
                      data: stats['salesByDay'] ?? [],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Top Selling Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (stats['topItems'] as List?)?.length ?? 0,
                    itemBuilder: (context, index) {
                      final item = (stats['topItems'] as List)[index];
                      return ListTile(
                        title: Text(item['Item']['name']),
                        subtitle: Text('Quantity: ${item['totalQuantity']}'),
                        trailing: Text('\$${item['totalAmount']}'),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);
    final business = businessProvider.currentBusiness;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(business?.name ?? 'Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _getScreen(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership),
            label: 'Subscription',
          ),
        ],
      ),
    );
  }
}
