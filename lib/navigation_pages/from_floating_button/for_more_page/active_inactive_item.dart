import 'package:flutter/material.dart';

import '../../../common/components/custom_files/custom_info_card.dart';
import '../../../common/components/custom_files/search_filter_widget.dart';
import '../../../database/product_db.dart';

class ActiveInactiveItemsPage extends StatefulWidget {
  const ActiveInactiveItemsPage({Key? key}) : super(key: key);

  @override
  State<ActiveInactiveItemsPage> createState() =>
      _ActiveInactiveItemsPageState();
}

class _ActiveInactiveItemsPageState extends State<ActiveInactiveItemsPage> {
  late Future<List<Map<String, dynamic>>> _productsFuture;
  final Map<int, bool> _activeStatus =
      {}; // In-memory storage for active status

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

  // Get active status from memory (defaults to true/active)
  bool _getActiveStatus(Map<String, dynamic> product) {
    final id = product['id'] as int;
    return _activeStatus[id] ?? true; // Default to active if not set
  }

  // Toggle active status (in memory only)
  void _toggleActiveStatus(Map<String, dynamic> product) {
    final id = product['id'] as int;
    final currentStatus = _getActiveStatus(product);
    setState(() {
      _activeStatus[id] = !currentStatus;
    });
  }

  // Count active items
  int _countActiveItems(List<Map<String, dynamic>> products) {
    return products.where((product) => _getActiveStatus(product)).length;
  }

  // Count inactive items
  int _countInactiveItems(List<Map<String, dynamic>> products) {
    return products.where((product) => !_getActiveStatus(product)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Active/Inactive Items',
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
          final activeItemsCount = _countActiveItems(productsList);
          final inactiveItemsCount = _countInactiveItems(productsList);

          return Column(
            children: [
              // Summary Cards Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSummaryCard(
                      'Active Items',
                      activeItemsCount.toString(),
                      Colors.green,
                      Icons.check_circle,
                    ),
                    _buildSummaryCard(
                      'Inactive Items',
                      inactiveItemsCount.toString(),
                      Colors.red,
                      Icons.cancel,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SearchFilterWidget<Map<String, dynamic>>(
                  items: productsList,
                  hintText: "Search Products...",
                  itemBuilder: (context, product) {
                    final isActive = _getActiveStatus(product);

                    return Column(
                      children: [
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: isActive ? Colors.green : Colors.red,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color:
                                          isActive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: isActive,
                                onChanged:
                                    (value) => _toggleActiveStatus(product),
                                activeColor: Colors.green,
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
                            'Stock: ${product['stockQuantity'] ?? 0}',
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
                      name: 'All Items',
                      icon: Icons.list,
                      filter: (items) => items,
                    ),
                    FilterOption<Map<String, dynamic>>(
                      name: 'Active Only',
                      icon: Icons.check_circle,
                      filter: (items) {
                        return items
                            .where((product) => _getActiveStatus(product))
                            .toList();
                      },
                    ),
                    FilterOption<Map<String, dynamic>>(
                      name: 'Inactive Only',
                      icon: Icons.cancel,
                      filter: (items) {
                        return items
                            .where((product) => !_getActiveStatus(product))
                            .toList();
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
