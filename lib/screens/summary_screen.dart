import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/screens/owner/boughts_screen.dart';
import 'package:inventory_frontend/screens/owner/filtered_sales_history_screen.dart';
import 'package:inventory_frontend/models/bought.dart';
import 'package:inventory_frontend/models/sold_item.dart';
import 'package:inventory_frontend/models/fraction.dart';
import 'package:inventory_frontend/models/available_item.dart';
import 'package:inventory_frontend/providers/bought_provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/providers/shop_provider.dart';
import 'package:inventory_frontend/screens/owner/transactions_screen.dart';

class SummaryScreen extends StatefulWidget {
  /// When provided, the screen will lock to this shop and (by default)
  /// hide the shop dropdown so the user cannot switch shops.
  final String? fixedShopId;

  /// Whether the user is allowed to change the selected shop via dropdown.
  /// Owners should use the default (true); salesman usage can set this to false.
  final bool allowShopSwitch;

  const SummaryScreen({
    super.key,
    this.fixedShopId,
    this.allowShopSwitch = true,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  final Map<String, String> _selectedUnitIds = {}; // key: itemId_fractionId -> fractionId
  String? _selectedShopId;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateOrToday(DateTime date, DateFormat fmt) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final d = DateTime(date.year, date.month, date.day);
    return _isSameDay(d, todayDate) ? 'Today' : fmt.format(d);
  }

  double _calcBoughtAmount(
    List<Bought> boughts,
    DateTime start,
    DateTime endInclusive,
  ) {
    return boughts
        .where((b) => !b.createdTime.isBefore(start) && !b.createdTime.isAfter(endInclusive))
        .fold<double>(
          0.0,
          (sum, b) => sum + (b.quantity * b.fractionPurchasePrice),
        );
  }

  double _calcSoldAmount(
    List<SoldItem> sales,
    DateTime start,
    DateTime endInclusive,
  ) {
    return sales
        .where((s) => !s.createdAt.isBefore(start) && !s.createdAt.isAfter(endInclusive))
        .fold<double>(0.0, (sum, s) => sum + s.soldPrice);
  }

  @override
  void initState() {
    super.initState();
    _initDates();
    _loadData();
    _loadShops();
  }

  void _initDates() {
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day);
    _startDate = _endDate!.subtract(const Duration(days: 0));
  }

