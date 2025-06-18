import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:inventory_frontend/providers/shop_provider.dart';
import 'package:inventory_frontend/models/shop.dart';
import 'package:inventory_frontend/models/user.dart';

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;

  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableSalespeople();
  }

  Future<void> _loadAvailableSalespeople() async {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    await shopProvider.getAvailableSalespeople();
  }

  Future<void> _assignSalesperson(User salesperson) async {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final success = await shopProvider.assignSalespersonToShop(
      widget.shop.id,
      salesperson.id,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${salesperson.name} assigned to ${widget.shop.name}'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shopProvider.error ?? 'Failed to assign salesperson'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeSalesperson(User salesperson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Salesperson'),
        content: Text('Are you sure you want to remove ${salesperson.name} from ${widget.shop.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
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
            content: Text('${salesperson.name} removed from ${widget.shop.name}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shopProvider.error ?? 'Failed to remove salesperson'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAssignSalespersonDialog() {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final availableSalespeople = shopProvider.availableSalespeople;

    if (availableSalespeople.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available salespeople to assign'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Salesperson'),
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
            child: const Text('Cancel'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 30,
                          child: Icon(
                            Icons.store,
                            size: 30,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.shop.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.shop.address,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Created: ${widget.shop.createdAt.toString().split(' ')[0]}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Salespeople Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Salespeople',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: _showAssignSalespersonDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Consumer<ShopProvider>(
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
                            'No salespeople assigned',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Assign salespeople to this shop to get started',
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
          ],
        ),
      ),
    );
  }
} 