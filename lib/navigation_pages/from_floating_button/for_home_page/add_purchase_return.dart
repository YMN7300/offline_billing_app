import 'package:flutter/material.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/common/components/custom_files/custom_selector_bottom_sheet.dart';
import 'package:offline_billing/common/components/custom_files/custom_text_field.dart';
import 'package:offline_billing/database/db/database_helper.dart';
import 'package:offline_billing/database/product_db.dart';
import 'package:offline_billing/database/purchase_db.dart';
import 'package:offline_billing/database/purchase_item_db.dart';
import 'package:offline_billing/database/purchase_return_db.dart';
import 'package:offline_billing/database/purchase_return_item_db.dart';

class AddPurchaseReturn extends StatefulWidget {
  final Map<String, dynamic>? originalPurchaseData;

  const AddPurchaseReturn({super.key, this.originalPurchaseData});

  @override
  State<AddPurchaseReturn> createState() => _AddPurchaseReturnState();
}

class _AddPurchaseReturnState extends State<AddPurchaseReturn> {
  // Controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _returnNoController = TextEditingController();
  final TextEditingController _originalPurchaseNoController =
      TextEditingController();
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
  bool _isLoadingData = false;
  int? _originalPurchaseId;

  @override
  void initState() {
    super.initState();
    _dateController.text =
        "${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}";

    // Generate return number for new returns
    _generateReturnNumber();

    // If we have original purchase data, prefill the form
    if (widget.originalPurchaseData != null) {
      _isLoadingData = true;

      // Load basic return info
      _originalPurchaseId =
          widget.originalPurchaseData!['original_purchase_id'];
      _returnNoController.text =
          widget.originalPurchaseData!['return_no'] ?? '';
      _dateController.text =
          widget.originalPurchaseData!['date'] ?? _dateController.text;
      _vendorController.text =
          widget.originalPurchaseData!['supplier_name'] ?? '';
      _originalPurchaseNoController.text =
          widget.originalPurchaseData!['original_purchase_no'] ?? '';
      _paymentStatusController.text =
          widget.originalPurchaseData!['payment_status'] ?? '';
      _paymentMethodController.text =
          widget.originalPurchaseData!['payment_method'] ?? '';
      _remarksController.text = widget.originalPurchaseData!['remarks'] ?? '';

      // Load return items if they exist
      if (widget.originalPurchaseData!['items'] != null) {
        _items = List<Map<String, dynamic>>.from(
          widget.originalPurchaseData!['items'],
        );
        _hasAddedItems = _items.isNotEmpty;
        _calculateTotal();
      }

      _isLoadingData = false;
    }
  }

  Future<void> _selectVendor() async {
    // Get all purchases to extract unique vendors
    final allPurchases = await PurchaseDB.getAllPurchases();

    // Extract unique vendor names
    final vendorNames =
        allPurchases
            .map((purchase) => purchase['vendor_name']?.toString())
            .where((name) => name != null && name.isNotEmpty)
            .toSet()
            .toList();

    if (vendorNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No vendors found in purchase records")),
      );
      return;
    }

    // Convert to list of maps for the bottom sheet
    final vendorOptions = vendorNames.map((name) => {'name': name}).toList();

