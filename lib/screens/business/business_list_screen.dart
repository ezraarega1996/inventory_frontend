import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/business.dart';
import 'package:inventory_frontend/services/business_service.dart';
import 'package:inventory_frontend/screens/business/business_detail_screen.dart';

class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({super.key});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  List<Business> _businesses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    try {
      final businessService = Provider.of<BusinessService>(context, listen: false);
      final businesses = await businessService.getAllBusinesses();
      setState(() {
        _businesses = businesses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Businesses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBusinesses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _businesses.isEmpty
                  ? const Center(child: Text('No businesses found'))
                  : ListView.builder(
                      itemCount: _businesses.length,
                      itemBuilder: (context, index) {
                        final business = _businesses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: business.logo != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(business.logo!),
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.business),
                                  ),
                            title: Text(business.name),
                            subtitle: Text(
                              '${business.subscriptionPlan} - ${business.subscriptionStatus}',
                            ),
                            trailing: Icon(
                              business.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: business.isActive
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BusinessDetailScreen(
                                    business: business,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
} 