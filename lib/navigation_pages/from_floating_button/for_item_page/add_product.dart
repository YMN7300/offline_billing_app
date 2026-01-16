import 'package:flutter/material.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/common/components/custom_files/custom_selector_bottom_sheet.dart';
import 'package:offline_billing/common/components/custom_files/custom_text_field.dart';

import '../../../common/components/custom_files/NumberOnlyFormatter.dart';
import '../../../database/brand_db.dart';
import '../../../database/category_db.dart';
import '../../../database/product_db.dart';
import '../../../database/unit_db.dart';

class AddProduct extends StatefulWidget {
  final Map<String, dynamic>? productData;
  const AddProduct({super.key, this.productData});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _stockQuantityController =
      TextEditingController();
  final TextEditingController _lowStockAlertController =
      TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? selectedUnit;
  String? selectedCategory;
  String? selectedBrand;

  DateTime _selectedDate = DateTime.now();
  int? _editingProductId;

  List<String> unitOptions = [];
  List<String> categoryOptions = [];
  List<String> brandOptions = [];

  @override
  void initState() {
    // Saare fields ko pre-fill kiya
    super.initState();

    if (widget.productData != null) {
      _editingProductId = widget.productData!['id'];
      _itemNameController.text = widget.productData!['name'];
      _salePriceController.text = widget.productData!['salePrice'].toString();
      _costPriceController.text = widget.productData!['costPrice'].toString();
      _stockQuantityController.text =
          widget.productData!['stockQuantity'].toString();
      _lowStockAlertController.text =
          widget.productData!['lowStockAlert'].toString();
      _dateController.text = widget.productData!['date'];

      selectedUnit = widget.productData!['unit'];
      selectedCategory = widget.productData!['category'];
      selectedBrand = widget.productData!['brand'];
    } else {
      _dateController.text =
          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    }

    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final units = await UnitDB.getAllUnits();
    final categories = await CategoryDB.getAllCategories();
    final brands = await BrandDB.getAllBrands();

    setState(() {
      unitOptions = units;
      categoryOptions = categories;
      brandOptions = brands;
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
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Widget _buildSelector({
    required String title,
    required String? selectedValue,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await showOptionSelectorBottomSheet(
          context: context,
          title: title,
          initialOptions: options,
          selectedOption: selectedValue,
          enableDelete: true,
        );
        if (result != null) {
          if (result.startsWith("DELETE:")) {
            final deletedOption = result.replaceFirst("DELETE:", "");
            if (title == "Unit") {
              await UnitDB.deleteUnit(deletedOption);
            } else if (title == "Category") {
              await CategoryDB.deleteCategory(deletedOption);
            } else if (title == "Brand") {
              await BrandDB.deleteBrand(deletedOption);
            }
            await _loadOptions();

            setState(() {
              if (title == "Unit" && selectedUnit == deletedOption)
                selectedUnit = null;
              if (title == "Category" && selectedCategory == deletedOption)
                selectedCategory = null;
              if (title == "Brand" && selectedBrand == deletedOption)
                selectedBrand = null;
            });
          } else {
            if (title == "Unit") {
              await UnitDB.insertUnit(result);
            } else if (title == "Category") {
              await CategoryDB.insertCategory(result);
            } else if (title == "Brand") {
              await BrandDB.insertBrand(result);
            }
            setState(() {
              if (title == "Unit") selectedUnit = result;
              if (title == "Category") selectedCategory = result;
              if (title == "Brand") selectedBrand = result;
            });
            await _loadOptions();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedValue ?? "Select $title",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selectedValue == null ? Colors.black : Colors.black,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _openCalendarDialog,
      child: AbsorbPointer(
        child: TextField(
          controller: _dateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: "Select Date",
            labelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            suffixIcon: Icon(Icons.calendar_month_outlined, color: primary),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter item name')));
      return;
    }
    if (selectedUnit == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select unit')));
      return;
    }

    final productData = {
      'name': _itemNameController.text,
      'unit': selectedUnit,
      'category': selectedCategory,
      'brand': selectedBrand,
      'salePrice': double.tryParse(_salePriceController.text) ?? 0.0,
      'costPrice': double.tryParse(_costPriceController.text) ?? 0.0,
      'stockQuantity': int.tryParse(_stockQuantityController.text) ?? 0,
      'lowStockAlert': int.tryParse(_lowStockAlertController.text) ?? 0,
      'date': _dateController.text,
    };

    if (_editingProductId != null) {
      // Edit mode - update existing product
      productData['id'] = _editingProductId;
      await ProductDB.updateProduct(productData);
    } else {
      await ProductDB.insertProduct(productData);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget sizedBox20() => const SizedBox(height: 20);

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primary,
      title: Text(
        //AppBar title dynamically change
        _editingProductId != null ? "Edit Item" : "Add Item",
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
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(350, 50),
        backgroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        "SAVE",
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
            CustomTextField(
              labelText: 'Item Name',
              controller: _itemNameController,
            ),
            sizedBox20(),
            _buildSelector(
              title: "Unit",
              selectedValue: selectedUnit,
              options: unitOptions,
              onSelected: (val) => setState(() => selectedUnit = val),
            ),
            sizedBox20(),
            _buildSelector(
              title: "Category",
              selectedValue: selectedCategory,
              options: categoryOptions,
              onSelected: (val) => setState(() => selectedCategory = val),
            ),
            sizedBox20(),
            _buildSelector(
              title: "Brand",
              selectedValue: selectedBrand,
              options: brandOptions,
              onSelected: (val) => setState(() => selectedBrand = val),
            ),
            sizedBox20(),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: 'Sale Price',
                    controller: _salePriceController,
                    icon: Icons.currency_rupee,
                    iconColor: Colors.green.shade800,
                    keyboardType: TextInputType.number,
                    inputFormatters: [NumberOnlyFormatter(context)],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: CustomTextField(
                    labelText: 'Cost Price',
                    controller: _costPriceController,
                    icon: Icons.currency_rupee,
                    iconColor: Colors.red.shade800,
                    keyboardType: TextInputType.number,
                    inputFormatters: [NumberOnlyFormatter(context)],
                  ),
                ),
              ],
            ),
            sizedBox20(),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: 'Enter count',
                    helperText: 'Stock Quantity',
                    controller: _stockQuantityController,
                    icon: Icons.production_quantity_limits,
                    iconColor: Colors.green.shade900,
                    keyboardType: TextInputType.number,
                    inputFormatters: [NumberOnlyFormatter(context)],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: CustomTextField(
                    labelText: 'Enter count',
                    helperText: 'Low Stock Alert',
                    controller: _lowStockAlertController,
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.red,
                    keyboardType: TextInputType.number,
                    inputFormatters: [NumberOnlyFormatter(context)],
                  ),
                ),
              ],
            ),
            sizedBox20(),
            _buildDateSelector(),
            sizedBox20(),
            const SizedBox(height: 50),
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
