import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/database/purchase_db.dart';
import 'package:offline_billing/database/vendor_db.dart';
import 'package:offline_billing/navigation_pages/appbar_buttons/fixed_appbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../common/components/custom_files/custom_info_card.dart';
import '../../common/components/custom_files/search_filter_widget.dart';
import '../../database/customer_db.dart';
import '../../database/purchase_item_db.dart';
import '../../database/purchase_return_db.dart';
import '../../database/purchase_return_item_db.dart';
import '../../database/sales_db.dart';
import '../../database/sales_item_db.dart';
import '../../database/sales_return_db.dart';
import '../../database/sales_return_item_db.dart';
import '../from_floating_button/for_home_page/add_customer.dart';
import '../from_floating_button/for_home_page/add_purchase.dart';
import '../from_floating_button/for_home_page/add_purchase_return.dart';
import '../from_floating_button/for_home_page/add_sales.dart';
import '../from_floating_button/for_home_page/add_sales_return.dart';
import '../from_floating_button/for_home_page/add_vendor.dart';
import '../from_floating_button/for_home_page/invoice/purchase_invoice.dart';
import '../from_floating_button/for_home_page/invoice/purchase_return_invoice.dart';
import '../from_floating_button/for_home_page/invoice/sales_invoice.dart';
import '../from_floating_button/for_home_page/invoice/sales_return_invoice.dart';

// Base ListView State
abstract class BaseListViewState<T extends StatefulWidget> extends State<T> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _itemList = [];
  String _emptyImage = '';
  String _emptyTitle = '';
  List<Widget> _emptyInfoRows = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get itemList => _itemList;
  String get emptyImage => _emptyImage;
  String get emptyTitle => _emptyTitle;
  List<Widget> get emptyInfoRows => _emptyInfoRows;

  Future<void> refresh();

  void setLoading(bool value) => setState(() => _isLoading = value);
  void setItemList(List<Map<String, dynamic>> list) =>
      setState(() => _itemList = list);
  void setEmptyContent(String image, String title, List<Widget> rows) {
    _emptyImage = image;
    _emptyTitle = title;
    _emptyInfoRows = rows;
  }

  Widget buildInfoRow(IconData icon, Color color, String label) {
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

  Widget buildEmptyContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          Image.asset(emptyImage, width: 300, height: 320),
          Text(
            emptyTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            child: Column(children: emptyInfoRows),
          ),
        ],
      ),
    );
  }

  Future<bool> showDeleteConfirmation(
    BuildContext context,
    String title,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Delete $title'),
                content: Text('Are you sure you want to delete this $title?'),
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
        ) ??
        false;
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController slider;
  final GlobalKey<_VendorListViewState> _vendorKey = GlobalKey();
  final GlobalKey<_CustomerListViewState> _customerKey = GlobalKey();
  final GlobalKey<_PurchaseListViewState> _purchaseKey = GlobalKey();
  final GlobalKey<_SalesListViewState> _salesKey = GlobalKey();
  final GlobalKey<_SalesReturnListViewState> _salesReturnKey = GlobalKey();
  final GlobalKey<_PurchaseReturnListViewState> _purchaseReturnKey =
      GlobalKey();
  final GlobalKey<_NestedTabViewState> _nestedSalesKey = GlobalKey();
  final GlobalKey<_NestedTabViewState> _nestedPurchaseKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    slider = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    slider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FixAppBar(),
      body: Column(
        children: [
          Container(
            height: 30,
            color: primary,
            child: TabBar(
              controller: slider,
              tabs: const [
                Tab(text: "SALES"),
                Tab(text: "CUSTOMER"),
                Tab(text: "PURCHASE"),
                Tab(text: "VENDOR"),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.amber,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: slider,
              children: [
                NestedTabView(
                  key: _nestedSalesKey,
                  tabs: const ["Sales List", "Sales Return"],
                  image: 'assets/images/sale2.png',
                  title: "Add sales to grow your business!",
                  salesKey: _salesKey,
                  salesReturnKey: _salesReturnKey,
                ),
                CustomerListView(
                  key: _customerKey,
                  fab: _buildCustomerFab(context),
                ),
                NestedTabView(
                  key: _nestedPurchaseKey,
                  tabs: const ["Purchase List", "Purchase Return"],
                  image: 'assets/images/purchase2.png',
                  title: 'Add PURCHASE and get started',
                  purchaseKey: _purchaseKey,
                  purchaseReturnKey: _purchaseReturnKey,
                ),
                VendorListView(key: _vendorKey, fab: _buildVendorFab(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  FloatingActionButton _buildCustomerFab(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.purple,
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddCustomer()),
        );
        if (result == true && _customerKey.currentState != null) {
          _customerKey.currentState!.refresh();
        }
      },
      icon: const Icon(Icons.person_add, color: Colors.white),
      label: const Text("ADD CUSTOMER", style: TextStyle(color: Colors.white)),
    );
  }

  FloatingActionButton _buildVendorFab(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.pink.shade700,
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddVendor()),
        );
        if (result == true && _vendorKey.currentState != null) {
          _vendorKey.currentState!.refresh();
        }
      },
      icon: const Icon(Icons.group, color: Colors.white),
      label: const Text("ADD VENDOR", style: TextStyle(color: Colors.white)),
    );
  }
}

// Sales List View
class SalesListView extends StatefulWidget {
  final Widget fab;
  const SalesListView({super.key, required this.fab});

  @override
  State<SalesListView> createState() => _SalesListViewState();
}

class _SalesListViewState extends BaseListViewState<SalesListView> {
  @override
  void initState() {
    super.initState();
    setEmptyContent(
      'assets/images/sale2.png',
      'Add SALES and grow your business!',
      [
        buildInfoRow(Icons.add_shopping_cart, Colors.green, 'Add Sales'),
        buildInfoRow(Icons.receipt, Colors.blue, 'View Receipts'),
        buildInfoRow(Icons.payment, Colors.orange, 'Pending Payments'),
      ],
    );
    _loadSales();
  }

  @override
  Future<void> refresh() => _loadSales();

  Future<void> _loadSales() async {
    setLoading(true);
    final sales = await SalesDB.getAllSales();
    if (mounted) {
      setItemList(sales);
      setLoading(false);
    }
  }