    final selectedVendor = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return VendorSelectionBottomSheet(
          vendors: vendorOptions,
          title: "Select Vendor",
        );
      },
    );

    if (selectedVendor != null && mounted) {
      setState(() {
        _vendorController.text = selectedVendor['name'] ?? '';
        // Clear previous invoice selection when vendor changes
        _originalPurchaseNoController.text = '';
        _originalPurchaseId = null;
      });
    }
  }

  Future<void> _selectOriginalInvoice() async {
    if (_vendorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a vendor first")),
      );
      return;
    }

    final invoices = await PurchaseDB.getAllPurchases();
    final vendorInvoices =
        invoices
            .where(
              (invoice) => invoice['vendor_name'] == _vendorController.text,
            )
            .toList();

    if (vendorInvoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No invoices found for this vendor")),
      );
      return;
    }

    // Get items for each invoice
    final List<Map<String, dynamic>> invoicesWithItems = [];
    for (final invoice in vendorInvoices) {
      final items = await PurchaseItemDB.getItemsByPurchaseId(invoice['id']);
      invoicesWithItems.add({
        ...invoice,
        'items': items,
        'total_amount': invoice['total_amount'],
      });
    }

    final selectedInvoice = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return InvoiceSelectionBottomSheet(
          invoices: invoicesWithItems,
          title: "Select Invoice",
        );
      },
    );

    if (selectedInvoice != null && mounted) {
      setState(() {
        _originalPurchaseNoController.text =
            selectedInvoice['purchase_no'] ?? '';
        _originalPurchaseId = selectedInvoice['id'];
      });
    }
  }

  Future<void> _generateReturnNumber() async {
    try {
      final returns = await PurchaseReturnDB.getAllReturns();
      int lastReturnNo = 0;

      if (returns.isNotEmpty) {
        // Extract all return numbers and find the maximum
        final returnNumbers =
            returns
                .map(
                  (r) => int.tryParse(r['return_no']?.toString() ?? '0') ?? 0,
                )
                .toList();
        lastReturnNo = returnNumbers.reduce((a, b) => a > b ? a : b);
      }

      setState(() {
        _returnNoController.text = (lastReturnNo + 1).toString();
      });
    } catch (e) {
      // Fallback in case of any error
      setState(() {
        _returnNoController.text = '1';
      });
      debugPrint('Error generating return number: $e');
    }
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
            // First Row: Item name + Icons
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

            // Second Row: Return Qty and Unit
            Row(
              children: [
                if (item['quantity'] != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('Return Qty: ${item['quantity']}'),
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
              'TOTAL RETURN AMOUNT:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '₹$_totalAmount',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.red,
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
    final result =
        await Navigator.pushNamed(
              context,
              'add_purchase_return_item',
              arguments: {
                ...item, // Spread all item properties
                'isEditing': true, // Add a flag to indicate edit mode
                'original_purchase_id': _originalPurchaseId,
              },
            )
            as Map<String, dynamic>?;

    if (result != null) {
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

  Future<void> _submitReturn() async {
    if (_vendorController.text.isEmpty ||
        _returnNoController.text.isEmpty ||
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
      bool success = false;
      final db = await DatabaseHelper.instance.database;
      int returnId = 0;
      final originalItems = <Map<String, dynamic>>[];

      // Get original items if editing
      if (widget.originalPurchaseData != null &&
          widget.originalPurchaseData!['id'] != null) {
        returnId = widget.originalPurchaseData!['id'];
        originalItems.addAll(
          await PurchaseReturnItemDB.getReturnItemsByReturnId(returnId),
        );
      }

      // PHASE 1: Save return and items
      await db.transaction((txn) async {
        // Create return data
        final returnData = {
          if (widget.originalPurchaseData != null &&
              widget.originalPurchaseData!['id'] != null)
            'id': widget.originalPurchaseData!['id'],
          'return_no': _returnNoController.text,
          'date': _dateController.text,
          'original_purchase_id': _originalPurchaseId,
          'original_purchase_no': _originalPurchaseNoController.text,
          'supplier_name': _vendorController.text,
          'total_amount': _totalAmount,
          'payment_status': _paymentStatusController.text,
          'payment_method': _paymentMethodController.text,
          'remarks': _remarksController.text,
        };

        // Save return
        if (widget.originalPurchaseData != null &&
            widget.originalPurchaseData!['id'] != null) {
          returnId = widget.originalPurchaseData!['id'];
          await txn.update(
            'purchase_return',
            returnData,
            where: 'id = ?',
            whereArgs: [returnId],
          );

          // Clear existing items
          await txn.delete(
            'purchase_return_item',
            where: 'return_id = ?',
            whereArgs: [returnId],
          );
        } else {
          returnId = await txn.insert('purchase_return', returnData);
        }

        // Save items
        for (final item in _items) {
          final itemData = {
            'return_id': returnId,
            'original_item_id': item['original_item_id'],
            'item_name': item['item_name'] ?? '',
            'unit': item['unit'] ?? '',
            'quantity': int.tryParse(item['quantity']?.toString() ?? '') ?? 1,
            'original_quantity': item['original_quantity'] ?? 0,
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
          };
          await txn.insert('purchase_return_item', itemData);
        }
        success = true;
      });

      // PHASE 2: Update stock quantities
      print('\n🛒 Starting stock updates for returns');

      if (widget.originalPurchaseData != null &&
          widget.originalPurchaseData!['id'] != null) {
        // For edits, first add the original quantities (undo the return)
        print('\n⏪ Reverting original return quantities');
        for (final originalItem in originalItems) {
          final productName =
              (originalItem['item_name'] as String?)?.trim() ?? '';
          final originalQty =
              int.tryParse(originalItem['quantity']?.toString() ?? '') ?? 0;

          if (originalQty > 0) {
            print(
              '➕ Adding $originalQty of "$productName" to stock (undo return)',
            );
            await ProductDB.updateProductStock(productName, originalQty);
          }
        }
      }

      // Then subtract the new quantities (apply the updated return)
      print('\n⏩ Applying new return quantities');
      for (final item in _items) {
        final productName = (item['item_name'] as String?)?.trim() ?? '';
        final quantity = int.tryParse(item['quantity']?.toString() ?? '') ?? 0;

        if (quantity > 0 && productName.isNotEmpty) {
          print('➖ Removing $quantity of "$productName" from stock (return)');
          await ProductDB.updateProductStock(productName, -quantity);
        }
      }

      print('\n✅ Completed all stock updates for returns');

      // Return success
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error in _submitReturn: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save return: ${e.toString()}'),
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
      title: const Text(
        "Add Purchase Return",
        style: TextStyle(
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
      onPressed: _submitReturn,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(350, 50),
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        "SAVE RETURN",
        style: TextStyle(
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
        final result =
            await Navigator.pushNamed(
                  context,
                  'add_purchase_return_item',
                  arguments: {
                    'original_purchase_id': _originalPurchaseId,
                    'auto_fill': _originalPurchaseId != null,
                  },
                )
                as Map<String, dynamic>?;

        if (result != null) {
          setState(() {
            _items.add(result);
            _hasAddedItems = true;
            _calculateTotal();
          });
        }
      },
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        "ADD RETURN ITEM",
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
                              controller: _returnNoController,
                              decoration: const InputDecoration(
                                labelText: 'Return Number',
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
                                    labelText: 'Return Date',
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
                      onTap: _selectVendor,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          labelText: 'Vendor',
                          controller: _vendorController,
                          icon: Icons.business,
                        ),
                      ),
                    ),
                    sizedBox20(),
                    GestureDetector(
                      onTap: _selectOriginalInvoice,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          labelText: 'Original Purchase No',
                          controller: _originalPurchaseNoController,
                          icon: Icons.receipt,
                          readOnly: true,
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
                                    options: [
                                      'Refunded',
                                      'Credit Note',
                                      'Adjusted',
                                    ],
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

class VendorSelectionBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> vendors;
  final String title;
  final String? displayField;

  const VendorSelectionBottomSheet({
    super.key,
    required this.vendors,
    required this.title,
    this.displayField = 'name',
  });

  @override
  State<VendorSelectionBottomSheet> createState() =>
      _VendorSelectionBottomSheetState();
}

class _VendorSelectionBottomSheetState
    extends State<VendorSelectionBottomSheet> {
  late List<Map<String, dynamic>> filteredVendors;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredVendors = widget.vendors;
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  widget.title,
                  style: const TextStyle(
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
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  filteredVendors =
                      widget.vendors.where((vendor) {
                        return vendor[widget.displayField]
                            .toString()
                            .toLowerCase()
                            .contains(value.toLowerCase());
                      }).toList();
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredVendors.length,
                itemBuilder: (context, index) {
                  final vendor = filteredVendors[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        vendor[widget.displayField].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => Navigator.pop(context, vendor),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceSelectionBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> invoices;
  final String title;

  const InvoiceSelectionBottomSheet({
    super.key,
    required this.invoices,
    required this.title,
  });

  @override
  State<InvoiceSelectionBottomSheet> createState() =>
      _InvoiceSelectionBottomSheetState();
}

class _InvoiceSelectionBottomSheetState
    extends State<InvoiceSelectionBottomSheet> {
  late List<Map<String, dynamic>> filteredInvoices;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredInvoices = widget.invoices;
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  widget.title,
                  style: const TextStyle(
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
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  filteredInvoices =
                      widget.invoices.where((invoice) {
                        return invoice['purchase_no']
                            .toString()
                            .toLowerCase()
                            .contains(value.toLowerCase());
                      }).toList();
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredInvoices.length,
                itemBuilder: (context, index) {
                  final invoice = filteredInvoices[index];
                  final items = invoice['items'] as List<dynamic>? ?? [];
                  final totalAmount = invoice['total_amount'] ?? 0.0;
                  final firstItemName =
                      items.isNotEmpty
                          ? items[0]['item_name']?.toString() ?? ''
                          : 'No items';
                  final firstItemQty =
                      items.isNotEmpty
                          ? items[0]['quantity']?.toString() ?? '0'
                          : '0';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () => Navigator.pop(context, invoice),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice ${invoice['purchase_no']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Item: $firstItemName (Qty: $firstItemQty)',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ₹$totalAmount',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
