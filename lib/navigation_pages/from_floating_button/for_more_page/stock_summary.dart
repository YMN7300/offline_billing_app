import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../common/components/custom_files/custom_info_card.dart';
import '../../../common/components/custom_files/search_filter_widget.dart';
import '../../../database/product_db.dart';

class StockSummaryPage extends StatefulWidget {
  const StockSummaryPage({Key? key}) : super(key: key);

  @override
  State<StockSummaryPage> createState() => _StockSummaryPageState();
}

class _StockSummaryPageState extends State<StockSummaryPage> {
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

  // Calculate total stock value (quantity * cost price)
  double _calculateTotalStockValue(List<Map<String, dynamic>> productsList) {
    return productsList.fold<double>(
      0.0,
      (previousValue, element) =>
          previousValue +
          ((element['stockQuantity'] as int? ?? 0) *
              (element['costPrice'] as double? ?? 0.0)),
    );
  }

  // Calculate total number of low stock items
  int _calculateLowStockItems(List<Map<String, dynamic>> productsList) {
    return productsList.where((product) {
      final stock = product['stockQuantity'] as int? ?? 0;
      final alertLevel = product['lowStockAlert'] as int? ?? 0;
      return stock <= alertLevel && stock > 0;
    }).length;
  }

  // Calculate total number of out of stock items
  int _calculateOutOfStockItems(List<Map<String, dynamic>> productsList) {
    return productsList.where((product) {
      final stock = product['stockQuantity'] as int? ?? 0;
      return stock == 0;
    }).length;
  }

  // Get stock status text and color
  Map<String, dynamic> _getStockStatus(int stock, int alertLevel) {
    if (stock == 0) {
      return {'text': 'Out of Stock', 'color': Colors.red};
    } else if (stock <= alertLevel) {
      return {'text': 'Low Stock', 'color': Colors.orange};
    } else {
      return {'text': 'In Stock', 'color': Colors.green};
    }
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
          'Stock Summary',
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
          final totalStockValue = _calculateTotalStockValue(productsList);
          final lowStockItems = _calculateLowStockItems(productsList);
          final outOfStockItems = _calculateOutOfStockItems(productsList);

          return Column(
            children: [
              // Summary Cards Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSummaryCard(
                      'Total Items',
                      totalItems.toString(),
                      Colors.blue,
                      Icons.inventory_2,
                    ),
                    _buildSummaryCard(
                      'Stock Value',
                      '₹${totalStockValue.toStringAsFixed(2)}',
                      Colors.green,
                      Icons.currency_rupee,
                    ),
                    _buildSummaryCard(
                      'Low Stock',
                      lowStockItems.toString(),
                      Colors.orange,
                      Icons.warning,
                    ),
                    _buildSummaryCard(
                      'Out of Stock',
                      outOfStockItems.toString(),
                      Colors.red,
                      Icons.error_outline,
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
                    final stock = product['stockQuantity'] as int? ?? 0;
                    final alertLevel = product['lowStockAlert'] as int? ?? 0;
                    final status = _getStockStatus(stock, alertLevel);

                    return Column(
                      children: [
                        // Status indicator moved above the card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status['color'].withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: status['color'],
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                status['text'],
                                style: TextStyle(
                                  color: status['color'],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Product card
                        CustomCard(
                          title: product['name'] ?? 'Unknown Product',
                          details: [
                            'Category: ${product['category'] ?? ''}',
                            'Brand: ${product['brand'] ?? ''}',
                            'Stock: $stock',
                            'Alert Level: $alertLevel',
                            'Price: ₹${(product['salePrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          ],
                          isRecent: false,
                        ),
                      ],
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
                      name: 'Low Stock',
                      icon: Icons.warning,
                      filter: (items) {
                        return items.where((product) {
                          final stock = product['stockQuantity'] as int? ?? 0;
                          final alertLevel =
                              product['lowStockAlert'] as int? ?? 0;
                          return stock <= alertLevel && stock > 0;
                        }).toList();
                      },
                    ),
                    FilterOption<Map<String, dynamic>>(
                      name: 'Out of Stock',
                      icon: Icons.error_outline,
                      filter: (items) {
                        return items.where((product) {
                          final stock = product['stockQuantity'] as int? ?? 0;
                          return stock == 0;
                        }).toList();
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
