import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../common/components/custom_files/custom_info_card.dart';
import '../../../common/components/custom_files/search_filter_widget.dart';
import '../../../database/product_db.dart';

class ItemSummaryPage extends StatefulWidget {
  const ItemSummaryPage({Key? key}) : super(key: key);

  @override
  State<ItemSummaryPage> createState() => _ItemSummaryPageState();
}

class _ItemSummaryPageState extends State<ItemSummaryPage> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = ProductDB.getAllProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Items Summary',
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
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Products Found'));
          }

          var productsList = snapshot.data!;
          final totalItems = productsList.length;

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
                      "Total Items",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      totalItems.toString(),
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
                  items: productsList,
                  hintText: "Search Products...",
                  dateExtractor: (product) => _parseDate(product['date']),
                  itemBuilder: (context, product) {
                    return CustomCard(
                      title: product['name'] ?? 'Unknown Product',
                      details: [
                        'Category: ${product['category'] ?? ''}',
                        'Brand: ${product['brand'] ?? ''}',
                        'Stock: ${product['stockQuantity'] ?? 0}',
                        'Price: ₹${(product['salePrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                      ],
                      isRecent: false,
                    );
                  },
                  emptyStateWidget: const Center(
                    child: Text("No Products Found"),
                  ),
                  customFilter: (items, query) {
                    return items.where((product) {
                      final name =
                          (product['name'] ?? '').toString().toLowerCase();
                      final category =
                          (product['category'] ?? '').toString().toLowerCase();
                      final brand =
                          (product['brand'] ?? '').toString().toLowerCase();
                      final type =
                          (product['type'] ?? '').toString().toLowerCase();
                      return name.contains(query) ||
                          category.contains(query) ||
                          brand.contains(query) ||
                          type.contains(query);
                    }).toList();
                  },
                  filterOptions: [
                    FilterOption<Map<String, dynamic>>(
                      name: 'None',
                      icon: Icons.clear,
                      filter: (items) => items,
                    ),
                    FilterOption<Map<String, dynamic>>(
                      name: 'Highest Stock',
                      icon: Icons.arrow_downward,
                      filter: (items) {
                        final sorted = List<Map<String, dynamic>>.from(items);
                        sorted.sort(
                          (a, b) =>
                              (b['stockQuantity'] as int?)?.compareTo(
                                a['stockQuantity'] as int? ?? 0,
                              ) ??
                              0,
                        );
                        return sorted;
                      },
                    ),
                    FilterOption<Map<String, dynamic>>(
                      name: 'Lowest Stock',
                      icon: Icons.arrow_upward,
                      filter: (items) {
                        final sorted = List<Map<String, dynamic>>.from(items);
                        sorted.sort(
                          (a, b) =>
                              (a['stockQuantity'] as int?)?.compareTo(
                                b['stockQuantity'] as int? ?? 0,
                              ) ??
                              0,
                        );
                        return sorted;
                      },
                    ),
                    FilterOption<Map<String, dynamic>>(
                      name: 'Highest Price',
                      icon: Icons.arrow_downward,
                      filter: (items) {
                        final sorted = List<Map<String, dynamic>>.from(items);
                        sorted.sort(
                          (a, b) =>
                              (b['salePrice'] as num?)?.compareTo(
                                a['salePrice'] as num? ?? 0,
                              ) ??
                              0,
                        );
                        return sorted;
                      },
                    ),
                    FilterOption<Map<String, dynamic>>(
                      name: 'Lowest Price',
                      icon: Icons.arrow_upward,
                      filter: (items) {
                        final sorted = List<Map<String, dynamic>>.from(items);
                        sorted.sort(
                          (a, b) =>
                              (a['salePrice'] as num?)?.compareTo(
                                b['salePrice'] as num? ?? 0,
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
        backgroundColor: Colors.blue.shade900,
        onPressed: () async {
          // Use await and then refresh the products list
          await Navigator.pushNamed(context, "add_product");
          _loadProducts(); // Refresh the list after returning from add_product page
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ADD PRODUCT", style: TextStyle(color: Colors.white)),
      ),
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
}