  Future<void> _deleteSale(int id) async {
    if (await showDeleteConfirmation(context, 'Sale')) {
      await SalesDB.deleteSale(id);
      await _loadSales();
    }
  }

  Future<void> _editSale(Map<String, dynamic> sale) async {
    setLoading(true);
    try {
      final items = await SalesItemDB.getSalesItemsBySalesId(sale['id']);
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AddSales(
                salesData: {
                  'id': sale['id'],
                  'sales_no': sale['sales_no'],
                  'date': sale['date'],
                  'customer_name': sale['customer_name'],
                  'total_amount': sale['total_amount'],
                  'payment_status': sale['payment_status'] ?? '',
                  'payment_method': sale['payment_method'] ?? '',
                  'remarks': sale['remarks'] ?? '',
                  'items': items,
                  'is_edit': true,
                },
              ),
        ),
      );
      if (result != null && result is Map && result['refresh'] == true) {
        await _loadSales();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading sale: $e')));
      }
    } finally {
      if (mounted) setLoading(false);
    }
  }

  Future<void> _generateAndShowSalesInvoice(Map<String, dynamic> sale) async {
    try {
      final saleId = sale['id'];
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final rawSale = await SalesDB.getSaleById(saleId);
      final rawItems = await SalesItemDB.getSalesItemsBySalesId(saleId);

      if (Navigator.canPop(context)) Navigator.pop(context);

      if (rawSale == null || rawItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sale or items not found!")),
          );
        }
        return;
      }

      final saleModel = SalesModel.fromMap(rawSale);
      final items = rawItems.map((e) => SalesItemModel.fromMap(e)).toList();
      final pdfData = await generateSalesInvoicePDF(saleModel, items);
      await Printing.layoutPdf(onLayout: (format) async => pdfData);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error generating invoice: $e")));
      }
    }
  }

  Future<void> _showSalesOptions(Map<String, dynamic> sale) async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Generate Invoice'),
                onTap: () async {
                  Navigator.pop(context);
                  await _generateAndShowSalesInvoice(sale);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Sale'),
                onTap: () async {
                  Navigator.pop(context);
                  await _shareSalesData(sale);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _shareSalesData(Map<String, dynamic> sale) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate PDF data
      final saleId = sale['id'];
      final rawSale = await SalesDB.getSaleById(saleId);
      final rawItems = await SalesItemDB.getSalesItemsBySalesId(saleId);

      if (rawSale == null || rawItems.isEmpty) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sale or items not found!")),
          );
        }
        return;
      }

      final saleModel = SalesModel.fromMap(rawSale);
      final items = rawItems.map((e) => SalesItemModel.fromMap(e)).toList();
      final pdfData = await generateSalesInvoicePDF(saleModel, items);

      // Save PDF to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/sale_${sale['sales_no']}.pdf');
      await file.writeAsBytes(pdfData);

      // Close loading dialog
      if (Navigator.canPop(context)) Navigator.pop(context);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Sales Invoice: ${sale['sales_no']} - ${sale['customer_name']} - Total: ₹${sale['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
        subject: 'Sales Invoice ${sale['sales_no']}',
      );

      // Clean up after some time (optional)
      Future.delayed(const Duration(seconds: 30), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error sharing sale: $e")));
      }
    }
  }

  // Date parsing method
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
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
          children: [
            itemList.isEmpty
                ? buildEmptyContent()
                : Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: SearchFilterWidget<Map<String, dynamic>>(
                    items: itemList,
                    hintText: 'Search by sales no, customer, amount...',
                    dateExtractor: (sale) => _parseDate(sale['date']),
                    emptyStateWidget: buildEmptyContent(),
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
                              (a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0),
                            ),
                      ),
                      FilterOption(
                        name: 'Oldest First',
                        icon: Icons.access_time,
                        filter: (items) {
                          final sorted = List<Map<String, dynamic>>.from(items);
                          sorted.sort((a, b) {
                            final dateA = _parseDate(a['date']);
                            final dateB = _parseDate(b['date']);
                            return (dateA ?? DateTime(0)).compareTo(
                              dateB ?? DateTime(0),
                            );
                          });
                          return sorted;
                        },
                      ),
                      FilterOption(
                        name: 'Newest First',
                        icon: Icons.access_time,
                        filter: (items) {
                          final sorted = List<Map<String, dynamic>>.from(items);
                          sorted.sort((a, b) {
                            final dateA = _parseDate(a['date']);
                            final dateB = _parseDate(b['date']);
                            return (dateB ?? DateTime(0)).compareTo(
                              dateA ?? DateTime(0),
                            );
                          });
                          return sorted;
                        },
                      ),
                      FilterOption(
                        name: 'Amount High to Low',
                        icon: Icons.arrow_downward,
                        filter:
                            (items) => List.from(items)..sort(
                              (a, b) => (b['total_amount'] ?? 0).compareTo(
                                a['total_amount'] ?? 0,
                              ),
                            ),
                      ),
                      FilterOption(
                        name: 'Amount Low to High',
                        icon: Icons.arrow_upward,
                        filter:
                            (items) => List.from(items)..sort(
                              (a, b) => (a['total_amount'] ?? 0).compareTo(
                                b['total_amount'] ?? 0,
                              ),
                            ),
                      ),
                    ],
                    customFilter:
                        (items, query) =>
                            items.where((sale) {
                              final saleNo =
                                  (sale['sales_no']?.toString() ?? '')
                                      .toLowerCase();
                              final customer =
                                  (sale['customer_name']?.toString() ?? '')
                                      .toLowerCase();
                              final amount =
                                  (sale['total_amount']?.toString() ?? '');
                              final date = (sale['date']?.toString() ?? '');
                              return saleNo.contains(query) ||
                                  customer.contains(query) ||
                                  amount.contains(query) ||
                                  date.contains(query);
                            }).toList(),
                    itemBuilder:
                        (context, sale) => CustomCard(
                          title: sale['sales_no']?.toString() ?? 'Sale',
                          details: [
                            if (sale['date'] != null) "Date: ${sale['date']}",
                            if (sale['customer_name'] != null)
                              "Customer: ${sale['customer_name']}",
                            "Total: ₹${(sale['total_amount']?.toStringAsFixed(2)) ?? '0.00'}",
                          ],
                          isRecent:
                              itemList.isNotEmpty &&
                              sale['id'] == itemList[0]['id'],
                          onEdit: () => _editSale(sale),
                          onDelete: () => _deleteSale(sale['id']),
                          onMore: () => _showSalesOptions(sale),
                        ),
                  ),
                ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(child: widget.fab),
            ),
          ],
        );
  }
}

