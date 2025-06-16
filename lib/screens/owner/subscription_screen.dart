import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/business_provider.dart';
import 'package:inventory_frontend/utils/theme.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final businessProvider = context.read<BusinessProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      if (authProvider.user?.businessId != null) {
        await businessProvider.loadCurrentBusiness(
          authProvider.user!.businessId!,
        );
      }

      await businessProvider.loadSubscriptionPlans();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _upgradePlan(String planName) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final businessProvider = context.read<BusinessProvider>();
      final checkoutUrl = await businessProvider.createCheckoutSession(
        planName,
      );

      if (checkoutUrl != null) {
        await url_launcher.launchUrl(
          Uri.parse(checkoutUrl),
          mode: url_launcher.LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              businessProvider.error ?? 'Failed to create checkout session',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upgrade plan: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer2<BusinessProvider, AuthProvider>(
                builder: (context, businessProvider, authProvider, child) {
                  final business = businessProvider.currentBusiness;
                  final plans = businessProvider.subscriptionPlans;

                  return RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (business != null) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Subscription',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Business', business.name),
                                    _buildInfoRow(
                                      'Plan',
                                      plans[business.subscriptionPlan]
                                              ?.displayName ??
                                          business.subscriptionPlan,
                                    ),
                                    _buildInfoRow(
                                      'Status',
                                      _formatStatus(
                                        business.subscriptionStatus,
                                      ),
                                    ),
                                    if (business.subscriptionStatus == 'trial')
                                      _buildInfoRow(
                                        'Trial Ends',
                                        _formatDate(business.trialEndsAt),
                                      ),
                                    if (business.subscriptionStatus == 'active')
                                      _buildInfoRow(
                                        'Subscription Ends',
                                        _formatDate(
                                          business.subscriptionEndsAt,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          const Text(
                            'Available Plans',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (plans.isEmpty)
                            const Center(
                              child: Text('No subscription plans available'),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: plans.length,
                              itemBuilder: (context, index) {
                                final planName = plans.keys.elementAt(index);
                                final plan = plans[planName]!;
                                final isCurrentPlan =
                                    business?.subscriptionPlan == planName;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              plan.displayName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (isCurrentPlan)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: const Text(
                                                  'Current Plan',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          plan.price > 0
                                              ? '${plan.price} ETB/${plan.currency}/month'
                                              : 'Free',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Features:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...plan.features.map(
                                          (feature) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: AppTheme.successColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text(feature)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        if (!isCurrentPlan)
                                          CustomButton(
                                            text:
                                                plan.price > 0
                                                    ? 'Upgrade to ${plan.displayName}'
                                                    : 'Switch to Free Plan',
                                            onPressed:
                                                () => _upgradePlan(planName),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'trial':
        return 'Trial';
      case 'active':
        return 'Active';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
