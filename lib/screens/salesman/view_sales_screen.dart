import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/screens/salesman/sale_detail_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ViewSalesScreen extends StatefulWidget {
  const ViewSalesScreen({Key? key}) : super(key: key);

  @override
  State<ViewSalesScreen> createState() => _ViewSalesScreenState();
}

class _ViewSalesScreenState extends State<ViewSalesScreen> {
  final Map<String, String> _selectedFractionIds = {}; // saleId -> fractionId
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }
  
  Future<void> _loadSales() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final salesProvider = context.read<SalesProvider>();
      await salesProvider.fetchUserSales();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sales: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _viewSaleDetails(int index) {
    final salesProvider = context.read<SalesProvider>();
    final sale = salesProvider.sales[index];
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaleDetailScreen(sale: sale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              // ignore: unawaited_futures
              _loadSales();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SalesProvider>(
              builder: (context, salesProvider, child) {
                final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
                final today = DateTime.now();

                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadSales,
                      child: salesProvider.sales.isEmpty
                          ? Center(child: Text(l10n.noSalesFound))
                          : ListView.builder(
                              itemCount: salesProvider.sales.length,
                              itemBuilder: (context, index) {
                                final sale = salesProvider.sales[index];
                                final itemFractions = sale.item?.fractions ?? [];
                                String selectedFractionId = _selectedFractionIds[sale.id] ?? sale.fraction?.id ?? '';
                                Fraction? selectedFraction = itemFractions.firstWhere(
                                  (f) => f.id == selectedFractionId,
                                );
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    title: Text(sale.item?.name ?? l10n.unknownItem),
                                    subtitle: Row(    
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Sale details on the left
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${sale.item?.name}(${sale.salesman?.name ?? 'Unknown Salesman'})'),
                                              Text(l10n.quantityWithUnit(
                                                (sale.quantity * sale.fraction!.ratio / selectedFraction!.ratio).toString(),
                                                selectedFraction?.name ?? ""
                                              )),
                                              Text(l10n.amountWithCurrency(sale.soldPrice.toString())),
                                              sale.available_items_count != null
                                                ? Text(l10n.availableItemsWithUnit(
                                                    (sale.available_items_count! * sale.fraction!.ratio / selectedFraction!.ratio).toString(),
                                                    selectedFraction?.name ?? ""
                                                  ))
                                                : const SizedBox.shrink(),
                                              Text(l10n.dateWithFormat(dateFormat.format(sale.createdAt))),
                                            ],
                                          ),
                                        ),
                                        // Dropdown on the right
                                        if ((sale.item?.fractions ?? []).isNotEmpty)
                                          Expanded(
                                            flex: 1,
                                            child: Align(
                                              alignment: Alignment.topRight,
                                              child: DropdownButton<String>(
                                                value: selectedFractionId,
                                                items: sale.item!.fractions!.map((fraction) {
                                                  return DropdownMenuItem<String>(
                                                    value: fraction.id,
                                                    child: Text(fraction.name),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedFractionIds[sale.id] = value!;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios),
                                    onTap: () => _viewSaleDetails(index),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