// Purchase List View
class PurchaseListView extends StatefulWidget {
  final Widget fab;
  const PurchaseListView({super.key, required this.fab});

  @override
  State<PurchaseListView> createState() => _PurchaseListViewState();
}

class _PurchaseListViewState extends BaseListViewState<PurchaseListView> {
  @override
  void initState() {
    super.initState();
    setEmptyContent(
      'assets/images/purchase2.png',
      'Add PURCHASES and get started',
      [
        buildInfoRow(Icons.add_business, Colors.blue, 'Add Purchases'),
        buildInfoRow(Icons.receipt, Colors.green, 'View Receipts'),
        buildInfoRow(Icons.payment, Colors.orange, 'Pending Payments'),
      ],
    );
    _loadPurchases();
  }

  @override
  Future<void> refresh() => _loadPurchases();

  Future<void> _loadPurchases() async {
    setLoading(true);
    final purchases = await PurchaseDB.getAllPurchases();
    if (mounted) {
      setItemList(purchases);
      setLoading(false);
    }
  }

  Future<void> _deletePurchase(int id) async {
    if (await showDeleteConfirmation(context, 'Purchase')) {
      await PurchaseDB.deletePurchase(id);
      await _loadPurchases();
    }
  }

  Future<void> _editPurchase(Map<String, dynamic> purchase) async {
    setLoading(true);
    try {
      final items = await PurchaseItemDB.getItemsByPurchaseId(purchase['id']);
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AddPurchase(
                purchaseData: {
                  'id': purchase['id'],
                  'purchase_no': purchase['purchase_no'],
                  'date': purchase['date'],
                  'vendor_name': purchase['vendor_name'],
                  'total_amount': purchase['total_amount'],
                  'payment_status': purchase['payment_status'] ?? '',
                  'payment_method': purchase['payment_method'] ?? '',
                  'remarks': purchase['remarks'] ?? '',
                  'items': items,
                  'is_edit': true,
                },
              ),
        ),
      );
      if (result != null && result is Map && result['refresh'] == true) {
        await _loadPurchases();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading purchase: $e')));
      }
    } finally {
      if (mounted) setLoading(false);
    }
  }

  Future<void> _generateAndShowInvoice(Map<String, dynamic> purchase) async {
    try {
      final purchaseId = purchase['id'];
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final rawPurchase = await PurchaseDB.getPurchaseById(purchaseId);
      final rawItems = await PurchaseItemDB.getItemsByPurchaseId(purchaseId);

      if (Navigator.canPop(context)) Navigator.pop(context);

      if (rawPurchase == null || rawItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Purchase or items not found!")),
          );
        }
        return;
      }

      final purchaseModel = PurchaseModel.fromMap(rawPurchase);
      final items = rawItems.map((e) => PurchaseItemModel.fromMap(e)).toList();
      final pdfData = await generateInvoicePDF(purchaseModel, items);
      await Printing.layoutPdf(onLayout: (format) async => pdfData);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error generating invoice: $e")));
      }
    }
  }

  void _showPurchaseOptions(Map<String, dynamic> purchase) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Generate Invoice'),
                onTap: () async {
                  Navigator.pop(context);
                  await _generateAndShowInvoice(purchase);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Purchase'),
                onTap: () async {
                  Navigator.pop(context);
                  await _sharePurchaseData(purchase);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _sharePurchaseData(Map<String, dynamic> purchase) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate PDF data
      final purchaseId = purchase['id'];
      final rawPurchase = await PurchaseDB.getPurchaseById(purchaseId);
      final rawItems = await PurchaseItemDB.getItemsByPurchaseId(purchaseId);

      if (rawPurchase == null || rawItems.isEmpty) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Purchase or items not found!")),
          );
        }
        return;
      }

      final purchaseModel = PurchaseModel.fromMap(rawPurchase);
      final items = rawItems.map((e) => PurchaseItemModel.fromMap(e)).toList();
      final pdfData = await generateInvoicePDF(purchaseModel, items);

      // Save PDF to temporary file
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/purchase_${purchase['purchase_no']}.pdf',
      );
      await file.writeAsBytes(pdfData);

      // Close loading dialog
      if (Navigator.canPop(context)) Navigator.pop(context);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Purchase Invoice: ${purchase['purchase_no']} - ${purchase['vendor_name']} - Total: ₹${purchase['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
        subject: 'Purchase Invoice ${purchase['purchase_no']}',
      );

      // Clean up after some time (optional)
      Future.delayed(const Duration(seconds: 30), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error sharing purchase: $e")));
      }
    }
  }

  // Date parsing method
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
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
          children: [
            itemList.isEmpty
                ? buildEmptyContent()
                : Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: SearchFilterWidget<Map<String, dynamic>>(
                    items: itemList,
                    hintText: 'Search by purchase no, vendor, amount...',
                    dateExtractor: (purchase) => _parseDate(purchase['date']),
                    emptyStateWidget: buildEmptyContent(),
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
                              (a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0),
                            ),
                      ),
                      FilterOption(
                        name: 'Oldest First',
                        icon: Icons.access_time,
                        filter: (items) {
                          final sorted = List<Map<String, dynamic>>.from(items);
                          sorted.sort((a, b) {
                            final dateA = _parseDate(a['date']);
                            final dateB = _parseDate(b['date']);
                            return (dateA ?? DateTime(0)).compareTo(
                              dateB ?? DateTime(0),
                            );
                          });
                          return sorted;
                        },
                      ),
                      FilterOption(
                        name: 'Newest First',
                        icon: Icons.access_time,
                        filter: (items) {
                          final sorted = List<Map<String, dynamic>>.from(items);
                          sorted.sort((a, b) {
                            final dateA = _parseDate(a['date']);
                            final dateB = _parseDate(b['date']);
                            return (dateB ?? DateTime(0)).compareTo(
                              dateA ?? DateTime(0),
                            );
                          });
                          return sorted;
                        },
                      ),
                      FilterOption(
                        name: 'Amount High to Low',
                        icon: Icons.arrow_downward,
                        filter:
                            (items) => List.from(items)..sort(
                              (a, b) => (b['total_amount'] ?? 0).compareTo(
                                a['total_amount'] ?? 0,
                              ),
                            ),
                      ),
                      FilterOption(
                        name: 'Amount Low to High',
                        icon: Icons.arrow_upward,
                        filter:
                            (items) => List.from(items)..sort(
                              (a, b) => (a['total_amount'] ?? 0).compareTo(
                                b['total_amount'] ?? 0,
                              ),
                            ),
                      ),
                    ],
                    customFilter:
                        (items, query) =>
                            items.where((purchase) {
                              final purchaseNo =
                                  (purchase['purchase_no']?.toString() ?? '')
                                      .toLowerCase();
                              final vendor =
                                  (purchase['vendor_name']?.toString() ?? '')
                                      .toLowerCase();
                              final amount =
                                  (purchase['total_amount']?.toString() ?? '');
                              final date = (purchase['date']?.toString() ?? '');
                              return purchaseNo.contains(query) ||
                                  vendor.contains(query) ||
                                  amount.contains(query) ||
                                  date.contains(query);
                            }).toList(),
                    itemBuilder:
                        (context, purchase) => CustomCard(
                          title:
                              purchase['purchase_no']?.toString() ?? 'Purchase',
                          details: [
                            if (purchase['date'] != null)
                              "Date: ${purchase['date']}",
                            if (purchase['vendor_name'] != null)
                              "Vendor: ${purchase['vendor_name']}",
                            "Total: ₹${(purchase['total_amount']?.toStringAsFixed(2)) ?? '0.00'}",
                          ],
                          isRecent:
                              itemList.isNotEmpty &&
                              purchase['id'] == itemList[0]['id'],
                          onEdit: () => _editPurchase(purchase),
                          onDelete: () => _deletePurchase(purchase['id']),
                          onMore: () => _showPurchaseOptions(purchase),
                        ),
                  ),
                ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(child: widget.fab),
            ),
          ],
        );
  }
}

