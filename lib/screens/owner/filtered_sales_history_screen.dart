import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/screens/owner/sale_detail_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class FilteredSalesHistoryScreen extends StatefulWidget {
  final String itemId;
  final String? fractionId;
  final DateTime start;
  final DateTime end;

  const FilteredSalesHistoryScreen({
    super.key,
    required this.itemId,
    this.fractionId,
    required this.start,
    required this.end,
  });

  @override
  State<FilteredSalesHistoryScreen> createState() => _FilteredSalesHistoryScreenState();
}

class _FilteredSalesHistoryScreenState extends State<FilteredSalesHistoryScreen> {
  final Map<String, String> _selectedFractionIds = {};
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
      await context.read<SalesProvider>().fetchSales();
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewSaleDetails(int index, List sales) {
    final sale = sales[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaleDetailScreen(sale: sale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final endInclusive = DateTime(widget.end.year, widget.end.month, widget.end.day, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.sales} (${DateFormat('yyyy-MM-dd').format(widget.start)} - ${DateFormat('yyyy-MM-dd').format(widget.end)})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSales,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SalesProvider>(
              builder: (context, salesProvider, child) {
                final filtered = salesProvider.sales.where((s) {
                  if (s.itemId != widget.itemId) return false;
                  if (widget.fractionId != null && s.fractionId != widget.fractionId) return false;
                  if (s.createdAt.isBefore(widget.start)) return false;
                  if (s.createdAt.isAfter(endInclusive)) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text(l10n.noSalesFound));
                }

                return RefreshIndicator(
                  onRefresh: _loadSales,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final sale = filtered[index];
                      final itemFractions = sale.item?.fractions ?? <Fraction>[];
                      final selectedFractionId = _selectedFractionIds[sale.id] ?? sale.fractionId;
                      final selectedFraction = itemFractions.isNotEmpty
                          ? itemFractions.firstWhere(
                              (f) => f.id == selectedFractionId,
                              orElse: () => itemFractions.first,
                            )
                          : Fraction(
                              id: '',
                              name: '',
                              ratio: 1,
                              sellingPrice: 0,
                              purchasePrice: 0,
                              itemId: '',
                            );

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(sale.item?.name ?? l10n.unknownItem),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${sale.item?.name} (${sale.salesman?.name ?? l10n.unknownSalesman})'),
                              Text(
                                l10n.quantityWithUnit(
                                  (sale.quantity * (sale.fraction?.ratio ?? selectedFraction.ratio) / selectedFraction.ratio).toString(),
                                  selectedFraction.name,
                                ),
                              ),
                              Text(
                                l10n.amountWithCurrency(
                                  (sale.quantity * selectedFraction.sellingPrice).toStringAsFixed(2),
                                ),
                              ),
                              if (sale.profit != null)
                                Text(
                                  'Profit: ${l10n.currencySymbol}${sale.profit!.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              Text(
                                l10n.dateWithFormat(
                                  dateFormat.format(sale.createdAt),
                                ),
                              ),
                            ],
                          ),
                          trailing: itemFractions.isNotEmpty
                              ? DropdownButton<String>(
                                  value: selectedFractionId,
                                  items: itemFractions.map((fraction) {
                                    return DropdownMenuItem<String>(
                                      value: fraction.id,
                                      child: Text(fraction.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value != null) {
                                        _selectedFractionIds[sale.id] = value;
                                      }
                                    });
                                  },
                                )
                              : null,
                          onTap: () => _viewSaleDetails(index, filtered),
                          isThreeLine: true,
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


