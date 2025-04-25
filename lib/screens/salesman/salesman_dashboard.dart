import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/screens/auth/login_screen.dart';
import 'package:inventory_frontend/screens/salesman/sell_item_screen.dart';
import 'package:inventory_frontend/screens/salesman/view_items_screen.dart';
import 'package:inventory_frontend/screens/salesman/view_sales_screen.dart';
import 'package:inventory_frontend/widgets/dashboard_card.dart';

class SalesmanDashboard extends StatefulWidget {
  const SalesmanDashboard({Key? key}) : super(key: key);

  @override
  State<SalesmanDashboard> createState() => _SalesmanDashboardState();
}

class _SalesmanDashboardState extends State<SalesmanDashboard> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    await salesProvider.fetchDashboardStats();
    await salesProvider.fetchUserSales();
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
        return const ViewItemsScreen();
      case 2:
        return const SellItemScreen();
      case 3:
        return const ViewSalesScreen();
      default:
        return _buildDashboard();
    }
  }
  
  Widget _buildDashboard() {
    final salesProvider = Provider.of<SalesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final stats = salesProvider.dashboardStats;
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${authProvider.user?.name ?? 'Salesperson'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                          title: 'Today\'s Sales',
                          value: '\$${_calculateTodaySales(salesProvider)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardCard(
                          title: 'Items Sold Today',
                          value: '${_calculateTodayItemCount(salesProvider)}',
                          icon: Icons.shopping_cart,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Sales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentSales(salesProvider),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  double _calculateTodaySales(SalesProvider provider) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    return provider.sales
      .where((sale) => sale.soldTime.isAfter(todayStart))
      .fold(0, (sum, sale) => sum + sale.amount);
  }
  
  int _calculateTodayItemCount(SalesProvider provider) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    return provider.sales
      .where((sale) => sale.soldTime.isAfter(todayStart))
      .length;
  }
  
  Widget _buildRecentSales(SalesProvider provider) {
    if (provider.sales.isEmpty) {
      return const Center(
        child: Text('No recent sales'),
      );
    }
    
    final recentSales = provider.sales.take(5).toList();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentSales.length,
      itemBuilder: (context, index) {
        final sale = recentSales[index];
        return Card(
          child: ListTile(
            title: Text(sale.item?.name ?? 'Unknown Item'),
            subtitle: Text('${sale.fractionId} - Qty: ${sale.quantity}'),
            trailing: Text('\$${sale.amount}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salesman Dashboard'),
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
            icon: Icon(Icons.inventory),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Sell',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Sales',
          ),
        ],
      ),
    );
  }
}