// Vendor List View
class VendorListView extends StatefulWidget {
  final Widget fab;
  const VendorListView({super.key, required this.fab});

  @override
  State<VendorListView> createState() => _VendorListViewState();
}

class _VendorListViewState extends BaseListViewState<VendorListView> {
  @override
  void initState() {
    super.initState();
    setEmptyContent(
      'assets/images/vendor2.png',
      'Add VENDORS and get started',
      [
        buildInfoRow(Icons.group_add, Colors.pink, 'Add Vendors'),
        buildInfoRow(Icons.phone, Colors.blue, 'Contact Vendors'),
        buildInfoRow(Icons.warning, Colors.red, 'Pending Payments'),
      ],
    );
    _loadVendors();
  }

  @override
  Future<void> refresh() => _loadVendors();

  Future<void> _loadVendors() async {
    setLoading(true);
    final vendors = await VendorDB.getAllVendors();
    if (mounted) {
      setItemList(vendors);
      setLoading(false);
    }
  }

  Future<void> _deleteVendor(int id) async {
    if (await showDeleteConfirmation(context, 'Vendor')) {
      await VendorDB.deleteVendor(id);
      await _loadVendors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
          children: [
            itemList.isEmpty
                ? buildEmptyContent()
                : Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: SearchFilterWidget<Map<String, dynamic>>(
                    items: itemList,
                    hintText: 'Search by vendor name, phone...',
                    emptyStateWidget: buildEmptyContent(),
                    customFilter:
                        (items, query) =>
                            items.where((vendor) {
                              final name =
                                  (vendor['name']?.toString() ?? '')
                                      .toLowerCase();
                              final phone = (vendor['phone']?.toString() ?? '');
                              final email =
                                  (vendor['email']?.toString() ?? '')
                                      .toLowerCase();
                              final address =
                                  (vendor['address']?.toString() ?? '')
                                      .toLowerCase();
                              return name.contains(query) ||
                                  phone.contains(query) ||
                                  email.contains(query) ||
                                  address.contains(query);
                            }).toList(),
                    itemBuilder:
                        (context, vendor) => CustomCard(
                          title: vendor['name']?.toString() ?? 'Vendor',
                          details: [
                            if (vendor['phone']?.toString().isNotEmpty ?? false)
                              "Phone: ${vendor['phone']}",
                            if (vendor['email']?.toString().isNotEmpty ?? false)
                              "Email: ${vendor['email']}",
                            if (vendor['address']?.toString().isNotEmpty ??
                                false)
                              "Address: ${vendor['address']}",
                          ],
                          isRecent:
                              itemList.isNotEmpty &&
                              vendor['id'] == itemList[0]['id'],
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddVendor(vendorData: vendor),
                              ),
                            );
                            if (result == true) _loadVendors();
                          },
                          onDelete: () => _deleteVendor(vendor['id']),
                        ),
                  ),
                ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(child: widget.fab),
            ),
          ],
        );
  }
}

// Customer List View
class CustomerListView extends StatefulWidget {
  final Widget fab;
  const CustomerListView({super.key, required this.fab});

  @override
  State<CustomerListView> createState() => _CustomerListViewState();
}

class _CustomerListViewState extends BaseListViewState<CustomerListView> {
  @override
  void initState() {
    super.initState();
    setEmptyContent(
      'assets/images/customer.png',
      'Add CUSTOMERS and grow your business!',
      [
        buildInfoRow(Icons.person_add, Colors.purple, 'Add Customers'),
        buildInfoRow(Icons.phone, Colors.blue, 'Contact Customers'),
        buildInfoRow(Icons.payment, Colors.green, 'Customer Payments'),
      ],
    );
    _loadCustomers();
  }

  @override
  Future<void> refresh() => _loadCustomers();

  Future<void> _loadCustomers() async {
    setLoading(true);
    final customers = await CustomerDB.getAllCustomers();
    if (mounted) {
      setItemList(customers);
      setLoading(false);
    }
  }

