import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/business.dart';
import 'package:inventory_frontend/providers/business_provider.dart';
import 'package:inventory_frontend/screens/admin/business_detail_screen.dart';
import 'package:inventory_frontend/utils/api.dart';

class BusinessesScreen extends StatefulWidget {
  const BusinessesScreen({Key? key}) : super(key: key);

  @override
  State<BusinessesScreen> createState() => _BusinessesScreenState();
}

class _BusinessesScreenState extends State<BusinessesScreen> {
  List<Business> _businesses = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }
  
  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await Api.get('businesses');
      
      setState(() {
        _businesses = List<Business>.from(
          response.map((x) => Business.fromJson(x))
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _viewBusinessDetails(Business business) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessDetailScreen(business: business),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBusinesses,
        child: _isLoading
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
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(business.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${business.email ?? 'N/A'}'),
                            Text('Plan: ${business.subscriptionPlan}'),
                            Text('Status: ${business.subscriptionStatus}'),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () => _viewBusinessDetails(business),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
