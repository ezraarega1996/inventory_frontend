import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/item.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/screens/salesman/item_detail_screen.dart';

class ViewItemsScreen extends StatefulWidget {
  const ViewItemsScreen({Key? key}) : super(key: key);

  @override
  State<ViewItemsScreen> createState() => _ViewItemsScreenState();
}

class _ViewItemsScreenState extends State<ViewItemsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadItems();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadItems() async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    await itemProvider.fetchItems();
  }
  
  void _viewItemDetails(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    
    final filteredItems = itemProvider.items.where((item) {
      final name = item.name.toLowerCase();
      final category = item.category?.name.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || category.contains(query);
    }).toList();
    
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Items',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadItems,
              child: itemProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                  ? const Center(child: Text('No items found'))
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text(item.category?.name ?? 'No category'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _viewItemDetails(item),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