  Future<void> _deleteCustomer(int id) async {
    if (await showDeleteConfirmation(context, 'Customer')) {
      await CustomerDB.deleteCustomer(id);
      await _loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
          children: [
            itemList.isEmpty
                ? buildEmptyContent()
                : Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: SearchFilterWidget<Map<String, dynamic>>(
                    items: itemList,
                    hintText: 'Search by customer name, phone...',
                    emptyStateWidget: buildEmptyContent(),
                    customFilter:
                        (items, query) =>
                            items.where((customer) {
                              final name =
                                  (customer['name']?.toString() ?? '')
                                      .toLowerCase();
                              final phone =
                                  (customer['phone']?.toString() ?? '');
                              final email =
                                  (customer['email']?.toString() ?? '')
                                      .toLowerCase();
                              final address =
                                  (customer['address']?.toString() ?? '')
                                      .toLowerCase();
                              return name.contains(query) ||
                                  phone.contains(query) ||
                                  email.contains(query) ||
                                  address.contains(query);
                            }).toList(),
                    itemBuilder:
                        (context, customer) => CustomCard(
                          title: customer['name']?.toString() ?? 'Customer',
                          details: [
                            if (customer['phone']?.toString().isNotEmpty ??
                                false)
                              "Phone: ${customer['phone']}",
                            if (customer['email']?.toString().isNotEmpty ??
                                false)
                              "Email: ${customer['email']}",
                            if (customer['address']?.toString().isNotEmpty ??
                                false)
                              "Address: ${customer['address']}",
                          ],
                          isRecent:
                              itemList.isNotEmpty &&
                              customer['id'] == itemList[0]['id'],
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AddCustomer(customerData: customer),
                              ),
                            );
                            if (result == true) _loadCustomers();
                          },
                          onDelete: () => _deleteCustomer(customer['id']),
                        ),
                  ),
                ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(child: widget.fab),
            ),
          ],
        );
  }
}

// Nested Tab View
class NestedTabView extends StatefulWidget {
  final List<String> tabs;
  final String image;
  final String title;
  final GlobalKey<_PurchaseListViewState>? purchaseKey;
  final GlobalKey<_PurchaseReturnListViewState>? purchaseReturnKey;
  final GlobalKey<_SalesListViewState>? salesKey;
  final GlobalKey<_SalesReturnListViewState>? salesReturnKey;

  const NestedTabView({
    super.key,
    required this.tabs,
    required this.image,
    required this.title,
    this.purchaseKey,
    this.purchaseReturnKey,
    this.salesKey,
    this.salesReturnKey,
  });

  @override
  State<NestedTabView> createState() => _NestedTabViewState();
}

