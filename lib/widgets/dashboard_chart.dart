import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardChart extends StatelessWidget {
  final List<dynamic> data;
  final String? emptyText;
  final String currencySymbol;
  
  const DashboardChart({
    super.key,
    required this.data,
    this.emptyText,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(emptyText ?? ''),
      );
    }
    
    final spots = _createSpots();
    final maxY = _getMaxY();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 5,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length || value.toInt() < 0) {
                  return const SizedBox();
                }
                
                final date = DateTime.parse(data[value.toInt()]['date']);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(date),
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '$currencySymbol${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  List<FlSpot> _createSpots() {
    final spots = <FlSpot>[];
    
    for (int i = 0; i < data.length; i++) {
      final total = double.parse(data[i]['total'].toString());
      spots.add(FlSpot(i.toDouble(), total));
    }
    
    return spots;
  }
  
  double _getMaxY() {
    double maxY = 0;
    
    for (final item in data) {
      final total = double.parse(item['total'].toString());
      if (total > maxY) {
        maxY = total;
      }
    }
    
    // Add some padding to the max value
    return maxY * 1.2;
  }
}
