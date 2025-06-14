import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/business.dart';
import 'package:inventory_frontend/utils/api.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';

class BusinessDetailScreen extends StatefulWidget {
  final Business business;
  
  const BusinessDetailScreen({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _stats = {};
  
  @override
  void initState() {
    super.initState();
    _loadBusinessStats();
  }
  
  Future<void> _loadBusinessStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await Api.get('businesses/${widget.business.id}/stats');
      
      setState(() {
        _stats = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updateSubscription(String status) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await Api.put('businesses/${widget.business.id}/subscription', {
        'status': status,
      });
      
      // Refresh business data
      final response = await Api.get('businesses/${widget.business.id}');
      final updatedBusiness = Business.fromJson(response);
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription status updated to $status'))
      );
      
      // Return to previous screen with updated business
      Navigator.of(context).pop(updatedBusiness);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $_error'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(business.name),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Business Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('ID', business.id),
                        _buildInfoRow('Name', business.name),
          
                        _buildInfoRow('Active', business.isActive ? 'Yes' : 'No'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subscription Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Plan', business.subscriptionPlan),
                        _buildInfoRow('Status', business.subscriptionStatus),
                        if (business.trialEndsAt != null)
                          _buildInfoRow('Trial Ends', _formatDate(business.trialEndsAt!)),
                        if (business.subscriptionEndsAt != null)
                          _buildInfoRow('Subscription Ends', _formatDate(business.subscriptionEndsAt!)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Activate',
                                onPressed: () => _updateSubscription('active'),
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomButton(
                                text: 'Suspend',
                                onPressed: () => _updateSubscription('expired'),
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomButton(
                                text: 'Cancel',
                                onPressed: () => _updateSubscription('cancelled'),
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Center(child: Text('Error loading stats: $_error'))
                else if (_stats.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Business Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Users', _stats['userCount']?.toString() ?? '0'),
                          _buildInfoRow('Items', _stats['itemCount']?.toString() ?? '0'),
                          _buildInfoRow('Total Sales', '\$${_stats['totalSales']?.toString() ?? '0'}'),
                          _buildInfoRow('Sales Count', _stats['salesCount']?.toString() ?? '0'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 