class _NestedTabViewState extends State<NestedTabView>
    with SingleTickerProviderStateMixin {
  late TabController nestedController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    nestedController = TabController(length: widget.tabs.length, vsync: this);
    nestedController.addListener(() {
      setState(() => _currentTabIndex = nestedController.index);
    });
  }

  @override
  void dispose() {
    nestedController.dispose();
    super.dispose();
  }

  Widget _getFabForCurrentTab() {
    if (widget.purchaseKey != null) {
      return _currentTabIndex == 0
          ? FloatingActionButton.extended(
            backgroundColor: Colors.blue.shade800,
            onPressed: () async {
              final result = await Navigator.pushNamed(context, "add_purchase");
              if (result != null &&
                  result is Map &&
                  result['refresh'] == true) {
                widget.purchaseKey?.currentState?.refresh();
              }
            },
            icon: const Icon(Icons.add_business, color: Colors.white),
            label: const Text(
              "ADD PURCHASE",
              style: TextStyle(color: Colors.white),
            ),
          )
          : FloatingActionButton.extended(
            backgroundColor: Colors.orange.shade800,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPurchaseReturn(),
                ),
              );
              if (result == true &&
                  widget.purchaseReturnKey?.currentState != null) {
                await widget.purchaseReturnKey?.currentState?.refresh();
              }
            },
            icon: const Icon(Icons.assignment_return, color: Colors.white),
            label: const Text(
              "ADD RETURN",
              style: TextStyle(color: Colors.white),
            ),
          );
    } else if (widget.salesKey != null) {
      return _currentTabIndex == 0
          ? FloatingActionButton.extended(
            backgroundColor: Colors.green.shade900,
            onPressed: () async {
              final result = await Navigator.pushNamed(context, "add_sales");
              if (result != null &&
                  result is Map &&
                  result['refresh'] == true) {
                widget.salesKey?.currentState?.refresh();
              }
            },
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            label: const Text(
              "ADD NEW SALE",
              style: TextStyle(color: Colors.white),
            ),
          )
          : FloatingActionButton.extended(
            backgroundColor: Colors.red.shade800,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddSalesReturn()),
              );
              if (result == true) {
                if (widget.salesReturnKey?.currentState != null) {
                  await widget.salesReturnKey?.currentState?.refresh();
                }
                if (mounted) setState(() {});
              }
            },
            icon: const Icon(Icons.undo, color: Colors.white),
            label: const Text(
              "ADD RETURN",
              style: TextStyle(color: Colors.white),
            ),
          );
    }
    return const SizedBox.shrink();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: nestedController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          indicatorColor: primary,
          tabs: widget.tabs.map((e) => Tab(text: e)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: nestedController,
            children:
                widget.tabs.map((tab) {
                  if (widget.purchaseKey != null && tab == "Purchase List") {
                    return PurchaseListView(
                      key: widget.purchaseKey,
                      fab: _getFabForCurrentTab(),
                    );
                  }
                  if (widget.purchaseReturnKey != null &&
                      tab == "Purchase Return") {
                    return PurchaseReturnListView(
                      key: widget.purchaseReturnKey,
                      fab: _getFabForCurrentTab(),
                    );
                  }
                  if (widget.salesKey != null && tab == "Sales List") {
                    return SalesListView(
                      key: widget.salesKey,
                      fab: _getFabForCurrentTab(),
                    );
                  }
                  if (widget.salesReturnKey != null && tab == "Sales Return") {
                    return SalesReturnListView(
                      key: widget.salesReturnKey,
                      fab: _getFabForCurrentTab(),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        Image.asset(widget.image, width: 300, height: 320),
                        Text(
                          tab == "Sales Return"
                              ? "Add SALES RETURNS to manage your business!"
                              : "Add PURCHASE RETURNS to manage your business!",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children:
                                _currentTabIndex == 1
                                    ? widget.salesKey != null
                                        ? [
                                          _buildInfoRow(
                                            Icons.undo,
                                            Colors.red,
                                            'Manage Sales Returns',
                                          ),
                                          _buildInfoRow(
                                            Icons.receipt,
                                            Colors.blue,
                                            'View Return Receipts',
                                          ),
                                          _buildInfoRow(
                                            Icons.money_off,
                                            Colors.orange,
                                            'Process Refunds',
                                          ),
                                        ]
                                        : [
                                          _buildInfoRow(
                                            Icons.assignment_return,
                                            Colors.orange,
                                            'Manage Purchase Returns',
                                          ),
                                          _buildInfoRow(
                                            Icons.receipt,
                                            Colors.green,
                                            'View Return Receipts',
                                          ),
                                          _buildInfoRow(
                                            Icons.money,
                                            Colors.blue,
                                            'Request Refunds',
                                          ),
                                        ]
                                    : [],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

// Sales Return List View
class SalesReturnListView extends StatefulWidget {
  final Widget fab;
  const SalesReturnListView({super.key, required this.fab});

  @override
  State<SalesReturnListView> createState() => _SalesReturnListViewState();
}

class _SalesReturnListViewState extends BaseListViewState<SalesReturnListView> {
  @override
  void initState() {
    super.initState();
    setEmptyContent(
      'assets/images/sale_return.png',
      'Add SALES RETURNS to manage your business!',
      [
        buildInfoRow(Icons.undo, Colors.red, 'Process Returns'),
        buildInfoRow(Icons.receipt, Colors.blue, 'View Return Receipts'),
        buildInfoRow(Icons.money_off, Colors.orange, 'Process Refunds'),
      ],
    );
    _loadReturns();
  }

  @override
  Future<void> refresh() => _loadReturns();

  Future<void> _loadReturns() async {
    setLoading(true);
    final returns = await SalesReturnDB.getAllReturns();
    if (mounted) {
      setItemList(returns);
      setLoading(false);
    }
  }

  Future<void> _editReturn(Map<String, dynamic> returnData) async {
    setLoading(true);
    try {
      final returnItems =
          (await SalesReturnItemDB.getReturnItemsByReturnId(
            returnData['id'],
          )).map((item) => Map<String, dynamic>.from(item)).toList();

      Map<String, dynamic>? originalSales;
      if (returnData['original_sales_id'] != null) {
        originalSales = await SalesDB.getSaleById(
          returnData['original_sales_id'],
        );
        if (originalSales != null) {
          final originalItems = await SalesItemDB.getSalesItemsBySalesId(
            returnData['original_sales_id'],
          );
          originalSales = {
            ...originalSales,
            'items':
                originalItems
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList(),
          };
        }
      }

      final dataToPass = {
        if (originalSales != null) ...originalSales,
        'id': returnData['id'],
        'return_no': returnData['return_no'],
        'date': returnData['date'],
        'customer_name': returnData['customer_name'],
        'original_sales_id': returnData['original_sales_id'],
        'original_sales_no': returnData['original_sales_no'],
        'total_amount': returnData['total_amount'],
        'payment_status': returnData['payment_status'] ?? '',
        'payment_method': returnData['payment_method'] ?? '',
        'remarks': returnData['remarks'] ?? '',
        'items': returnItems,
        'is_edit': true,
      };

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddSalesReturn(originalSalesData: dataToPass),
        ),
      );

      if (result == true) await _loadReturns();
    } catch (e, stackTrace) {
      debugPrint('Error in _editReturn: $e');
      debugPrint(stackTrace.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading return details: $e')),
        );
      }
    } finally {
      if (mounted) setLoading(false);
    }
  }

  Future<void> _deleteReturn(int id) async {
    if (await showDeleteConfirmation(context, 'Return')) {
      await SalesReturnDB.deleteReturn(id);
      await _loadReturns();
    }
  }

  Future<void> _generateAndShowSalesReturnInvoice(
    Map<String, dynamic> saleReturn,
  ) async {
    try {
      final saleReturnId = saleReturn['id'];
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final rawSaleReturn = await SalesReturnDB.getReturnById(saleReturnId);
      final rawItems = await SalesReturnItemDB.getReturnItemsByReturnId(
        saleReturnId,
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

      if (rawSaleReturn == null || rawItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sales return or items not found!")),
          );
        }
        return;
      }

      final saleReturnModel = SalesReturnModel.fromMap(rawSaleReturn);
      final items =
          rawItems.map((e) => SalesReturnItemModel.fromMap(e)).toList();
      final pdfData = await generateSalesReturnInvoicePDF(
        saleReturnModel,
        items,
      );
      await Printing.layoutPdf(onLayout: (format) async => pdfData);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating return invoice: $e")),
        );
      }
    }
  }

  void _showReturnOptions(Map<String, dynamic> returnData) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Generate Return Invoice'),
                onTap: () async {
                  Navigator.pop(context);
                  await _generateAndShowSalesReturnInvoice(returnData);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Return'),
                onTap: () async {
                  Navigator.pop(context);
                  await _shareSalesReturnData(returnData);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _shareSalesReturnData(Map<String, dynamic> returnData) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate PDF data
      final returnId = returnData['id'];
      final rawReturn = await SalesReturnDB.getReturnById(returnId);
      final rawItems = await SalesReturnItemDB.getReturnItemsByReturnId(
        returnId,
      );

      if (rawReturn == null || rawItems.isEmpty) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sales return or items not found!")),
          );
        }
        return;
      }

      final returnModel = SalesReturnModel.fromMap(rawReturn);
      final items =
          rawItems.map((e) => SalesReturnItemModel.fromMap(e)).toList();
      final pdfData = await generateSalesReturnInvoicePDF(returnModel, items);

      // Save PDF to temporary file
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/sales_return_${returnData['return_no']}.pdf',
      );
      await file.writeAsBytes(pdfData);

      // Close loading dialog
      if (Navigator.canPop(context)) Navigator.pop(context);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Sales Return: ${returnData['return_no']} - ${returnData['customer_name']} - Total: ₹${returnData['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
        subject: 'Sales Return ${returnData['return_no']}',
      );

      // Clean up after some time (optional)
      Future.delayed(const Duration(seconds: 30), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sharing sales return: $e")),
        );
      }
    }
  }

  // Date parsing method
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
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
          children: [
            itemList.isEmpty
                ? buildEmptyContent()
                : Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: SearchFilterWidget<Map<String, dynamic>>(
                    items: itemList,
                    hintText: 'Search by return no, customer, amount...',
                    dateExtractor: (ret) => _parseDate(ret['date']),
                    emptyStateWidget: buildEmptyContent(),
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
                              (a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0),
                            ),
                      ),
                      FilterOption(
                        name: 'Oldest First',
                        icon: Icons.access_time,
                        filter: (items) {
                          final sorted = List<Map<String, dynamic>>.from(items);
                          sorted.sort((a, b) {
                            final dateA = _parseDate(a['date']);
                            final dateB = _parseDate(b['date']);
                            return (dateA ?? DateTime(0)).compareTo(
                              dateB ?? DateTime(0),
                            );
                          });
                          return sorted;
                        },
                      ),
                      FilterOption(
                        name: 'Newest First',
                        icon: Icons.access_time,
                        filter: (items) {
                          final sorted = List<Map<String, dynamic>>.from(items);
                          sorted.sort((a, b) {
                            final dateA = _parseDate(a['date']);
                            final dateB = _parseDate(b['date']);
                            return (dateB ?? DateTime(0)).compareTo(
                              dateA ?? DateTime(0),
                            );
                          });
                          return sorted;
                        },
                      ),
                      FilterOption(
                        name: 'Amount High to Low',
                        icon: Icons.arrow_downward,
                        filter:
                            (items) => List.from(items)..sort(
                              (a, b) => (b['total_amount'] ?? 0).compareTo(
                                a['total_amount'] ?? 0,
                              ),
                            ),
                      ),
                      FilterOption(
                        name: 'Amount Low to High',
                        icon: Icons.arrow_upward,
                        filter:
                            (items) => List.from(items)..sort(
                              (a, b) => (a['total_amount'] ?? 0).compareTo(
                                b['total_amount'] ?? 0,
                              ),
                            ),
                      ),
                    ],
                    customFilter:
                        (items, query) =>
                            items.where((ret) {
                              final returnNo =
                                  (ret['return_no']?.toString() ?? '')
                                      .toLowerCase();
                              final customer =
                                  (ret['customer_name']?.toString() ?? '')
                                      .toLowerCase();
                              final amount =
                                  (ret['total_amount']?.toString() ?? '');
                              final date = (ret['date']?.toString() ?? '');
                              return returnNo.contains(query) ||
                                  customer.contains(query) ||
                                  amount.contains(query) ||
                                  date.contains(query);
                            }).toList(),
                    itemBuilder:
                        (context, ret) => CustomCard(
                          title: ret['return_no']?.toString() ?? 'Return',
                          details: [
                            if (ret['date'] != null) "Date: ${ret['date']}",
                            if (ret['customer_name'] != null)
                              "Customer: ${ret['customer_name']}",
                            "Total: ₹${(ret['total_amount']?.toStringAsFixed(2)) ?? '0.00'}",
                          ],
                          isRecent:
                              itemList.isNotEmpty &&
                              ret['id'] == itemList[0]['id'],
                          onEdit: () => _editReturn(ret),
                          onDelete: () => _deleteReturn(ret['id']),
                          onMore: () => _showReturnOptions(ret),
                        ),
                  ),
                ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(child: widget.fab),
            ),
          ],
        );
  }
}

