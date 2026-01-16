import 'dart:math';

import 'package:flutter/material.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/database/product_db.dart';
import 'package:offline_billing/database/sales_item_db.dart';
import 'package:offline_billing/database/unit_db.dart';

import '../../../common/components/custom_files/custom_selector_bottom_sheet.dart';
import '../../../common/components/custom_files/custom_text_field.dart';

class AddSalesItemPage extends StatefulWidget {
  const AddSalesItemPage({super.key});

  @override
  State<AddSalesItemPage> createState() => _AddSalesItemPageState();
}

class _AddSalesItemPageState extends State<AddSalesItemPage>
    with WidgetsBindingObserver {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _subtotalController = TextEditingController();
  final TextEditingController _discountValueController =
      TextEditingController();
  final TextEditingController _discountPercentController =
      TextEditingController();
  final TextEditingController _taxValueController = TextEditingController();
  final TextEditingController _taxPercentController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();

  List<String> unitOptions = [];
  List<Map<String, dynamic>> productOptions = [];
  Map<String, dynamic>? selectedProduct;
  String? _tempTag; // To track if we're editing an existing item

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUnitOptions();
    _loadProductOptions();

    // Check for arguments when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _prefillData(args);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProductOptions();
    }
  }

  void _prefillData(Map<String, dynamic> itemData) {
    setState(() {
      _tempTag = itemData['temp_tag']?.toString();
      _itemNameController.text = itemData['item_name']?.toString() ?? '';
      _unitController.text = itemData['unit']?.toString() ?? '';

      // Handle quantity
      final quantity = itemData['quantity'] ?? 1;
      _quantityController.text = quantity.toString();

      // Handle rate
      final rate = itemData['rate'] ?? 0;
      _rateController.text = rate is String ? rate : rate.toStringAsFixed(2);

      // Handle tax percentage - reconstruct the formatted string
      final taxPercent = itemData['tax_percent'] ?? 0;
      if (taxPercent is String) {
        // If it's already a formatted string, use it directly
        _taxPercentController.text =
            taxPercent.contains('%') ? taxPercent : 'GST@ $taxPercent%';
      } else {
        // If it's a number, format it
        _taxPercentController.text = 'GST@ ${taxPercent.toString()}%';
      }

      // Handle subtotal - calculate if not provided
      final subtotal =
          itemData['subtotal'] ??
          (double.tryParse(_rateController.text) ?? 0) *
              (double.tryParse(_quantityController.text) ?? 1);
      _subtotalController.text = subtotal.toStringAsFixed(2);

      // Handle discount
      final discountPercent = itemData['discount_percent'] ?? 0;
      _discountPercentController.text = discountPercent.toString();

      final discountValue = itemData['discount_value'] ?? 0;
      _discountValueController.text = discountValue.toString();

      // Handle tax value
      final taxValue = itemData['tax_value'] ?? 0;
      _taxValueController.text = taxValue.toString();

      // Handle total amount
      final totalAmount = itemData['total_amount'] ?? 0;
      _totalAmountController.text = totalAmount.toStringAsFixed(2);
    });

    // Force calculations after UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateSubtotal();
      _calculateDiscountFromPercent();
      _calculateTaxFromPercent();
      _calculateTotalAmount();
    });
  }

  Future<void> _loadUnitOptions() async {
    final units = await UnitDB.getAllUnits();
    setState(() {
      unitOptions = units;
    });
  }

  Future<void> _loadProductOptions() async {
    final products = await ProductDB.getAllProducts();
    setState(() {
      productOptions = products;
    });
  }

  Widget sizedBox20() => const SizedBox(height: 15);

  String _generateTempTag() {
    final random = Random();
    return 'temp_${random.nextInt(999999)}_${random.nextInt(999999)}';
  }

  Future<void> _selectUnit() async {
    final result = await showOptionSelectorBottomSheet(
      context: context,
      title: "Unit",
      initialOptions: unitOptions,
      selectedOption: _unitController.text,
      enableDelete: true,
    );

    if (result != null) {
      if (result.startsWith("DELETE:")) {
        final deletedOption = result.replaceFirst("DELETE:", "");
        await UnitDB.deleteUnit(deletedOption);
        await _loadUnitOptions();

        if (_unitController.text == deletedOption) {
          setState(() {
            _unitController.text = '';
          });
        }
      } else {
        await UnitDB.insertUnit(result);
        setState(() {
          _unitController.text = result;
        });
        await _loadUnitOptions();
      }
    }
  }

  Future<void> _selectItemName() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredProducts = List.from(productOptions);

    await showModalBottomSheet(
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
                          "Item Name",
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
                          filteredProducts =
                              productOptions
                                  .where(
                                    (product) => product['name']
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
                            'add_product',
                          );
                          if (result == true) {
                            await _loadProductOptions();
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.blue),
                        label: const Text(
                          "Add New Item",
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
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                product['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text(
                                    "Selling Price: ${product['salePrice']?.toStringAsFixed(2) ?? '0.00'}",
                                  ),
                                  Text(
                                    "In Stock: ${product['stockQuantity']?.toStringAsFixed(0) ?? '0'}",
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context, product);
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
    ).then((value) {
      if (value != null && value is Map<String, dynamic>) {
        final product = value;
        selectedProduct = product;
        setState(() {
          _itemNameController.text = product['name'] ?? '';
          _unitController.text = product['unit'] ?? '';
          _rateController.text =
              product['salePrice']?.toStringAsFixed(2) ?? '0';
          _calculateSubtotal();
        });
      }
    });
  }

  Future<void> _selectTaxPercent() async {
    final taxOptions = [
      'GST@ 0%',
      'IGST@ 0%',
      'GST@ 0.25%',
      'IGST@ 0.25%',
      'GST@ 3%',
      'IGST@ 3%',
      'GST@ 5%',
      'IGST@ 5%',
      'GST@ 12%',
      'IGST@ 12%',
      'GST@ 18%',
      'IGST@ 18%',
      'GST@ 28%',
      'IGST@ 28%',
    ];

    final result = await showOptionSelectorBottomSheet(
      context: context,
      title: 'Tax %',
      initialOptions: taxOptions,
      selectedOption: _taxPercentController.text,
      enableCustomAdd: false,
      enableSearch: false,
    );

    if (result != null) {
      setState(() {
        _taxPercentController.text = result;
        _calculateTaxFromPercent();
      });
    }
  }

  void _calculateSubtotal() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final quantityText = _quantityController.text.trim();
    final quantity =
        quantityText.isEmpty ? 1.0 : double.tryParse(quantityText) ?? 1.0;
    final subtotal = rate * quantity;
    _subtotalController.text = subtotal.toStringAsFixed(2);
    _calculateDiscountFromPercent();
    _calculateTaxFromPercent();
  }

  void _calculateDiscountFromPercent() {
    final subtotal = double.tryParse(_subtotalController.text) ?? 0;
    final percent = int.tryParse(_discountPercentController.text) ?? 0;
    final discount = subtotal * percent / 100;
    _discountValueController.text = discount.toStringAsFixed(2);
    _calculateTotalAmount();
  }

  void _calculateDiscountFromValue() {
    final subtotal = double.tryParse(_subtotalController.text) ?? 0;
    final discountValue = double.tryParse(_discountValueController.text) ?? 0;
    final percent = subtotal > 0 ? (discountValue / subtotal) * 100 : 0;
    _discountPercentController.text = percent.toStringAsFixed(0);
    _calculateTotalAmount();
  }

  void _calculateTaxFromPercent() {
    final subtotal = double.tryParse(_subtotalController.text) ?? 0;
    final discount = double.tryParse(_discountValueController.text) ?? 0;
    final percentText = _taxPercentController.text.replaceAll(
      RegExp('[^0-9.]'),
      '',
    );
    final percent = double.tryParse(percentText) ?? 0;
    final taxableAmount = subtotal - discount;
    final tax = taxableAmount * percent / 100;
    _taxValueController.text = tax.toStringAsFixed(2);
    _calculateTotalAmount();
  }

  void _calculateTaxFromValue() {
    final subtotal = double.tryParse(_subtotalController.text) ?? 0;
    final discount = double.tryParse(_discountValueController.text) ?? 0;
    final taxValue = double.tryParse(_taxValueController.text) ?? 0;
    final taxableAmount = subtotal - discount;
    final percent = taxableAmount > 0 ? (taxValue / taxableAmount) * 100 : 0;
    _taxPercentController.text = 'GST@ ${percent.toStringAsFixed(0)}%';
    _calculateTotalAmount();
  }

  void _calculateTotalAmount() {
    final subtotal = double.tryParse(_subtotalController.text) ?? 0;
    final discount = double.tryParse(_discountValueController.text) ?? 0;
    final tax = double.tryParse(_taxValueController.text) ?? 0;
    final total = subtotal - discount + tax;
    _totalAmountController.text = total.toStringAsFixed(2);
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primary,
      title: const Text(
        "Add Sales Item",
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
      onPressed: () async {
        if (_itemNameController.text.isEmpty ||
            _quantityController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill required fields')),
          );
          return;
        }

        // Prepare data for UI return
        final itemDataForUI = <String, dynamic>{
          'item_name': _itemNameController.text,
          'unit': _unitController.text,
          'quantity': _quantityController.text,
          'rate': _rateController.text,
          'subtotal': _subtotalController.text,
          'discount_percent': _discountPercentController.text,
          'discount_value': _discountValueController.text,
          'tax_percent': _taxPercentController.text,
          'tax_value': _taxValueController.text,
          'total_amount': _totalAmountController.text,
        };

        // Prepare data for database
        final itemDataForDB = <String, dynamic>{
          'item_name': _itemNameController.text,
          'unit': _unitController.text,
          'quantity': int.tryParse(_quantityController.text) ?? 1,
          'rate': double.tryParse(_rateController.text) ?? 0.0,
          'subtotal': double.tryParse(_subtotalController.text) ?? 0.0,
          'discount_percent':
              double.tryParse(_discountPercentController.text) ?? 0.0,
          'discount_value':
              double.tryParse(_discountValueController.text) ?? 0.0,
          'tax_percent':
              double.tryParse(
                _taxPercentController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              0.0,
          'tax_value': double.tryParse(_taxValueController.text) ?? 0.0,
          'total_amount': double.tryParse(_totalAmountController.text) ?? 0.0,
        };

        try {
          if (_tempTag != null) {
            // First get the existing item by temp tag
            final existingItems = await SalesItemDB.getSalesItemsByTempTag(
              _tempTag!,
            );

            if (existingItems.isNotEmpty) {
              // Update the existing item using its ID
              await SalesItemDB.updateSalesItem({
                ...itemDataForDB,
                'id': existingItems.first['id'],
                'temp_tag': _tempTag, // Keep the temp tag
              });
              itemDataForUI['temp_tag'] = _tempTag;
            } else {
              // If no item found with this temp tag, insert as new
              final newTempTag = _generateTempTag();
              await SalesItemDB.insertSalesItem({
                ...itemDataForDB,
                'temp_tag': newTempTag,
              });
              itemDataForUI['temp_tag'] = newTempTag;
            }
          } else {
            // Create new item with new temp tag
            final newTempTag = _generateTempTag();
            await SalesItemDB.insertSalesItem({
              ...itemDataForDB,
              'temp_tag': newTempTag,
            });
            itemDataForUI['temp_tag'] = newTempTag;
          }

          Navigator.pop(context, itemDataForUI);
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save item: $e')));
        }
      },
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(350, 50),
        backgroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        "SAVE ITEM",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _selectItemName,
              child: AbsorbPointer(
                child: CustomTextField(
                  labelText: 'Item Name',
                  controller: _itemNameController,
                  icon: Icons.inventory_2,
                ),
              ),
            ),
            sizedBox20(),
            GestureDetector(
              onTap: _selectUnit,
              child: AbsorbPointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _unitController.text.isEmpty
                            ? "Select Unit"
                            : _unitController.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
            sizedBox20(),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: 'Quantity',
                    controller: _quantityController,
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateSubtotal(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: CustomTextField(
                    labelText: 'Rate',
                    controller: _rateController,
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateSubtotal(),
                  ),
                ),
              ],
            ),
            sizedBox20(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Subtotal",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    labelText: 'Subtotal',
                    controller: _subtotalController,
                    icon: Icons.calculate,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                  sizedBox20(),
                  const Text(
                    "DISCOUNT",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          labelText: '%',
                          controller: _discountPercentController,
                          icon: Icons.percent,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateDiscountFromPercent(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CustomTextField(
                          labelText: 'Value',
                          controller: _discountValueController,
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateDiscountFromValue(),
                        ),
                      ),
                    ],
                  ),
                  sizedBox20(),
                  const Text(
                    "TAX",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectTaxPercent,
                          child: AbsorbPointer(
                            child: CustomTextField(
                              labelText: '%',
                              controller: _taxPercentController,
                              icon: Icons.percent,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CustomTextField(
                          labelText: 'Value',
                          controller: _taxValueController,
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateTaxFromValue(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            sizedBox20(),
            CustomTextField(
              labelText: 'Total Amount',
              controller: _totalAmountController,
              icon: Icons.currency_rupee_sharp,
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
            sizedBox20(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: _buildSaveButton(),
      ),
    );
  }
}
