import 'package:flutter/material.dart';
import 'package:offline_billing/common/components/custom_files/custom_selector_bottom_sheet.dart';
import 'package:offline_billing/common/components/custom_files/custom_text_field.dart';
import 'package:offline_billing/database/purchase_item_db.dart';
import 'package:offline_billing/database/purchase_return_item_db.dart';
import 'package:offline_billing/database/unit_db.dart';

class AddPurchaseReturnItemPage extends StatefulWidget {
  const AddPurchaseReturnItemPage({super.key});

  @override
  State<AddPurchaseReturnItemPage> createState() =>
      _AddPurchaseReturnItemPageState();
}

class _AddPurchaseReturnItemPageState extends State<AddPurchaseReturnItemPage> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _maxReturnableController =
      TextEditingController();
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
  List<Map<String, dynamic>> originalItems = [];
  Map<String, dynamic>? selectedOriginalItem;
  int? originalPurchaseId;
  int? originalItemId;
  int maxReturnableQty = 0;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      originalPurchaseId = args['original_purchase_id'];
      final isEditing = args['isEditing'] ?? false;

      if (isEditing) {
        // Editing existing item - load all data from args
        _prefillData(args);
      } else if (originalPurchaseId != null) {
        // New item with original purchase ID - load original items
        _loadOriginalItems(originalPurchaseId!);
      }
    }
  }

  Future<void> _loadItemData(int itemId) async {
    setState(() => isLoading = true);
    try {
      // First try to load from PurchaseReturnItemDB
      final returnItem = await PurchaseReturnItemDB.getCompleteReturnItemById(
        itemId,
      );
      _prefillData(returnItem);
      originalItemId = itemId;

      // Then load the original purchase item to get max returnable quantity
      if (returnItem['original_item_id'] != null) {
        final originalItem = await PurchaseItemDB.getCompleteItemById(
          returnItem['original_item_id'],
        );
        _maxReturnableController.text = originalItem['quantity'].toString();
        maxReturnableQty = int.tryParse(_maxReturnableController.text) ?? 0;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading item: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadOriginalItems(int purchaseId) async {
    setState(() => isLoading = true);
    try {
      final items = await PurchaseItemDB.getItemsByPurchaseId(purchaseId);
      setState(() => originalItems = items);

      if (items.isNotEmpty) {
        _selectOriginalItem(items.first);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No items found in the original purchase'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUnitOptions();
  }

  void _prefillData(Map<String, dynamic> itemData) {
    setState(() {
      _itemNameController.text = itemData['item_name']?.toString() ?? '';
      _unitController.text = itemData['unit']?.toString() ?? '';
      _rateController.text = (itemData['rate']?.toString() ?? '0');
      _quantityController.text = (itemData['quantity']?.toString() ?? '1');
      originalItemId = itemData['original_item_id'];

      // Handle max returnable quantity
      if (itemData['original_quantity'] != null) {
        _maxReturnableController.text =
            itemData['original_quantity'].toString();
        maxReturnableQty = int.tryParse(_maxReturnableController.text) ?? 0;
      }

      // Handle tax
      _taxPercentController.text =
          itemData['tax_percent']?.toString() ?? 'GST@ 0%';
      _taxValueController.text = (itemData['tax_value']?.toString() ?? '0');

      // Handle discount
      _discountPercentController.text =
          (itemData['discount_percent']?.toString() ?? '0');
      _discountValueController.text =
          (itemData['discount_value']?.toString() ?? '0');

      // Calculate amounts
      _calculateSubtotal();
      _calculateDiscountFromPercent();
      _calculateTaxFromPercent();
    });
  }

  Future<void> _loadUnitOptions() async {
    final units = await UnitDB.getAllUnits();
    setState(() {
      unitOptions = units.map((unit) => unit.toString()).toList();
    });
  }

  void _selectOriginalItem(Map<String, dynamic> item) {
    setState(() {
      selectedOriginalItem = item;
      originalItemId = item['id'];
      _itemNameController.text = item['item_name'] ?? '';
      _unitController.text = item['unit'] ?? '';
      _rateController.text = (item['rate']?.toStringAsFixed(2) ?? '0');
      _maxReturnableController.text = (item['quantity']?.toString() ?? '0');
      maxReturnableQty = int.tryParse(_maxReturnableController.text) ?? 0;
      _quantityController.text = maxReturnableQty.toString();

      // Handle tax percentage
      if (item['tax_percent'] != null) {
        if (item['tax_percent'] is String) {
          _taxPercentController.text = item['tax_percent'];
        } else {
          _taxPercentController.text = 'GST@ ${item['tax_percent']}%';
        }
      } else {
        _taxPercentController.text = 'GST@ 0%';
      }

      // Handle discount
      _discountPercentController.text =
          (item['discount_percent']?.toString() ?? '0');
      _discountValueController.text =
          (item['discount_value']?.toStringAsFixed(2) ?? '0.00');

      _calculateSubtotal();
      _calculateDiscountFromPercent();
      _calculateTaxFromPercent();
    });
  }

  Widget sizedBox20() => const SizedBox(height: 15);

  Future<void> _selectOriginalItemDialog() async {
    if (originalItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items available in the original purchase'),
        ),
      );
      return;
    }

    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredItems = List.from(originalItems);

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
                          "Select Original Item",
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
                          filteredItems =
                              originalItems
                                  .where(
                                    (item) => item['item_name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(value.toLowerCase()),
                                  )
                                  .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                item['item_name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text('Qty: ${item['quantity']}'),
                                  Text('Rate: ₹${item['rate']}'),
                                  Text('Unit: ${item['unit']}'),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context, item);
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
        _selectOriginalItem(value);
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
    final percent = double.tryParse(_discountPercentController.text) ?? 0;
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

  Map<String, dynamic> _prepareReturnItemData() {
    return {
      'original_item_id': originalItemId,
      'item_name': _itemNameController.text,
      'unit': _unitController.text,
      'quantity': _quantityController.text,
      'original_quantity': _maxReturnableController.text,
      'rate': _rateController.text,
      'subtotal': _subtotalController.text,
      'discount_percent': _discountPercentController.text,
      'discount_value': _discountValueController.text,
      'tax_percent': _taxPercentController.text,
      'tax_value': _taxValueController.text,
      'total_amount': _totalAmountController.text,
    };
  }

  bool _validateForm() {
    if (_itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an item')));
      return false;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return false;
    }

    if (quantity > maxReturnableQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot return more than $maxReturnableQty items'),
        ),
      );
      return false;
    }

    return true;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.red,
      title: const Text(
        "Add Return Item",
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
      onPressed: () {
        if (!_validateForm()) return;

        final returnItem = _prepareReturnItemData();
        Navigator.pop(context, returnItem);
      },
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(350, 50),
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        "SAVE RETURN ITEM",
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _selectOriginalItemDialog,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          labelText: 'Item Name',
                          controller: _itemNameController,
                          icon: Icons.inventory_2,
                        ),
                      ),
                    ),
                    sizedBox20(),
                    CustomTextField(
                      labelText: 'Original Quantity',
                      controller: _maxReturnableController,
                      icon: Icons.numbers,
                      readOnly: true,
                    ),
                    sizedBox20(),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            labelText: 'Return Quantity',
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
                                  onChanged:
                                      (_) => _calculateDiscountFromPercent(),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: CustomTextField(
                                  labelText: 'Value',
                                  controller: _discountValueController,
                                  icon: Icons.currency_rupee,
                                  keyboardType: TextInputType.number,
                                  onChanged:
                                      (_) => _calculateDiscountFromValue(),
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
