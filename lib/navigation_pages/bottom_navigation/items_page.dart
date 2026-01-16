import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/navigation_pages/appbar_buttons/fixed_appbar.dart';

import '../../common/components/custom_files/custom_info_card.dart';
import '../../common/components/custom_files/search_filter_widget.dart';
import '../../database/product_db.dart';
import '../from_floating_button/for_item_page/add_product.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  List<Map<String, dynamic>> _productList = [];
  List<Map<String, dynamic>> _filteredProductList = [];
  int? _latestProductId;
  int _selectedFilterIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await ProductDB.getAllProducts();
    if (mounted) {
      setState(() {
        _productList = products;
        _filteredProductList = _applyStockFilter(products);
        if (products.isNotEmpty) {
          _latestProductId =
              products.reduce(
                (curr, next) => curr['id'] > next['id'] ? curr : next,
              )['id'];
        }
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _applyStockFilter(
    List<Map<String, dynamic>> products,
  ) {
    if (_selectedFilterIndex == 0) {
      return products;
    } else {
      return products.where((product) {
        final stock = product['stockQuantity'] ?? 0;
        final lowStockAlert = product['lowStockAlert'] ?? 0;
        return stock <= lowStockAlert;
      }).toList();
    }
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: const Text(
              'Are you sure you want to delete this product?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await ProductDB.deleteProduct(id);
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FixAppBar(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        height: 30,
                        color: primary,
                        child: const Center(
                          child: Text(
                            "PRODUCT",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            _productList.isEmpty
                                ? _buildEmptyContent()
                                : Padding(
                                  padding: const EdgeInsets.only(bottom: 80),
                                  child: SearchFilterWidget(
                                    items: _filteredProductList,
                                    hintText: 'Search by name, price, stock...',
                                    dateExtractor:
                                        (product) =>
                                            _parseDate(product['date']),
                                    emptyStateWidget:
                                        _selectedFilterIndex == 1
                                            ? _buildLowStockEmptyContent()
                                            : _buildEmptyContent(),
                                    filterOptions: [
                                      FilterOption(
                                        name: 'None',
                                        icon: Icons.clear_all,
                                        filter: (items) => items,
                                      ),
                                      FilterOption(
                                        name: 'Recent',
                                        icon: Icons.access_time,
                                        filter:
                                            (items) => List.from(items)..sort(
                                              (a, b) =>
                                                  b['id'].compareTo(a['id']),
                                            ),
                                      ),
                                      FilterOption(
                                        name: 'Stock High to Low',
                                        icon: Icons.arrow_downward,
                                        filter:
                                            (items) => List.from(items)..sort(
                                              (a, b) =>
                                                  b['stockQuantity'].compareTo(
                                                    a['stockQuantity'],
                                                  ),
                                            ),
                                      ),
                                      FilterOption(
                                        name: 'Stock Low to High',
                                        icon: Icons.arrow_upward,
                                        filter:
                                            (items) => List.from(items)..sort(
                                              (a, b) =>
                                                  a['stockQuantity'].compareTo(
                                                    b['stockQuantity'],
                                                  ),
                                            ),
                                      ),
                                      FilterOption(
                                        name: 'Highest Price',
                                        icon: Icons.arrow_downward,
                                        filter: (items) {
                                          final sorted =
                                              List<Map<String, dynamic>>.from(
                                                items,
                                              );
                                          sorted.sort(
                                            (a, b) =>
                                                (b['salePrice'] as num?)
                                                    ?.compareTo(
                                                      a['salePrice'] as num? ??
                                                          0,
                                                    ) ??
                                                0,
                                          );
                                          return sorted;
                                        },
                                      ),
                                      FilterOption(
                                        name: 'Lowest Price',
                                        icon: Icons.arrow_upward,
                                        filter: (items) {
                                          final sorted =
                                              List<Map<String, dynamic>>.from(
                                                items,
                                              );
                                          sorted.sort(
                                            (a, b) =>
                                                (a['salePrice'] as num?)
                                                    ?.compareTo(
                                                      b['salePrice'] as num? ??
                                                          0,
                                                    ) ??
                                                0,
                                          );
                                          return sorted;
                                        },
                                      ),
                                    ],
                                    customFilter: (items, query) {
                                      return items.where((product) {
                                        final nameMatch = product['name']
                                            .toString()
                                            .toLowerCase()
                                            .contains(query.toLowerCase());
                                        final salePriceMatch =
                                            product['salePrice']
                                                .toString()
                                                .contains(query);
                                        final costPriceMatch =
                                            product['costPrice']
                                                .toString()
                                                .contains(query);
                                        final stockMatch =
                                            product['stockQuantity']
                                                .toString()
                                                .contains(query);
                                        return nameMatch ||
                                            salePriceMatch ||
                                            costPriceMatch ||
                                            stockMatch;
                                      }).toList();
                                    },
                                    itemBuilder: (context, product) {
                                      final details = [
                                        "Sale Price: ₹${product['salePrice']}",
                                        "Cost Price: ₹${product['costPrice']}",
                                        "Stock: ${product['stockQuantity']}",
                                      ];

                                      return CustomCard(
                                        title: product['name'],
                                        details: details,
                                        isRecent:
                                            _latestProductId != null &&
                                            product['id'] == _latestProductId,
                                        onEdit: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => AddProduct(
                                                    productData: product,
                                                  ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadProducts();
                                          }
                                        },
                                        onDelete:
                                            () => _deleteProduct(product['id']),
                                      );
                                    },
                                    toggleButtons: Container(
                                      margin: const EdgeInsets.only(bottom: 1),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16.0,
                                          top: 4.0,
                                          bottom: 4.0,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: ToggleButtons(
                                            isSelected: [
                                              _selectedFilterIndex == 0,
                                              _selectedFilterIndex == 1,
                                            ],
                                            onPressed: (int index) {
                                              setState(() {
                                                _selectedFilterIndex = index;
                                                _filteredProductList =
                                                    _applyStockFilter(
                                                      _productList,
                                                    );
                                              });
                                            },
                                            constraints: const BoxConstraints(
                                              minWidth: 100,
                                              minHeight: 32,
                                            ),
                                            color: Colors.black,
                                            selectedColor: Colors.white,
                                            fillColor: primary,
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                            children: const [
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.0,
                                                ),
                                                child: Text(
                                                  'All Items',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.0,
                                                ),
                                                child: Text(
                                                  'Low Stock',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FloatingActionButton.extended(
                        backgroundColor: Colors.blueAccent.shade700,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddProduct(),
                            ),
                          );
                          if (result == true) {
                            _loadProducts();
                          }
                        },
                        icon: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "ADD PRODUCT",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildEmptyContent() {
    return _buildEmptyContentWithImage(
      'assets/images/inventory2.png',
      'Add PRODUCTS and get started',
      [
        _buildInfoRow(Icons.upload, Colors.blue, 'Manage Stock IN'),
        _buildInfoRow(Icons.download, Colors.green, 'Manage Stock OUT'),
        _buildInfoRow(
          Icons.warning_amber_outlined,
          Colors.red,
          'Low Stock Alerts',
        ),
      ],
    );
  }

  Widget _buildLowStockEmptyContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no_low_stock.png',
            height: 100,
            width: 100,
          ),
          const Text(
            'No items with low stock count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContentWithImage(
    String image,
    String title,
    List<Widget> rows,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Image.asset(image, width: 300, height: 300),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Container(
            padding: const EdgeInsets.all(10),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Date parsing method from ItemSummaryPage
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
