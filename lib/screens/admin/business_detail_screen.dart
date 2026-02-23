import 'package:flutter/material.dart';
import 'package:inventory_frontend/models/business.dart';
import 'package:inventory_frontend/utils/api.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BusinessDetailScreen extends StatefulWidget {
  final Business business;
  
  const BusinessDetailScreen({
    super.key,
    required this.business,
  });

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
    final l10n = AppLocalizations.of(context)!;
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
        SnackBar(content: Text(l10n.subscriptionStatusUpdatedTo(status)))
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
        SnackBar(content: Text(l10n.errorWithDetails(_error ?? '')))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                        Text(
                          l10n.businessInformation,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(l10n.idLabel, business.id),
                        _buildInfoRow(l10n.nameLabel, business.name),
                        _buildInfoRow(l10n.emailLabel, business.email ?? l10n.na),
                        _buildInfoRow(l10n.phoneLabel, business.phone ?? l10n.na),
                        _buildInfoRow(l10n.addressLabel, business.address ?? l10n.na),
                        _buildInfoRow(l10n.activeLabel, business.isActive ? l10n.yes : l10n.no),
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
                        Text(
                          l10n.subscriptionInformation,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(l10n.planLabel, business.subscriptionPlan),
                        _buildInfoRow(l10n.statusLabel, business.subscriptionStatus),
                        if (business.trialEndsAt != null)
                          _buildInfoRow(l10n.trialEndsLabel, _formatDate(business.trialEndsAt!)),
                        if (business.subscriptionEndsAt != null)
                          _buildInfoRow(l10n.subscriptionEndsLabel, _formatDate(business.subscriptionEndsAt!)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: l10n.activate,
                                onPressed: () => _updateSubscription('active'),
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomButton(
                                text: l10n.suspend,
                                onPressed: () => _updateSubscription('expired'),
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomButton(
                                text: l10n.cancelSubscription,
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
                  Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.errorLoadingData(_error ?? ''),
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.businessStatistics,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(l10n.users, _stats['userCount']?.toString() ?? '0'),
                          _buildInfoRow(l10n.items, _stats['itemCount']?.toString() ?? '0'),
                          _buildInfoRow(l10n.totalSales, '\$${_stats['totalSales']?.toString() ?? '0'}'),
                          _buildInfoRow(l10n.salesCount, _stats['salesCount']?.toString() ?? '0'),
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