import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:inventory_frontend/providers/shop_provider.dart';
import 'package:inventory_frontend/models/shop.dart';
import 'package:inventory_frontend/screens/owner/shop_detail_screen.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  bool _isLoading = false;
  bool _showRegistrationForm = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
    });

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    await shopProvider.getShops();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createShop() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isSubmitting = true; });

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final success = await shopProvider.createShop(
      _nameController.text.trim(),
      _addressController.text.trim(),
    );

    setState(() { _isSubmitting = false; });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shopCreatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form and hide it
        _nameController.clear();
        _addressController.clear();
        setState(() {
          _showRegistrationForm = false;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shopProvider.error ?? l10n.shopCreatedFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteShop(Shop shop) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteShopTitle),
        content: Text(l10n.deleteShopContent(shop.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final success = await shopProvider.deleteShop(shop.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shopDeletedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shopProvider.error ?? l10n.shopDeletedFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shops),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadShops,
          ),
        ],
      ),
      body: Column(
        children: [
          // Registration Form Section
          if (_showRegistrationForm)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.blue.shade200),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.createNewShop,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showRegistrationForm = false;
                              _nameController.clear();
                              _addressController.clear();
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _nameController,
                      labelText: l10n.shopNameLabel,
                      hintText: l10n.enterShopNameHint,
                      prefixIcon: Icons.store,
                      enabled: !_isSubmitting,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.pleaseEnterShopName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _addressController,
                      labelText: l10n.shopAddressLabel,
                      hintText: l10n.enterShopAddressHint,
                      prefixIcon: Icons.location_on,
                      enabled: !_isSubmitting,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.pleaseEnterShopAddress;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: _isSubmitting ? l10n.processing : l10n.save,
                      onPressed: _isSubmitting ? null : () { _createShop(); },
                      isLoading: _isSubmitting,
                    ),
                  ],
                ),
              ),
            ),
          
          // Shops List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Consumer<ShopProvider>(
                    builder: (context, shopProvider, child) {
                      final shops = shopProvider.shops;
                      
                      if (shops.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No shops found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Create your first shop to get started',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: shops.length,
                        itemBuilder: (context, index) {
                          final shop = shops[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(
                                  Icons.store,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              title: Text(
                                shop.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(shop.address),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${shop.salespeople?.length ?? 0} salespeople',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'view':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ShopDetailScreen(shop: shop),
                                        ),
                                      );
                                      break;
                                    case 'edit':
                                      // TODO: Implement edit shop functionality
                                      break;
                                    case 'delete':
                                      await _deleteShop(shop);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShopDetailScreen(shop: shop),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showRegistrationForm = !_showRegistrationForm;
            if (!_showRegistrationForm) {
              _nameController.clear();
              _addressController.clear();
            }
          });
        },
        child: Icon(_showRegistrationForm ? Icons.close : Icons.add),
      ),
    );
  }
} 