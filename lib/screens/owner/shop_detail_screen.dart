import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:inventory_frontend/providers/shop_provider.dart';
import 'package:inventory_frontend/models/shop.dart';
import 'package:inventory_frontend/models/user.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/widgets/fraction_dropdown.dart';
import 'package:inventory_frontend/screens/available_items_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;

  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailableSalespeople();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSalespeople() async {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    await shopProvider.getAvailableSalespeople();
  }

  Future<void> _assignSalesperson(User salesperson) async {
    final l10n = AppLocalizations.of(context)!;
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final success = await shopProvider.assignSalespersonToShop(
      widget.shop.id,
      salesperson.id,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.salespersonAssigned(salesperson.name, widget.shop.name)),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shopProvider.error ?? l10n.failedToAssignSalesperson),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeSalesperson(User salesperson) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeSalespersonTitle),
        content: Text(l10n.removeSalespersonContent(salesperson.name, widget.shop.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final success = await shopProvider.removeSalespersonFromShop(
        widget.shop.id,
        salesperson.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.salespersonRemoved(salesperson.name, widget.shop.name)),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shopProvider.error ?? l10n.failedToRemoveSalesperson),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAssignSalespersonDialog() {
    final l10n = AppLocalizations.of(context)!;
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final availableSalespeople = shopProvider.availableSalespeople;

    if (availableSalespeople.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noAvailableSalespeople),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.assignSalespersonTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableSalespeople.length,
            itemBuilder: (context, index) {
              final salesperson = availableSalespeople[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    salesperson.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(salesperson.name),
                subtitle: Text(salesperson.phone),
                onTap: () {
                  Navigator.pop(context);
                  _assignSalesperson(salesperson);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shop.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              _loadAvailableSalespeople();
              setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Information Card
            const SizedBox(height: 24),
            // TabBar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.salespeopleTab, icon: const Icon(Icons.people)),
                Tab(text: l10n.availableItemsTab, icon: const Icon(Icons.inventory_2)),
              ],
            ),
            const SizedBox(height: 16),
            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSalespeopleTab(context),
                  AvailableItemsScreen(shopId: widget.shop.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalespeopleTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.salespeopleTab,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            ElevatedButton.icon(
              onPressed: _showAssignSalespersonDialog,
              icon: const Icon(Icons.person_add),
              label: Text(l10n.assignLabel),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer<ShopProvider>(
            builder: (context, shopProvider, child) {
              final currentShop = shopProvider.shops.firstWhere(
                (shop) => shop.id == widget.shop.id,
                orElse: () => widget.shop,
              );
              final salespeople = currentShop.salespeople ?? [];

              if (salespeople.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noSalespeopleAssigned,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.assignSalespeopleToShop,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: salespeople.length,
                itemBuilder: (context, index) {
                  final salesperson = salespeople[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          salesperson.name[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(salesperson.name),
                      subtitle: Text(salesperson.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _removeSalesperson(salesperson),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}