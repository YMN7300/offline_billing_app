import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/common/components/custom_files/NumberOnlyFormatter.dart';
import 'package:offline_billing/common/components/custom_files/custom_text_field.dart';

import '../../../common/components/custom_files/custom_selector_bottom_sheet.dart';
import '../../../database/customer_db.dart';
import '../../../database/state_db.dart';

class AddCustomer extends StatefulWidget {
  final Map<String, dynamic>? customerData; // Optional for edit mode

  const AddCustomer({super.key, this.customerData});

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  List<String> _states = [];
  bool _isLoadingStates = true;

  bool get isEditMode => widget.customerData != null;

  @override
  void initState() {
    super.initState();
    _loadStates();
    if (isEditMode) _loadCustomerData();
  }

  void _loadCustomerData() {
    final data = widget.customerData!;
    _nameController.text = (data['name'] ?? '').toString();
    _phoneController.text = (data['phone'] ?? '').toString();
    _gstinController.text = (data['gstin'] ?? '').toString();
    _addressController.text = (data['address'] ?? '').toString();
    _pincodeController.text = (data['pincode'] ?? '').toString();
    _cityController.text = (data['city'] ?? '').toString();
    _stateController.text = (data['state'] ?? '').toString();
  }

  Future<void> _loadStates() async {
    try {
      final states = await StateDB.getAllStates();
      setState(() {
        _states = states;
        _isLoadingStates = false;
      });
    } catch (e) {
      _showSnackBar("Failed to load states");
      setState(() {
        _isLoadingStates = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitForm() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final gstin = _gstinController.text.trim().toUpperCase();
    final address = _addressController.text.trim();
    final pincode = _pincodeController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();

    // Validate only required fields for customer: name and phone
    if (name.isEmpty || phone.isEmpty) {
      _showSnackBar("Please fill in name and phone number");
      return;
    }

    // Validate phone number (10 digits)
    if (phone.length != 10) {
      _showSnackBar("Phone number must be exactly 10 digits");
      return;
    }

    final Map<String, dynamic> customerMap = {
      'name': name,
      'phone': phone,
      'gstin': gstin, // Now stored in uppercase
      'address': address,
      'pincode': pincode,
      'city': city,
      'state': state,
    };

    if (isEditMode) {
      customerMap['id'] =
          int.tryParse(widget.customerData!['id'].toString()) ?? 0;

      final result = await CustomerDB.updateCustomer(customerMap);
      if (result == 0) {
        _showSnackBar("Failed to update customer. Please try again.");
        return;
      }
    } else {
      await CustomerDB.insertCustomer(customerMap);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _selectState() async {
    if (_states.isEmpty) {
      _showSnackBar("No states available.");
      return;
    }

    final selected = await showOptionSelectorBottomSheet(
      context: context,
      title: 'State',
      initialOptions: _states,
      selectedOption: _stateController.text,
      enableCustomAdd: false,
    );

    if (selected != null && selected.isNotEmpty) {
      _stateController.text = selected;
    }
  }

  Widget sizedBox20() => const SizedBox(height: 20);

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primary,
      title: Text(
        isEditMode ? "Edit Customer" : "Add Customer",
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
      body:
          _isLoadingStates
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CustomTextField(
                      labelText: 'Name',
                      controller: _nameController,
                    ),
                    sizedBox20(),
                    CustomTextField(
                      labelText: 'Phone Number',
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        NumberOnlyFormatter(context, onError: _showSnackBar),
                      ],
                    ),
                    sizedBox20(),
                    CustomTextField(
                      labelText: 'GSTIN',
                      controller: _gstinController,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                        GstinFormatter(context, onError: _showSnackBar),
                      ],
                      onChanged: (value) {
                        // Force uppercase in case the formatter didn't catch it
                        if (value != value.toUpperCase()) {
                          _gstinController.value = _gstinController.value
                              .copyWith(
                                text: value.toUpperCase(),
                                selection: TextSelection.collapsed(
                                  offset: value.length,
                                ),
                              );
                        }
                      },
                    ),
                    sizedBox20(),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Billing Address'),
                    ),
                    sizedBox20(),
                    CustomTextField(
                      labelText: 'Address',
                      controller: _addressController,
                      maxLines: 2,
                    ),
                    sizedBox20(),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            labelText: 'Pincode',
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(6),
                              NumberOnlyFormatter(
                                context,
                                onError: _showSnackBar,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: CustomTextField(
                            labelText: 'City',
                            controller: _cityController,
                          ),
                        ),
                      ],
                    ),
                    sizedBox20(),
                    GestureDetector(
                      onTap: _selectState,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          labelText: 'State',
                          controller: _stateController,
                          icon: Icons.arrow_drop_down,
                        ),
                      ),
                    ),
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
