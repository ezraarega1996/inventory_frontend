import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/models/bought.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/sold_item.dart';
import 'package:inventory_frontend/providers/bought_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/screens/owner/sale_detail_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final Map<String, String> _selectedFractionIds = {}; // boughtId -> fractionId
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }
  
  Future<void> _loadSales() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    await Future.wait([
      context.read<SalesProvider>().fetchSales(),
      context.read<BoughtProvider>().fetchBoughts(),
    ]);
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }
  
  Future<void> _deleteSale(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSaleTitle),
        content: Text(l10n.deleteSaleContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final salesProvider = context.read<SalesProvider>();
      final success = await salesProvider.deleteSale(id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saleDeletedSuccess))
        );
        await _loadSales();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(salesProvider.error ?? l10n.error))
        );
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
        title: Text(l10n.sales),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    tabs: [
                      Tab(text: l10n.sales),
                      const Tab(text: 'Summary'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSalesList(l10n),
                        _buildSummaryTab(l10n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSalesList(AppLocalizations l10n) {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, child) {
        if (salesProvider.sales.isEmpty) {
          return Center(child: Text(l10n.noSalesFound));
        }
        return RefreshIndicator(
          onRefresh: _loadSales,
          child: ListView.builder(
            itemCount: salesProvider.sales.length,
            itemBuilder: (context, index) {
              final sale = salesProvider.sales[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    // Default to the fraction used in the sale
                    String selectedFractionId =
                        _selectedFractionIds[sale.id] ?? sale.fractionId;

                    final itemFractions = sale.item?.fractions ?? <Fraction>[];
                    final Fraction selectedFraction = itemFractions.isNotEmpty
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
                    return ListTile(
                      subtitle: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${sale.item?.name}(${sale.salesman?.name ?? l10n.unknownSalesman})'),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${l10n.quantityLabel}: ${sale.quantity * (sale.fraction?.ratio ?? selectedFraction.ratio) / selectedFraction.ratio} ${selectedFraction.name}',
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.amountLabel +
                                                ': ${l10n.currencySymbol}${sale.quantity * selectedFraction.sellingPrice}',
                                          ),
                                          if (sale.profit != null)
                                            Text(
                                              'Profit: ${l10n.currencySymbol}${sale.profit!.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: sale.available_items_count != null
                                          ? Text(
                                              l10n.availableLabel +
                                                  ': ${sale.available_items_count! * (sale.fraction?.ratio ?? selectedFraction.ratio) / selectedFraction.ratio} ${selectedFraction.name}',
                                            )
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(l10n.dateLabel + ': ${DateFormat('MMM dd, yyyy HH:mm').format(sale.createdAt)}'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (itemFractions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteSale(sale.id);
                                  } else {
                                    setState(() {
                                      _selectedFractionIds[sale.id] = value;
                                    });
                                  }
                                },
                                itemBuilder: (context) => [
                                  ...itemFractions.map((fraction) => PopupMenuItem<String>(
                                    value: fraction.id,
                                    child: Text(l10n.viewAs(fraction.name)),
                                  )),
                                  const PopupMenuDivider(),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text(l10n.delete, style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      onTap: () => _viewSaleDetails(index),
                      isThreeLine: true,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(AppLocalizations l10n) {
    return Consumer2<SalesProvider, BoughtProvider>(
      builder: (context, salesProvider, boughtProvider, child) {
        final summaries = _buildTransactionSummaries(
          boughtProvider.boughts,
          salesProvider.sales,
        );

        if (summaries.isEmpty) {
          return Center(child: Text('No transaction summary yet.'));
        }

        final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

        return RefreshIndicator(
          onRefresh: _loadSales,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('Fraction')),
                  DataColumn(label: Text('Prev Qty')),
                  DataColumn(label: Text('Bought')),
                  DataColumn(label: Text('Sold')),
                  DataColumn(label: Text('Remaining')),
                  DataColumn(label: Text('Profit')),
                ],
                rows: summaries.map((summary) {
                  return DataRow(
                    cells: [
                      DataCell(Text(dateFormat.format(summary.date))),
                      DataCell(Text(summary.itemName)),
                      DataCell(Text(summary.fractionName)),
                      DataCell(Text(summary.previousQuantity.toStringAsFixed(2))),
                      DataCell(Text(summary.boughtQuantity.toStringAsFixed(2))),
                      DataCell(Text(summary.soldQuantity.toStringAsFixed(2))),
                      DataCell(Text(summary.remainingQuantity.toStringAsFixed(2))),
                      DataCell(
                        summary.profit != null
                            ? Text('${l10n.currencySymbol}${summary.profit!.toStringAsFixed(2)}')
                            : const Text('-'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  List<_TransactionSummary> _buildTransactionSummaries(
    List<Bought> boughts,
    List<SoldItem> sales,
  ) {
    final events = <_TransactionEvent>[];

    for (final bought in boughts) {
      events.add(_TransactionEvent(
        date: bought.createdTime,
        itemId: bought.itemId,
        fractionId: bought.fractionId,
        itemName: bought.item?.name ?? 'Unknown',
        fractionName: bought.fraction?.name ?? 'Unknown',
        quantity: bought.quantity,
        profit: null,
        type: _TransactionType.bought,
      ));
    }

    for (final sale in sales) {
      events.add(_TransactionEvent(
        date: sale.createdAt,
        itemId: sale.itemId,
        fractionId: sale.fractionId,
        itemName: sale.item?.name ?? 'Unknown',
        fractionName: sale.fraction?.name ?? 'Unknown',
        quantity: sale.quantity,
        profit: sale.profit,
        type: _TransactionType.sold,
      ));
    }

    events.sort((a, b) => a.date.compareTo(b.date));

    final stockTracker = <String, double>{};
    final summaries = <_TransactionSummary>[];

    for (final event in events) {
      final key = '${event.itemId}_${event.fractionId}';
      final previous = stockTracker[key] ?? 0;
      double boughtQty = 0;
      double soldQty = 0;
      double? profit;

      if (event.type == _TransactionType.bought) {
        boughtQty = event.quantity;
        stockTracker[key] = previous + boughtQty;
      } else {
        soldQty = event.quantity;
        stockTracker[key] = previous - soldQty;
        profit = event.profit;
      }

      final remaining = stockTracker[key] ?? 0;

      summaries.add(_TransactionSummary(
        date: event.date,
        itemName: event.itemName,
        fractionName: event.fractionName,
        previousQuantity: previous,
        boughtQuantity: boughtQty,
        soldQuantity: soldQty,
        remainingQuantity: remaining,
        profit: profit,
      ));
    }

    return summaries;
  }
}

enum _TransactionType { bought, sold }

class _TransactionEvent {
  final DateTime date;
  final String itemId;
  final String fractionId;
  final String itemName;
  final String fractionName;
  final double quantity;
  final double? profit;
  final _TransactionType type;

  _TransactionEvent({
    required this.date,
    required this.itemId,
    required this.fractionId,
    required this.itemName,
    required this.fractionName,
    required this.quantity,
    required this.profit,
    required this.type,
  });
}

class _TransactionSummary {
  final DateTime date;
  final String itemName;
  final String fractionName;
  final double previousQuantity;
  final double boughtQuantity;
  final double soldQuantity;
  final double remainingQuantity;
  final double? profit;

  _TransactionSummary({
    required this.date,
    required this.itemName,
    required this.fractionName,
    required this.previousQuantity,
    required this.boughtQuantity,
    required this.soldQuantity,
    required this.remainingQuantity,
    required this.profit,
  });
}
