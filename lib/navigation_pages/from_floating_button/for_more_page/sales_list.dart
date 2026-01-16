import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../common/components/custom_files/custom_info_card.dart';
import '../../../common/components/custom_files/search_filter_widget.dart';
import '../../../database/sales_db.dart';

class SalesListPage extends StatefulWidget {
  const SalesListPage({Key? key}) : super(key: key);

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  late Future<List<Map<String, dynamic>>> _salesFuture;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  void _loadSales() {
    setState(() {
      _salesFuture = SalesDB.getAllSales();
    });
  }

  double _calculateTotal(List<Map<String, dynamic>> salesList) {
    return salesList.fold<double>(
      0.0,
      (previousValue, element) =>
          previousValue + (element['total_amount'] as num? ?? 0).toDouble(),
    );
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    // Normalize separators for parsing
    String normalized = dateStr.replaceAll('-', '/');

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(normalized);
    } catch (_) {
      try {
        return DateFormat('yyyy/MM/dd').parseStrict(normalized);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Reports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _salesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Sales Found'));
          }

          var salesList = snapshot.data!;
          final grandTotal = _calculateTotal(salesList);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Sales",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SearchFilterWidget<Map<String, dynamic>>(
                  items: salesList,
                  hintText: "Search Sales...",
                  dateExtractor: (sale) => _parseDate(sale['date']),
                  itemBuilder: (context, sale) {
                    return CustomCard(
                      title: sale['customer_name'] ?? 'Unknown Customer',
                      details: [
                        'Sales No: ${sale['sales_no'] ?? ''}',
                        'Date: ${sale['date'] ?? ''}',
                        'Amount: ₹${(sale['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                        'Status: ${sale['payment_status'] ?? 'N/A'}',
                      ],
                      isRecent: false,
                    );
                  },
                  emptyStateWidget: const Center(child: Text("No Sales Found")),
                  customFilter: (items, query) {
                    return items.where((sale) {
                      final name =
                          (sale['customer_name'] ?? '')
                              .toString()
                              .toLowerCase();
                      final salesNo =
                          (sale['sales_no'] ?? '').toString().toLowerCase();
                      final date =
                          (sale['date'] ?? '').toString().toLowerCase();
                      return name.contains(query) ||
                          salesNo.contains(query) ||
                          date.contains(query);
                    }).toList();
                  },
                  filterOptions: [
                    FilterOption<Map<String, dynamic>>(
                      name: 'None',
                      icon: Icons.clear,
                      filter: (items) => items,
                    ),
                    FilterOption<Map<String, dynamic>>(
                      name: 'Highest Amount',
                      icon: Icons.arrow_downward,
                      filter: (items) {
                        final sorted = List<Map<String, dynamic>>.from(items);
                        sorted.sort(
                          (a, b) =>
                              (b['total_amount'] as num?)?.compareTo(
                                a['total_amount'] as num? ?? 0,
                              ) ??
                              0,
                        );
                        return sorted;
                      },
                    ),
                    FilterOption<Map<String, dynamic>>(
                      name: 'Lowest Amount',
                      icon: Icons.arrow_upward,
                      filter: (items) {
                        final sorted = List<Map<String, dynamic>>.from(items);
                        sorted.sort(
                          (a, b) =>
                              (a['total_amount'] as num?)?.compareTo(
                                b['total_amount'] as num? ?? 0,
                              ) ??
                              0,
                        );
                        return sorted;
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade900,
        onPressed: () async {
          // Use await and then refresh the sales list
          await Navigator.pushNamed(context, "add_sales");
          _loadSales(); // Refresh the list after returning from add_sales page
        },
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text("ADD SALES", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
