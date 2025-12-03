import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/screens/owner/boughts_screen.dart';
import 'package:inventory_frontend/screens/owner/filtered_sales_history_screen.dart';
import 'package:inventory_frontend/models/bought.dart';
import 'package:inventory_frontend/models/sold_item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/providers/bought_provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  final Map<String, String> _selectedUnitIds = {}; // key: itemId_fractionId -> fractionId

  @override
  void initState() {
    super.initState();
    _initDates();
    _loadData();
  }

  void _initDates() {
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day);
    _startDate = _endDate!.subtract(const Duration(days: 7));
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        context.read<BoughtProvider>().fetchBoughts(),
        context.read<SalesProvider>().fetchSales(),
      ]);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickStartDate() async {
    final initial = _startDate ?? DateTime.now();
    final first = DateTime(initial.year - 1);
    final last = _endDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final initial = _endDate ?? DateTime.now();
    final first = _startDate ?? DateTime(initial.year - 1);
    final last = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<BoughtProvider, SalesProvider>(
              builder: (context, boughtProvider, salesProvider, child) {
                final start = _startDate;
                final end = _endDate;

                if (start == null || end == null) {
                  return const Center(child: Text('Please select a date range'));
                }

                final summaries = _buildItemSummaries(
                  boughtProvider.boughts,
                  salesProvider.sales,
                  start,
                  end,
                );

                if (summaries.isEmpty) {
                  return const Center(child: Text('No data for selected period'));
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickStartDate,
                                icon: const Icon(Icons.date_range),
                                label: Text('From: ${dateFormat.format(start)}'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickEndDate,
                                icon: const Icon(Icons.date_range),
                                label: Text('To:   ${dateFormat.format(end)}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Item')),
                                DataColumn(label: Text('Unit')),
                                DataColumn(label: Text('Prev Qty')),
                                DataColumn(label: Text('Bought')),
                                DataColumn(label: Text('Sold')),
                                DataColumn(label: Text('Remaining')),
                                DataColumn(label: Text('Profit')),
                              ],
                              rows: summaries.map((s) {
                                final key = '${s.itemId}_${s.baseFractionId}';
                                final fractions = s.fractions.isNotEmpty
                                    ? s.fractions
                                    : <Fraction>[
                                        Fraction(
                                          id: s.baseFractionId,
                                          name: s.fractionName,
                                          ratio: s.baseRatio,
                                          sellingPrice: 0,
                                          purchasePrice: 0,
                                          itemId: s.itemId,
                                        ),
                                      ];
                                final selectedUnitId = _selectedUnitIds[key] ?? s.baseFractionId;
                                final selectedFraction = fractions.firstWhere(
                                  (f) => f.id == selectedUnitId,
                                  orElse: () => fractions.first,
                                );
                                final ratioFactor = s.baseRatio / selectedFraction.ratio;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(s.itemName)),
                                    DataCell(
                                      DropdownButton<String>(
                                        value: selectedUnitId,
                                        items: fractions.map((f) {
                                          return DropdownMenuItem<String>(
                                            value: f.id,
                                            child: Text(f.name),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() {
                                            _selectedUnitIds[key] = value;
                                          });
                                        },
                                      ),
                                    ),
                                    DataCell(Text((s.previousQuantity * ratioFactor).toStringAsFixed(2))),
                                    DataCell(
                                      Text((s.boughtInPeriod * ratioFactor).toStringAsFixed(2)),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => BoughtsScreen(
                                              filterItemId: s.itemId,
                                              filterFractionId: s.baseFractionId,
                                              filterStart: start,
                                              filterEnd: end,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    DataCell(
                                      Text((s.soldInPeriod * ratioFactor).toStringAsFixed(2)),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => FilteredSalesHistoryScreen(
                                              itemId: s.itemId,
                                              fractionId: s.baseFractionId,
                                              start: start,
                                              end: end,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    DataCell(Text((s.remainingNow * ratioFactor).toStringAsFixed(2))),
                                    DataCell(Text(s.profitInPeriod.toStringAsFixed(2))),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  List<_ItemSummary> _buildItemSummaries(
    List<Bought> boughts,
    List<SoldItem> sales,
    DateTime start,
    DateTime end,
  ) {
    // Normalize end to end-of-day
    final endInclusive = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final Map<String, _ItemSummaryAccumulator> acc = {};

    _ItemSummaryAccumulator forKey(Bought b) {
      final key = '${b.itemId}_${b.fractionId}';
      return acc.putIfAbsent(
        key,
        () => _ItemSummaryAccumulator(
          itemId: b.itemId,
          fractionId: b.fractionId,
          itemName: b.item?.name ?? 'Unknown',
          fractionName: b.fraction?.name ?? 'Unknown',
          baseRatio: b.fraction?.ratio ?? 1,
          fractions: b.item?.fractions ?? const [],
        ),
      );
    }

    _ItemSummaryAccumulator forKeySale(SoldItem s) {
      final key = '${s.itemId}_${s.fractionId}';
      return acc.putIfAbsent(
        key,
        () => _ItemSummaryAccumulator(
          itemId: s.itemId,
          fractionId: s.fractionId,
          itemName: s.item?.name ?? 'Unknown',
          fractionName: s.fraction?.name ?? 'Unknown',
          baseRatio: s.fraction?.ratio ?? 1,
          fractions: s.item?.fractions ?? const [],
        ),
      );
    }

    for (final b in boughts) {
      final a = forKey(b);
      final t = b.createdTime;
      if (t.isBefore(start)) {
        a.totalBoughtBefore += b.quantity;
      }
      if (!t.isBefore(start) && !t.isAfter(endInclusive)) {
        a.boughtInPeriod += b.quantity;
      }
      a.totalBoughtAll += b.quantity;
    }

    for (final s in sales) {
      final a = forKeySale(s);
      final t = s.createdAt;
      if (t.isBefore(start)) {
        a.totalSoldBefore += s.quantity;
      }
      if (!t.isBefore(start) && !t.isAfter(endInclusive)) {
        a.soldInPeriod += s.quantity;
        a.profitInPeriod += s.profit ?? 0;
      }
      a.totalSoldAll += s.quantity;
    }

    return acc.values.map((a) {
      final previous = a.totalBoughtBefore - a.totalSoldBefore;
      final remaining = a.totalBoughtAll - a.totalSoldAll;
      return _ItemSummary(
        itemId: a.itemId,
        baseFractionId: a.fractionId,
        itemName: a.itemName,
        fractionName: a.fractionName,
        baseRatio: a.baseRatio,
        fractions: a.fractions,
        previousQuantity: previous,
        boughtInPeriod: a.boughtInPeriod,
        soldInPeriod: a.soldInPeriod,
        remainingNow: remaining,
        profitInPeriod: a.profitInPeriod,
      );
    }).toList()
      ..sort((a, b) => a.itemName.compareTo(b.itemName));
  }
}

class _ItemSummaryAccumulator {
  final String itemId;
  final String fractionId;
  final String itemName;
  final String fractionName;
  double baseRatio;
  List<Fraction> fractions;

  double totalBoughtBefore = 0;
  double totalSoldBefore = 0;
  double boughtInPeriod = 0;
  double soldInPeriod = 0;
  double totalBoughtAll = 0;
  double totalSoldAll = 0;
  double profitInPeriod = 0;

  _ItemSummaryAccumulator({
    required this.itemId,
    required this.fractionId,
    required this.itemName,
    required this.fractionName,
    required this.baseRatio,
    required this.fractions,
  });
}

class _ItemSummary {
  final String itemId;
  final String baseFractionId;
  final String itemName;
  final String fractionName;
  final double baseRatio;
  final List<Fraction> fractions;
  final double previousQuantity;
  final double boughtInPeriod;
  final double soldInPeriod;
  final double remainingNow;
  final double profitInPeriod;

  _ItemSummary({
    required this.itemId,
    required this.baseFractionId,
    required this.itemName,
    required this.fractionName,
    required this.baseRatio,
    required this.fractions,
    required this.previousQuantity,
    required this.boughtInPeriod,
    required this.soldInPeriod,
    required this.remainingNow,
    required this.profitInPeriod,
  });
}


