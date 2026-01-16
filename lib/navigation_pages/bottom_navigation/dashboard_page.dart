import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../database/customer_db.dart';
import '../../database/product_db.dart';
import '../../database/purchase_db.dart';
import '../../database/sales_db.dart';
import '../../database/vendor_db.dart';
import '../appbar_buttons/fixed_appbar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int totalVendors = 0;
  int totalCustomers = 0;
  double stockValue = 0;
  double totalPurchaseAmount = 0;
  int numberOfItems = 0;
  double cashInHand = 0.0;

  String selectedPeriod = 'Last 7 Days';
  List<Map<String, dynamic>> salesData = [];
  double totalSales = 0;
  int? touchedIndex;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadTotalPurchaseAmount();
    _loadCashInHand();
  }

  Future<void> _loadDashboardData() async {
    try {
      final vendors = await VendorDB.getAllVendors();
      final customers = await CustomerDB.getAllCustomers();
      final products = await ProductDB.getAllProducts();

      double value = 0;
      for (var product in products) {
        final quantity = product['stockQuantity'] as int? ?? 0;
        final costPrice = product['costPrice'] as double? ?? 0;
        value += quantity * costPrice;
      }

      if (mounted) {
        setState(() {
          totalVendors = vendors.length;
          totalCustomers = customers.length;
          stockValue = value;
          numberOfItems = products.length;
        });
      }

      _loadSalesData();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  Future<void> _loadTotalPurchaseAmount() async {
    try {
      final purchases = await PurchaseDB.getAllPurchases();
      double total = 0;
      for (var purchase in purchases) {
        total += (purchase['total_amount'] as num?)?.toDouble() ?? 0.0;
      }
      if (mounted) {
        setState(() {
          totalPurchaseAmount = total;
        });
      }
    } catch (e) {
      debugPrint('Error loading total purchase amount: $e');
    }
  }

  Future<void> _loadCashInHand() async {
    try {
      final sales = await SalesDB.getAllSales();
      final purchases = await PurchaseDB.getAllPurchases();
      double totalSalesCash = 0.0;
      double totalPurchaseCash = 0.0;

      for (var s in sales) {
        if ((s['payment_method'] ?? '').toLowerCase() == 'cash') {
          totalSalesCash += (s['total_amount'] as num).toDouble();
        }
      }
      for (var p in purchases) {
        if ((p['payment_method'] ?? '').toLowerCase() == 'cash') {
          totalPurchaseCash += (p['total_amount'] as num).toDouble();
        }
      }

      setState(() {
        cashInHand = totalSalesCash - totalPurchaseCash;
      });
    } catch (e) {
      debugPrint('Error loading cash in hand: $e');
    }
  }

  Future<void> _loadSalesData() async {
    try {
      final allSales = await SalesDB.getAllSales();
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      if (selectedPeriod == 'Last 7 Days') {
        final sevenDaysAgo = startOfToday.subtract(const Duration(days: 6));
        List<double> dailySales = List.generate(7, (_) => 0.0);

        for (var sale in allSales) {
          final dateStr = sale['date'] as String?;
          if (dateStr == null) continue;

          final parts = dateStr.split('-');
          if (parts.length != 3) continue;

          final saleDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );

          final dayOnly = DateTime(saleDate.year, saleDate.month, saleDate.day);

          if (dayOnly.isBefore(sevenDaysAgo) || dayOnly.isAfter(startOfToday)) {
            continue;
          }

          int dayIndex = dayOnly.difference(sevenDaysAgo).inDays;

          if (dayIndex >= 0 && dayIndex < 7) {
            final amount = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
            dailySales[dayIndex] += amount;
          }
        }

        setState(() {
          salesData = List.generate(7, (index) {
            return {'label': index, 'amount': dailySales[index]};
          });
          totalSales = dailySales.reduce((a, b) => a + b);
          touchedIndex = null;
        });
      } else {
        DateTime firstMonthStart = DateTime(now.year, now.month - 2, 1);
        List<double> monthlySales = List.generate(3, (_) => 0.0);

        for (var sale in allSales) {
          final dateStr = sale['date'] as String?;
          if (dateStr == null) continue;

          final parts = dateStr.split('-');
          if (parts.length != 3) continue;

          final saleDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );

          if (saleDate.isBefore(firstMonthStart) ||
              saleDate.isAfter(startOfToday)) {
            continue;
          }

          int diffMonths =
              (saleDate.year - firstMonthStart.year) * 12 +
              (saleDate.month - firstMonthStart.month);

          if (diffMonths >= 0 && diffMonths < 3) {
            final amount = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
            monthlySales[diffMonths] += amount;
          }
        }

        setState(() {
          salesData = List.generate(3, (index) {
            return {'label': index, 'amount': monthlySales[index]};
          });
          totalSales = monthlySales.reduce((a, b) => a + b);
          touchedIndex = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading sales data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FixAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildSalesGraphCard(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Total Vendors",
                    totalVendors.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    "Total Customers",
                    totalCustomers.toString(),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInventoryCard(),
            const SizedBox(height: 8),
            _buildCashInHandCard(),
            const SizedBox(height: 8),
            _buildPurchaseCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Inventory",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Stock Value", style: TextStyle(fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      "₹ ${stockValue.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("No. of Items", style: TextStyle(fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      numberOfItems.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashInHandCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, "cash_in_hand");
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cash In-Hand",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "₹ ${cashInHand.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, "purchase_list");
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Purchases",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "₹ ${totalPurchaseAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesGraphCard() {
    final spots =
        salesData.isEmpty
            ? List.generate(
              selectedPeriod == 'Last 7 Days' ? 7 : 3,
              (i) => FlSpot(i.toDouble(), 0),
            )
            : salesData
                .map(
                  (e) => FlSpot(
                    e['label'].toDouble(),
                    (e['amount'] as double) > 0 ? e['amount'] : 0,
                  ),
                )
                .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Sales",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownButton<String>(
                  value: selectedPeriod,
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                  iconSize: 14,
                  iconEnabledColor: Colors.deepPurple,
                  items: const [
                    DropdownMenuItem(
                      value: 'Last 7 Days',
                      child: Text('Last 7 Days'),
                    ),
                    DropdownMenuItem(
                      value: 'Last 3 Months',
                      child: Text('Last 3 Months'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedPeriod = value;
                        touchedIndex = null;
                      });
                      _loadSalesData();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                "Total Sales",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                "₹ ${totalSales.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            if (touchedIndex != null) ...[
              const SizedBox(height: 2),
              Center(
                child: Text(
                  "₹ ${(salesData[touchedIndex!]['amount'] as double).toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            SizedBox(
              height: 160,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 20,
                          getTitlesWidget: (value, meta) {
                            if (selectedPeriod == 'Last 7 Days') {
                              final now = DateTime.now();
                              final start = now.subtract(
                                const Duration(days: 6),
                              );
                              final day = start.add(
                                Duration(days: value.toInt()),
                              );
                              const days = [
                                "Sun",
                                "Mon",
                                "Tue",
                                "Wed",
                                "Thu",
                                "Fri",
                                "Sat",
                              ];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  days[day.weekday % 7],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            } else {
                              DateTime now = DateTime.now();
                              List<String> months = List.generate(3, (i) {
                                DateTime m = DateTime(
                                  now.year,
                                  now.month - 2 + i,
                                );
                                const monthNames = [
                                  "Jan",
                                  "Feb",
                                  "Mar",
                                  "Apr",
                                  "May",
                                  "Jun",
                                  "Jul",
                                  "Aug",
                                  "Sep",
                                  "Oct",
                                  "Nov",
                                  "Dec",
                                ];
                                return monthNames[m.month - 1];
                              });
                              int idx = value.toInt().clamp(0, 2);
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  months[idx],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: false,
                        color: Colors.deepPurple,
                        barWidth: 2,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.withOpacity(0.3),
                              Colors.deepPurple.withOpacity(0.05),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: false,
                      touchCallback: (event, response) {
                        if (response != null &&
                            response.lineBarSpots != null &&
                            response.lineBarSpots!.isNotEmpty) {
                          setState(() {
                            touchedIndex =
                                response.lineBarSpots!.first.spotIndex;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
