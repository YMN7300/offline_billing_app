import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../common/components/custom_files/custom_info_card.dart';
import '../../../common/components/custom_files/search_filter_widget.dart';
import '../../../database/purchase_db.dart';

class PurchaseListPage extends StatefulWidget {
  const PurchaseListPage({Key? key}) : super(key: key);

  @override
  State<PurchaseListPage> createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends State<PurchaseListPage> {
  late Future<List<Map<String, dynamic>>> _purchasesFuture;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  void _loadPurchases() {
    setState(() {
      _purchasesFuture = PurchaseDB.getAllPurchases();
    });
  }

  double _calculateTotal(List<Map<String, dynamic>> purchasesList) {
    return purchasesList.fold<double>(
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
          'Purchase Reports',
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
        future: _purchasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Purchases Found'));
          }

          var purchasesList = snapshot.data!;
          final grandTotal = _calculateTotal(purchasesList);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Purchases",
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
                  items: purchasesList,
                  hintText: "Search Purchases...",
                  dateExtractor: (purchase) => _parseDate(purchase['date']),
                  itemBuilder: (context, purchase) {
                    return CustomCard(
                      title: purchase['vendor_name'] ?? 'Unknown Vendor',
                      details: [
                        'Purchase No: ${purchase['purchase_no'] ?? ''}',
                        'Date: ${purchase['date'] ?? ''}',
                        'Amount: ₹${(purchase['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                        'Status: ${purchase['payment_status'] ?? 'N/A'}',
                      ],
                      isRecent: false,
                    );
                  },
                  emptyStateWidget: const Center(
                    child: Text("No Purchases Found"),
                  ),
                  customFilter: (items, query) {
                    return items.where((purchase) {
                      final name =
                          (purchase['vendor_name'] ?? '')
                              .toString()
                              .toLowerCase();
                      final purchaseNo =
                          (purchase['purchase_no'] ?? '')
                              .toString()
                              .toLowerCase();
                      final date =
                          (purchase['date'] ?? '').toString().toLowerCase();
                      final status =
                          (purchase['payment_status'] ?? '')
                              .toString()
                              .toLowerCase();
                      return name.contains(query) ||
                          purchaseNo.contains(query) ||
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
        backgroundColor: Colors.blue.shade900,
        onPressed: () async {
          // Use await and then refresh the purchases list
          await Navigator.pushNamed(context, "add_purchase");
          _loadPurchases(); // Refresh the list after returning from add_purchase page
        },
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text(
          "ADD PURCHASE",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
