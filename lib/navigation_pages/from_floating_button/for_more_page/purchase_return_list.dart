import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../common/components/custom_files/custom_info_card.dart';
import '../../../common/components/custom_files/search_filter_widget.dart';
import '../../../database/purchase_return_db.dart';

class PurchaseReturnListPage extends StatefulWidget {
  const PurchaseReturnListPage({Key? key}) : super(key: key);

  @override
  State<PurchaseReturnListPage> createState() => _PurchaseReturnListPageState();
}

class _PurchaseReturnListPageState extends State<PurchaseReturnListPage> {
  late Future<List<Map<String, dynamic>>> _returnsFuture;

  @override
  void initState() {
    super.initState();
    _loadReturns();
  }

  void _loadReturns() {
    setState(() {
      _returnsFuture = PurchaseReturnDB.getAllReturns();
    });
  }

  double _calculateTotal(List<Map<String, dynamic>> returnsList) {
    return returnsList.fold<double>(
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
          'Purchase Returns Reports',
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
        future: _returnsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Purchase Returns Found'));
          }

          var returnsList = snapshot.data!;
          final grandTotal = _calculateTotal(returnsList);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Returns",
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
                  items: returnsList,
                  hintText: "Search Returns...",
                  dateExtractor: (returnItem) => _parseDate(returnItem['date']),
                  itemBuilder: (context, returnItem) {
                    return CustomCard(
                      title: returnItem['supplier_name'] ?? 'Unknown Supplier',
                      details: [
                        'Return No: ${returnItem['return_no'] ?? ''}',
                        'Date: ${returnItem['date'] ?? ''}',
                        'Amount: ₹${(returnItem['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                        'Status: ${returnItem['payment_status'] ?? 'N/A'}',
                      ],
                      isRecent: false,
                    );
                  },
                  emptyStateWidget: const Center(
                    child: Text("No Returns Found"),
                  ),
                  customFilter: (items, query) {
                    return items.where((returnItem) {
                      final name =
                          (returnItem['supplier_name'] ?? '')
                              .toString()
                              .toLowerCase();
                      final returnNo =
                          (returnItem['return_no'] ?? '')
                              .toString()
                              .toLowerCase();
                      final originalPurchaseNo =
                          (returnItem['original_purchase_no'] ?? '')
                              .toString()
                              .toLowerCase();
                      final date =
                          (returnItem['date'] ?? '').toString().toLowerCase();
                      final status =
                          (returnItem['payment_status'] ?? '')
                              .toString()
                              .toLowerCase();
                      return name.contains(query) ||
                          returnNo.contains(query) ||
                          originalPurchaseNo.contains(query) ||
                          date.contains(query) ||
                          status.contains(query);
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
                    FilterOption<Map<String, dynamic>>(
                      name: 'By Status',
                      icon: Icons.filter_list,
                      filter: (items) {
                        final sorted = List<Map<String, dynamic>>.from(items);
                        sorted.sort(
                          (a, b) => (a['payment_status'] ?? '').compareTo(
                            b['payment_status'] ?? '',
                          ),
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
        backgroundColor: Colors.orange.shade900,
        onPressed: () {
          Navigator.pushNamed(context, "add_purchase_return").then((_) {
            _loadReturns(); // Refresh the list after returning from add_purchase_return page
          });
        },
        icon: const Icon(Icons.assignment_return, color: Colors.white),
        label: const Text("ADD RETURN", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
