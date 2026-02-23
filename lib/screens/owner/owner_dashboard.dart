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
import 'package:inventory_frontend/screens/available_items_screen.dart';
import 'package:inventory_frontend/screens/owner/shops_screen.dart';
import 'package:inventory_frontend/screens/summary_screen.dart';
import 'package:inventory_frontend/widgets/dashboard_card.dart';
import 'package:inventory_frontend/widgets/dashboard_chart.dart';
import 'package:inventory_frontend/widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

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

  try {
    await Future.wait([
      salesProvider.fetchDashboardStats(),
      salesProvider.fetchTodaySales(),
      if (authProvider.user?.businessId != null)
        businessProvider.loadCurrentBusiness(
          authProvider.user!.businessId!,
        ),
    ]);
  } catch (_) {
    // Providers already track error state.
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
      case 8:
        return const ShopsScreen();
      case 9:
        return const SummaryScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Consumer2<SalesProvider, BusinessProvider>(
      builder: (context, salesProvider, businessProvider, child) {
        final stats = salesProvider.dashboardStats;
        final business = businessProvider.currentBusiness;
        final l10n = AppLocalizations.of(context)!;
        final currency = NumberFormat('#,##0.00');
        final currencySymbol = l10n.currencySymbol;

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
                    Text(
                      l10n.dashboard,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadDashboardData,
                      tooltip: l10n.refresh,
                    ),
                  ],
                ),
                if (business != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                    child: Text(
                      business.name,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (salesProvider.error != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              salesProvider.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (stats != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DashboardCard(
                              title: l10n.totalSales,
                              value: '$currencySymbol${currency.format((stats['totalSales'] ?? 0).toDouble())}',
                              icon: Icons.attach_money,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DashboardCard(
                              title: l10n.salesCount,
                              value: '${stats['salesCount'] ?? 0}',
                              icon: Icons.shopping_cart,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Text(
                        l10n.todaysSalesBySalesman,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (salesProvider.todaySalesData.isEmpty)
                        Text(l10n.noSalesToday)
                      else
                        Column(
                          children: salesProvider.todaySalesData.map((salesData) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(salesData.salesmanName ?? l10n.unknownSalesman),
                                trailing: Text(
                                  '$currencySymbol${currency.format(salesData.totalAmount)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 24),
                      Text(
                        l10n.salesTrend,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: DashboardChart(
                          data: stats['salesByDay'] ?? [],
                          emptyText: l10n.noData,
                          currencySymbol: currencySymbol,
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        l10n.topSellingItems,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (((stats['topItems'] as List?)?.isEmpty ?? true))
                        Text(l10n.noItemsFound)
                      else
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
                                subtitle: Text('${l10n.quantityLabel}: ${item['totalQuantity']}'),
                                trailing: Text(
                                  '$currencySymbol${currency.format((item['totalAmount'] ?? 0).toDouble())}',
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
            actions: const [
              LanguageSelector(),
            ],
          ),
          drawer: _buildDrawer(),
          body: _getScreen(),
        );
      },
    );
  }

  Widget _buildDrawer() {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              l10n.menu,
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text(l10n.dashboard),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.summarize),
            title: Text(l10n.summary),
            selected: _selectedIndex == 9,
            onTap: () {
              setState(() {
                _selectedIndex = 9;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.shop),
            title: Text(l10n.shops),
            selected: _selectedIndex == 8,
            onTap: () {
              setState(() {
                _selectedIndex = 8;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text(l10n.salesPerson),
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
            title: Text(l10n.categories),
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
            title: Text(l10n.items),
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
            title: Text(l10n.storedItems),
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
            title: Text(l10n.availableItems),
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
            title: Text(l10n.sales),
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
            title: Text(l10n.subscription),
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
            title: Text(l10n.logout),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
