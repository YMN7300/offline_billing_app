import 'package:flutter/material.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/common/components/custom_files/custom_selector_bottom_sheet.dart';
import 'package:offline_billing/common/components/custom_files/custom_text_field.dart';
import 'package:offline_billing/database/customer_db.dart';
import 'package:offline_billing/database/sales_db.dart';
import 'package:offline_billing/database/sales_item_db.dart';

import '../../../database/db/database_helper.dart';
import '../../../database/product_db.dart';

class AddSales extends StatefulWidget {
  final Map<String, dynamic>? salesData;

  const AddSales({super.key, this.salesData});

  @override
  State<AddSales> createState() => _AddSalesState();
}

class _AddSalesState extends State<AddSales> {
  // Controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _salesController = TextEditingController();
  final TextEditingController _paymentStatusController =
      TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  // State variables
  DateTime _selectedDate = DateTime.now();
  bool _hasAddedItems = false;
  List<Map<String, dynamic>> _items = [];
  double _totalAmount = 0.0;
  List<Map<String, dynamic>> _customerOptions = [];
  bool _isEditing = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _dateController.text =
        "${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}";
    _loadCustomerOptions();

    // Check if editing existing sales
    if (widget.salesData != null) {
      _isEditing = true;
      _isLoadingData = true;
      // Delay slightly to allow UI to build
      Future.delayed(Duration.zero, () async {
        await _initializeEditMode();
        if (mounted) {
          setState(() => _isLoadingData = false);
        }
      });
    } else {
      // Only generate sales number for new sales
      _generateSalesNumber();
    }
  }

  Future<void> _generateSalesNumber() async {
    if (!_isEditing) {
      try {
        final sales = await SalesDB.getAllSales();
        int lastSalesNo = 0;

        if (sales.isNotEmpty) {
          // Extract all sales numbers and find the maximum
          final salesNumbers =
              sales
                  .map(
                    (s) => int.tryParse(s['sales_no']?.toString() ?? '0') ?? 0,
                  )
                  .toList();
          lastSalesNo = salesNumbers.reduce((a, b) => a > b ? a : b);
        }

        setState(() {
          _salesController.text = (lastSalesNo + 1).toString();
        });
      } catch (e) {
        // Fallback in case of any error
        setState(() {
          _salesController.text = '1';
        });
        debugPrint('Error generating sales number: $e');
      }
    }
  }

  // Edit mode initialize method
  Future<void> _initializeEditMode() async {
    final sales = widget.salesData!;

    setState(() {
      _salesController.text = sales['sales_no'] ?? '';
      _customerController.text = sales['customer_name'] ?? '';
      _paymentStatusController.text = sales['payment_status'] ?? '';
      _paymentMethodController.text = sales['payment_method'] ?? '';
      _remarksController.text = sales['remarks'] ?? '';
      _totalAmount = sales['total_amount'] ?? 0.0;

      // Date parsing
      if (sales['date'] != null) {
        final parts = sales['date'].toString().split('-');
        if (parts.length == 3) {
          _selectedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          _dateController.text = sales['date'];
        }
      }
    });

    // Load items for this sales
    if (sales['id'] != null) {
      final items = await SalesItemDB.getSalesItemsBySalesId(sales['id']);
      setState(() {
        _items =
            items.map((item) {
              return {
                'id': item['id'],
                'item_name': item['item_name'],
                'quantity': item['quantity'],
                'rate': item['rate'],
                'unit': item['unit'],
                'total_amount': item['total_amount'],
                'sales_id': item['sales_id'],
              };
            }).toList();
        _hasAddedItems = items.isNotEmpty;
        _calculateTotal();
      });
    }
  }

  Future<void> _loadCustomerOptions() async {
    final customers = await CustomerDB.getAllCustomers();
    setState(() {
      _customerOptions = customers;
    });
  }

  Future<void> _openCalendarDialog() async {
    DateTime? picked = await showRoundedDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      borderRadius: 0,
      height: 320,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        dialogBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}-${picked.month}-${picked.year}";
      });
    }
  }

  Future<void> _selectCustomer() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredCustomers = List.from(_customerOptions);

    final selectedCustomer = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Customer",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      labelText: 'Search',
                      controller: searchController,
                      icon: Icons.search,
                      onChanged: (value) {
                        setState(() {
                          filteredCustomers =
                              _customerOptions
                                  .where(
                                    (customer) => customer['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(value.toLowerCase()),
                                  )
                                  .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.pushNamed(
                            context,
                            'add_customer',
                          );
                          if (result == true) {
                            await _loadCustomerOptions();
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.blue),
                        label: const Text(
                          "Add New Customer",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                customer['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  if (customer['phone'] != null)
                                    Text("Phone: ${customer['phone']}"),
                                  if (customer['gstin'] != null)
                                    Text("GSTIN: ${customer['gstin']}"),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context, customer);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selectedCustomer != null && selectedCustomer is Map<String, dynamic>) {
      setState(() {
        _customerController.text = selectedCustomer['name'] ?? '';
      });
    }
  }

  Widget sizedBox20() => const SizedBox(height: 20);

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Item Name and Edit/Delete Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['item_name'] ?? 'Item',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editItem(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Second Row: Qty and Unit
            Row(
              children: [
                if (item['quantity'] != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('Qty: ${item['quantity']}'),
                    ),
                  ),
                if (item['unit'] != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('Unit: ${item['unit']}'),
                    ),
                  ),
              ],
            ),

            // Third Row: Rate and Total
            Row(
              children: [
                if (item['rate'] != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('Rate: ₹${item['rate']}'),
                    ),
                  ),
                if (item['total_amount'] != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'Total: ₹${item['total_amount']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAmount() {
    return Card(
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'GRAND TOTAL:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '₹$_totalAmount',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculateTotal();
      _hasAddedItems = _items.isNotEmpty;
    });
  }

  void _editItem(int index) async {
    final item = _items[index];

    // For existing items, fetch complete item data
    if (item['id'] != null) {
      final dbItem = await SalesItemDB.getSalesItemById(item['id']);
      if (dbItem != null) {
        item.addAll({
          'item_name': dbItem['item_name'],
          'unit': dbItem['unit'],
          'quantity': dbItem['quantity'],
          'rate': dbItem['rate'],
          'subtotal': dbItem['subtotal'],
          'discount_percent': dbItem['discount_percent'],
          'discount_value': dbItem['discount_value'],
          'tax_percent': dbItem['tax_percent'],
          'tax_value': dbItem['tax_value'],
          'total_amount': dbItem['total_amount'],
          'temp_tag':
              item['temp_tag'] ??
              'temp_${DateTime.now().millisecondsSinceEpoch}',
        });
      }
    }

    final result = await Navigator.pushNamed(
      context,
      'add_sales_item',
      arguments: item,
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _items[index] = result;
        _calculateTotal();
      });
    }
  }

  void _calculateTotal() {
    _totalAmount = _items.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['total_amount'].toString()) ?? 0.0);
    });
  }

  Future<void> _submitSales() async {
    if (_customerController.text.isEmpty ||
        _salesController.text.isEmpty ||
        !_hasAddedItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all required fields."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      int salesId = 0;
      final itemsToUpdate = <Map<String, dynamic>>[];
      final originalItems = <Map<String, dynamic>>[];

      // Get original items if editing
      if (_isEditing && widget.salesData != null) {
        salesId = widget.salesData!['id'];
        originalItems.addAll(await SalesItemDB.getSalesItemsBySalesId(salesId));
      }

      // PHASE 1: Save sales and items
      await db.transaction((txn) async {
        // Create sales data
        final salesData = {
          if (_isEditing && widget.salesData != null)
            'id': widget.salesData!['id'],
          'sales_no': _salesController.text,
          'date': _dateController.text,
          'customer_name': _customerController.text,
          'total_amount': _totalAmount,
          'payment_status': _paymentStatusController.text,
          'payment_method': _paymentMethodController.text,
          'remarks': _remarksController.text,
        };

        // Save sales
        if (_isEditing && widget.salesData != null) {
          salesId = widget.salesData!['id'];
          await txn.update(
            'sales',
            salesData,
            where: 'id = ?',
            whereArgs: [salesId],
          );

          // Clear existing items
          await txn.delete(
            'sales_item',
            where: 'sales_id = ?',
            whereArgs: [salesId],
          );
        } else {
          salesId = await txn.insert('sales', salesData);
        }

        // Save items
        for (final item in _items) {
          final itemData = {
            'item_name': item['item_name'] as String? ?? '',
            'unit': item['unit'] as String? ?? '',
            'quantity': int.tryParse(item['quantity']?.toString() ?? '') ?? 1,
            'rate': double.tryParse(item['rate']?.toString() ?? '') ?? 0.0,
            'subtotal':
                double.tryParse(item['subtotal']?.toString() ?? '') ?? 0.0,
            'discount_percent':
                double.tryParse(item['discount_percent']?.toString() ?? '') ??
                0.0,
            'discount_value':
                double.tryParse(item['discount_value']?.toString() ?? '') ??
                0.0,
            'tax_percent': item['tax_percent'] as String? ?? 'GST@ 0%',
            'tax_value':
                double.tryParse(item['tax_value']?.toString() ?? '') ?? 0.0,
            'total_amount':
                double.tryParse(item['total_amount']?.toString() ?? '') ?? 0.0,
            'sales_id': salesId,
          };
          await txn.insert('sales_item', itemData);

          itemsToUpdate.add({
            'productName': (item['item_name'] as String?)?.trim() ?? '',
            'quantity': int.tryParse(item['quantity']?.toString() ?? '') ?? 0,
          });
        }

        await txn.delete('sales_item', where: 'sales_id IS NULL');
      });

      // PHASE 2: Update stock quantities
      print('\n🛒 Starting stock updates');

      if (_isEditing) {
        // For edits, first add back the original quantities (undo the sale)
        print('\n⏪ Reverting original sale quantities');
        for (final originalItem in originalItems) {
          final productName =
              (originalItem['item_name'] as String?)?.trim() ?? '';
          final originalQty =
              int.tryParse(originalItem['quantity']?.toString() ?? '') ?? 0;

          if (originalQty > 0) {
            print('➕ Adding back $originalQty of "$productName" to stock');
            await ProductDB.updateProductStock(productName, originalQty);
          }
        }
      }

      // Then subtract the new quantities (apply the updated sale)
      print('\n⏩ Applying new sale quantities');
      for (final item in itemsToUpdate) {
        final productName = item['productName'] as String;
        final quantity = item['quantity'] as int;

        if (quantity > 0) {
          print('➖ Removing $quantity of "$productName" from stock');
          await ProductDB.updateProductStock(productName, -quantity);
        }
      }

      print('\n✅ Completed all stock updates');

      // Return success
      if (mounted) {
        Navigator.pop(context, {
          'success': true,
          'salesId': salesId,
          'refresh': true,
        });
      }
    } catch (e) {
      print('⛔ CRITICAL ERROR in _submitSales: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save sales: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primary,
      title: Text(
        _isEditing ? "Edit Sales" : "Add Sales",
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _submitSales,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(350, 50),
        backgroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        _isEditing ? "UPDATE SALES" : "SAVE SALES",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildAddItemButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await Navigator.pushNamed(context, 'add_sales_item');
        if (result != null && result is Map<String, dynamic>) {
          // Save the item to database with temp tag
          final tempTag = DateTime.now().millisecondsSinceEpoch.toString();
          final itemData = {...result, 'temp_tag': tempTag, 'sales_id': null};

          try {
            await SalesItemDB.insertSalesItem(itemData);
            setState(() {
              _items.add(result);
              _hasAddedItems = true;
              _calculateTotal();
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add item: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        "ADD ITEM",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(350, 50),
        backgroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body:
          _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _salesController,
                              decoration: const InputDecoration(
                                labelText: 'Sales Number',
                                labelStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                border: InputBorder.none,
                                icon: Icon(Icons.receipt_long),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: GestureDetector(
                              onTap: _openCalendarDialog,
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _dateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Sales Date',
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    border: InputBorder.none,
                                    icon: Icon(Icons.calendar_month),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    sizedBox20(),
                    GestureDetector(
                      onTap: _selectCustomer,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          labelText: 'Customer',
                          controller: _customerController,
                          icon: Icons.person,
                        ),
                      ),
                    ),
                    sizedBox20(),
                    _buildAddItemButton(),
                    sizedBox20(),
                    if (_hasAddedItems) ...[
                      Column(
                        children: [
                          ..._items.asMap().entries.map(
                            (entry) => _buildItemCard(entry.value, entry.key),
                          ),
                          _buildTotalAmount(),
                        ],
                      ),
                      sizedBox20(),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  () => _selectOption(
                                    controller: _paymentStatusController,
                                    title: 'Payment Status',
                                    options: ['Paid', 'Unpaid', 'Partial'],
                                    enableSearch: false,
                                  ),
                              child: AbsorbPointer(
                                child: CustomTextField(
                                  labelText: 'Payment Status',
                                  controller: _paymentStatusController,
                                  icon: Icons.payment,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  () => _selectOption(
                                    controller: _paymentMethodController,
                                    title: 'Payment Method',
                                    options: ['Cash', 'Card', 'UPI'],
                                    enableSearch: false,
                                  ),
                              child: AbsorbPointer(
                                child: CustomTextField(
                                  labelText: 'Payment Method',
                                  controller: _paymentMethodController,
                                  icon: Icons.account_balance_wallet,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      sizedBox20(),
                      CustomTextField(
                        labelText: 'Remarks',
                        controller: _remarksController,
                        icon: Icons.notes,
                        maxLines: 2,
                      ),
                      sizedBox20(),
                    ],
                  ],
                ),
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: _buildSaveButton(),
      ),
    );
  }

  Future<void> _selectOption({
    required TextEditingController controller,
    required String title,
    required List<String> options,
    required bool enableSearch,
  }) async {
    final result = await showOptionSelectorBottomSheet(
      context: context,
      title: title,
      initialOptions: options,
      selectedOption: controller.text,
      enableCustomAdd: false,
      enableSearch: enableSearch,
    );

    if (result != null) {
      setState(() {
        controller.text = result;
      });
    }
  }
}