  Future<void> _loadShops() async {
    try {
      await context.read<ShopProvider>().getShops();
      final shops = context.read<ShopProvider>().shops;
      if (mounted && shops.isNotEmpty && _selectedShopId == null && widget.fixedShopId == null) {
        setState(() {
          _selectedShopId = shops.first.id;
        });
      }
    } catch (_) {
      // Ignore shop loading errors here; ShopProvider already handles error state.
    }
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
        context.read<AvailableItemProvider>().fetchAvailableItems(),
      ]);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<_ItemSummary> _buildSummariesFromAvailableItems(List<AvailableItem> availableItems) {
    return availableItems.map((ai) {
      final fractions = ai.item?.fractions ?? const <Fraction>[];
      final unitFraction = fractions.where((f) => f.isUnit).isNotEmpty
          ? fractions.firstWhere((f) => f.isUnit)
          : (fractions.isNotEmpty ? fractions.first : null);

      final baseFractionId = unitFraction?.id ?? '';
      final baseRatio = unitFraction?.ratio ?? 1;
      final itemName = ai.item?.name ?? 'Unknown';
      final fractionName = unitFraction?.name ?? 'Unit';

      // AvailableItem.quantity is stored in base units in the backend.
      // Convert it into the selected base fraction quantity.
      final baseQuantity = baseRatio == 0 ? 0.0 : (ai.quantity / baseRatio);

      return _ItemSummary(
        itemId: ai.itemId,
        baseFractionId: baseFractionId,
        itemName: itemName,
        fractionName: fractionName,
        baseRatio: baseRatio,
        fractions: fractions,
        previousQuantity: baseQuantity,
        boughtInPeriod: 0,
        boughtAmountInPeriod: 0,
        soldInPeriod: 0,
        soldAmountInPeriod: 0,
        remainingNow: baseQuantity,
        profitInPeriod: 0,
      );
    }).toList()
      ..sort((a, b) => a.itemName.compareTo(b.itemName));
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
    final shopProvider = context.watch<ShopProvider>();
    final shops = shopProvider.shops;
    // If a fixed shopId is provided (e.g. salesman side), always use that.
    final currentShopId = widget.fixedShopId != null && widget.fixedShopId!.isNotEmpty
        ? widget.fixedShopId
        : _selectedShopId ?? (shops.isNotEmpty ? shops.first.id : null);

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
          : Consumer3<BoughtProvider, SalesProvider, AvailableItemProvider>(
              builder: (context, boughtProvider, salesProvider, availableItemProvider, child) {
                final start = _startDate;
                final end = _endDate;

                if (start == null || end == null) {
                  return const Center(child: Text('Please select a date range'));
                }

                // When no fixed shop is provided (owner view), we require shops.
                if (shops.isEmpty && widget.fixedShopId == null) {
                  return const Center(child: Text('No shops available'));
                }

                if (currentShopId == null || currentShopId.isEmpty) {
                  return const Center(child: Text('Please select a shop'));
                }

                final filteredBoughts = boughtProvider.boughts
                    .where((b) => b.shopId == currentShopId)
                    .toList();

                // Sales:
                // - In salesman context (fixedShopId != null), show ONLY sales that
                //   explicitly belong to the salesman’s assigned shop.
                // - In owner context, keep a legacy fallback for older sales that
                //   have no shopId when there is only a single shop.
                final filteredSales = salesProvider.sales.where((s) {
                  // Salesman summary: strict shop match only
                  if (widget.fixedShopId != null) {
                    return s.shopId != null &&
                        s.shopId!.isNotEmpty &&
                        s.shopId == currentShopId;
                  }

                  // Owner summary: prefer explicit shopId match first
                  if (s.shopId != null && s.shopId!.isNotEmpty) {
                    return s.shopId == currentShopId;
                  }

                  // Legacy fallback only for single-shop businesses (owner view)
                  final isSingleShopBusiness =
                      shops.length == 1 && shops.first.id == currentShopId;
                  return isSingleShopBusiness;
                }).toList();

                final availableItemsForShop = availableItemProvider.availableItems.where((ai) {
                  if (widget.fixedShopId != null) {
                    return ai.shopId == currentShopId;
                  }
                  return ai.shopId == currentShopId;
                }).toList();

                final endInclusive = DateTime(end.year, end.month, end.day, 23, 59, 59);
                final totalBoughtAmount = _calcBoughtAmount(filteredBoughts, start, endInclusive);
                final totalSoldAmount = _calcSoldAmount(filteredSales, start, endInclusive);
                final netIncome = totalSoldAmount - totalBoughtAmount;

                final currencyFormat = NumberFormat('#,##0.00');

                final summaries = _buildItemSummaries(
                  filteredBoughts,
                  filteredSales,
                  start,
                  end,
                );

                // If there are no transactions in the selected period, still show inventory rows
                // using current available items so user can see quantities and can change dates.
                final effectiveSummaries = summaries.isNotEmpty
                    ? summaries
                    : (availableItemsForShop.isNotEmpty
                        ? _buildSummariesFromAvailableItems(availableItemsForShop)
                        : <_ItemSummary>[]);

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (shops.isNotEmpty && widget.allowShopSwitch)
                              DropdownButtonFormField<String>(
                                value: currentShopId,
                                decoration: const InputDecoration(
                                  labelText: 'Shop',
                                  border: OutlineInputBorder(),
                                ),
                                items: shops
                                    .map(
                                      (shop) => DropdownMenuItem<String>(
                                        value: shop.id,
                                        child: Text(shop.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedShopId = value;
                                  });
                                },
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickStartDate,
                                    icon: const Icon(Icons.date_range),
                                    label: Text('From: ${_formatDateOrToday(start, dateFormat)}'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickEndDate,
                                    icon: const Icon(Icons.date_range),
                                    label: Text('To:   ${_formatDateOrToday(end, dateFormat)}'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Bought Amount'),
                                          const SizedBox(height: 4),
                                          Text(currencyFormat.format(totalBoughtAmount)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Sold Amount'),
                                          const SizedBox(height: 4),
                                          Text(currencyFormat.format(totalSoldAmount)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Net Income'),
                                          const SizedBox(height: 4),
                                          Text(currencyFormat.format(netIncome)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: [
                                      const DataColumn(label: Text('Item')),
                                      const DataColumn(label: Text('Unit')),
                                      const DataColumn(label: Text('Prev Qty')),
                                      const DataColumn(label: Text('Bought')),
                                      if (widget.allowShopSwitch)
                                        const DataColumn(label: Text('Bought Amt')),
                                      const DataColumn(label: Text('Sold')),
                                      const DataColumn(label: Text('Sold Amt')),
                                      if (widget.allowShopSwitch)
                                        const DataColumn(label: Text('Net')),
                                      const DataColumn(label: Text('Remaining')),
                                      if (widget.allowShopSwitch)
                                        const DataColumn(label: Text('Profit')),
                                    ],
                                    rows: effectiveSummaries.map((s) {
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
                                      final selectedUnitId =
                                          _selectedUnitIds[key] ?? s.baseFractionId;
                                      final selectedFraction = fractions.firstWhere(
                                        (f) => f.id == selectedUnitId,
                                        orElse: () => fractions.first,
                                      );
                                      final ratioFactor =
                                          s.baseRatio / selectedFraction.ratio;
                                      final currencyFormat =
                                          NumberFormat('#,##0.00');
                                      final netIncome =
                                          s.soldAmountInPeriod - s.boughtAmountInPeriod;

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
                                          DataCell(
                                            Text(
                                              (s.previousQuantity * ratioFactor)
                                                  .toStringAsFixed(2),
                                            ),
                                            onTap: () {
                                              final availableItemProvider =
                                                  context.read<AvailableItemProvider>();
                                              final match = availableItemProvider.availableItems
                                                  .where((ai) =>
                                                      ai.shopId == currentShopId &&
                                                      ai.itemId == s.itemId)
                                                  .toList();

                                              if (match.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('No item found in available items'),
                                                  ),
                                                );
                                                return;
                                              }

                                              final cutoff = DateTime(
                                                start.year,
                                                start.month,
                                                start.day,
                                              );

                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => TransactionsScreen(
                                                    availableItem: match.first,
                                                    showBefore: cutoff,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          DataCell(
                                            Text(
                                              (s.boughtInPeriod * ratioFactor)
                                                  .toStringAsFixed(2),
                                            ),
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
                                          if (widget.allowShopSwitch)
                                            DataCell(
                                              Text(
                                                currencyFormat.format(
                                                  s.boughtAmountInPeriod,
                                                ),
                                              ),
                                            ),
                                          DataCell(
                                            Text(
                                              (s.soldInPeriod * ratioFactor)
                                                  .toStringAsFixed(2),
                                            ),
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      FilteredSalesHistoryScreen(
                                                    itemId: s.itemId,
                                                    fractionId: s.baseFractionId,
                                                    shopId: currentShopId,
                                                    start: start,
                                                    end: end,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          DataCell(
                                            Text(
                                              currencyFormat.format(
                                                s.soldAmountInPeriod,
                                              ),
                                            ),
                                          ),
                                          if (widget.allowShopSwitch)
                                            DataCell(
                                              Text(currencyFormat.format(netIncome)),
                                            ),
                                          DataCell(
                                            Text(
                                              (s.remainingNow * ratioFactor)
                                                  .toStringAsFixed(2),
                                            ),
                                          ),
                                          if (widget.allowShopSwitch)
                                            DataCell(
                                              Text(
                                                s.profitInPeriod.toStringAsFixed(2),
                                              ),
                                            ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            if (effectiveSummaries.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text('No data for selected period'),
                              ),
                          ],
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
        a.boughtAmountInPeriod += (b.quantity * b.fractionPurchasePrice);
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
        a.soldAmountInPeriod += s.soldPrice;
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
        boughtAmountInPeriod: a.boughtAmountInPeriod,
        soldInPeriod: a.soldInPeriod,
        soldAmountInPeriod: a.soldAmountInPeriod,
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
  double boughtAmountInPeriod = 0;
  double soldInPeriod = 0;
  double soldAmountInPeriod = 0;
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
  final double boughtAmountInPeriod;
  final double soldInPeriod;
  final double soldAmountInPeriod;
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
    required this.boughtAmountInPeriod,
    required this.soldInPeriod,
    required this.soldAmountInPeriod,
    required this.remainingNow,
    required this.profitInPeriod,
  });
}