// Purchase Return List View
class PurchaseReturnListView extends StatefulWidget {
  final Widget fab;
  const PurchaseReturnListView({super.key, required this.fab});

  @override
  State<PurchaseReturnListView> createState() => _PurchaseReturnListViewState();
}

class _PurchaseReturnListViewState
    extends BaseListViewState<PurchaseReturnListView> {
  @override
  void initState() {
    super.initState();
    setEmptyContent(
      'assets/images/purchase_return.png',
      'Add PURCHASE RETURNS to manage your business!',
      [
        buildInfoRow(Icons.assignment_return, Colors.orange, 'Process Returns'),
        buildInfoRow(Icons.receipt, Colors.green, 'View Return Receipts'),
        buildInfoRow(Icons.money, Colors.blue, 'Request Refunds'),
      ],
    );
    _loadReturns();
  }

  @override
  Future<void> refresh() => _loadReturns();

  Future<void> _loadReturns() async {
    setLoading(true);
    final returns = await PurchaseReturnDB.getAllReturns();
    if (mounted) {
      setItemList(returns);
      setLoading(false);
    }
  }

  Future<void> _editReturn(Map<String, dynamic> returnData) async {
    setLoading(true);
    try {
      final returnItems =
          (await PurchaseReturnItemDB.getReturnItemsByReturnId(
            returnData['id'],
          )).map((item) => Map<String, dynamic>.from(item)).toList();

      Map<String, dynamic>? originalPurchase;
      if (returnData['original_purchase_id'] != null) {
        originalPurchase = await PurchaseDB.getPurchaseById(
          returnData['original_purchase_id'],
        );
        if (originalPurchase != null) {
          final originalItems = await PurchaseItemDB.getItemsByPurchaseId(
            returnData['original_purchase_id'],
          );
          originalPurchase = {
            ...originalPurchase,
            'items':
                originalItems
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList(),
          };
        }
      }

      final dataToPass = {
        if (originalPurchase != null) ...originalPurchase,
        'id': returnData['id'],
        'return_no': returnData['return_no'],
        'date': returnData['date'],
        'supplier_name': returnData['supplier_name'],
        'original_purchase_id': returnData['original_purchase_id'],
        'original_purchase_no': returnData['original_purchase_no'],
        'total_amount': returnData['total_amount'],
        'payment_status': returnData['payment_status'] ?? '',
        'payment_method': returnData['payment_method'] ?? '',
        'remarks': returnData['remarks'] ?? '',
        'items': returnItems,
        'is_edit': true,
      };

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AddPurchaseReturn(originalPurchaseData: dataToPass),
        ),
      );

      if (result == true) await _loadReturns();
    } catch (e, stackTrace) {
      debugPrint('Error in _editReturn: $e');
      debugPrint(stackTrace.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading return details: $e')),
        );
      }
    } finally {
      if (mounted) setLoading(false);
    }
  }

  Future<void> _deleteReturn(int id) async {
    if (await showDeleteConfirmation(context, 'Return')) {
      await PurchaseReturnDB.deleteReturn(id);
      await _loadReturns();
    }
  }

  Future<void> _generateAndShowPurchaseReturnInvoice(
    Map<String, dynamic> purchaseReturn,
  ) async {
    try {
      final purchaseReturnId = purchaseReturn['id'];
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final rawPurchaseReturn = await PurchaseReturnDB.getReturnById(
        purchaseReturnId,
      );
      final rawItems = await PurchaseReturnItemDB.getReturnItemsByReturnId(
        purchaseReturnId,
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

      if (rawPurchaseReturn == null || rawItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Purchase return or items not found!"),
            ),
          );
        }
        return;
      }

      final purchaseReturnModel = PurchaseReturnModel.fromMap(
        rawPurchaseReturn,
      );
      final items =
          rawItems.map((e) => PurchaseReturnItemModel.fromMap(e)).toList();
      final pdfData = await generatePurchaseReturnInvoicePDF(
        purchaseReturnModel,
        items,
      );
      await Printing.layoutPdf(onLayout: (format) async => pdfData);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating return invoice: $e")),
        );
      }
    }
  }

  void _showReturnOptions(Map<String, dynamic> returnData) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Generate Return Invoice'),
                onTap: () async {
                  Navigator.pop(context);
                  await _generateAndShowPurchaseReturnInvoice(returnData);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Return'),
                onTap: () async {
                  Navigator.pop(context);
                  await _sharePurchaseReturnData(returnData);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _sharePurchaseReturnData(Map<String, dynamic> returnData) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate PDF data
      final returnId = returnData['id'];
      final rawReturn = await PurchaseReturnDB.getReturnById(returnId);
      final rawItems = await PurchaseReturnItemDB.getReturnItemsByReturnId(
        returnId,
      );

      if (rawReturn == null || rawItems.isEmpty) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Purchase return or items not found!"),
            ),
          );
        }
        return;
      }

      final returnModel = PurchaseReturnModel.fromMap(rawReturn);
      final items =
          rawItems.map((e) => PurchaseReturnItemModel.fromMap(e)).toList();
      final pdfData = await generatePurchaseReturnInvoicePDF(
        returnModel,
        items,
      );

      // Save PDF to temporary file
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/purchase_return_${returnData['return_no']}.pdf',
      );
      await file.writeAsBytes(pdfData);

      // Close loading dialog
      if (Navigator.canPop(context)) Navigator.pop(context);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Purchase Return: ${returnData['return_no']} - ${returnData['supplier_name']} - Total: ₹${returnData['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
        subject: 'Purchase Return ${returnData['return_no']}',
      );

      // Clean up after some time (optional)
      Future.delayed(const Duration(seconds: 30), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sharing purchase return: $e")),
        );
      }
    }
  }

  // Date parsing method
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
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
          children: [
            itemList.isEmpty
                ? buildEmptyContent()
                : Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: SearchFilterWidget<Map<String, dynamic>>(
                    items: itemList,
                    hintText: 'Search by return no, supplier, amount...',
                    dateExtractor: (ret) => _parseDate(ret['date']),
                    emptyStateWidget: buildEmptyContent(),
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
                              (a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0),
                            ),
                      ),
                      FilterOption(
                        name: 'Oldest First',
                        icon: Icons.access_time,
                        filter: (items) {
                          final sorted = List<Map<String, dynamic>>.from(items);
                          sorted.sort((a, b) {
                            final dateA = _parseDate(a['date']);
                            final dateB = _parseDate(b['date']);
                            return (dateA ?? DateTime(0)).compareTo(
                              dateB ?? DateTime(0),
                            );
                          });
                          return sorted;
                        },
                      ),
                      FilterOption(
                        name: 'Newest First',
                        icon: Icons.access_time,
                        filter: (items) {
                          final sorted = List<Map<String, dynamic>>.from(items);
                          sorted.sort((a, b) {
                            final dateA = _parseDate(a['date']);
                            final dateB = _parseDate(b['date']);
                            return (dateB ?? DateTime(0)).compareTo(
                              dateA ?? DateTime(0),
                            );
                          });
                          return sorted;
                        },
                      ),
                      FilterOption(
                        name: 'Amount High to Low',
                        icon: Icons.arrow_downward,
                        filter:
                            (items) => List.from(items)..sort(
                              (a, b) => (b['total_amount'] ?? 0).compareTo(
                                a['total_amount'] ?? 0,
                              ),
                            ),
                      ),
                      FilterOption(
                        name: 'Amount Low to High',
                        icon: Icons.arrow_upward,
                        filter:
                            (items) => List.from(items)..sort(
                              (a, b) => (a['total_amount'] ?? 0).compareTo(
                                b['total_amount'] ?? 0,
                              ),
                            ),
                      ),
                    ],
                    customFilter:
                        (items, query) =>
                            items.where((ret) {
                              final returnNo =
                                  (ret['return_no']?.toString() ?? '')
                                      .toLowerCase();
                              final supplier =
                                  (ret['supplier_name']?.toString() ?? '')
                                      .toLowerCase();
                              final amount =
                                  (ret['total_amount']?.toString() ?? '');
                              final date = (ret['date']?.toString() ?? '');
                              return returnNo.contains(query) ||
                                  supplier.contains(query) ||
                                  amount.contains(query) ||
                                  date.contains(query);
                            }).toList(),
                    itemBuilder:
                        (context, ret) => CustomCard(
                          title: ret['return_no']?.toString() ?? 'Return',
                          details: [
                            if (ret['date'] != null) "Date: ${ret['date']}",
                            if (ret['supplier_name'] != null)
                              "Supplier: ${ret['supplier_name']}",
                            "Total: ₹${(ret['total_amount']?.toStringAsFixed(2)) ?? '0.00'}",
                          ],
                          isRecent:
                              itemList.isNotEmpty &&
                              ret['id'] == itemList[0]['id'],
                          onEdit: () => _editReturn(ret),
                          onDelete: () => _deleteReturn(ret['id']),
                          onMore: () => _showReturnOptions(ret),
                        ),
                  ),
                ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(child: widget.fab),
            ),
          ],
        );
  }
}
