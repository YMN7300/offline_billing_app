import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/common/components/custom_files/NumberOnlyFormatter.dart';
import 'package:offline_billing/common/components/custom_files/custom_text_field.dart';

import '../../../common/components/custom_files/custom_selector_bottom_sheet.dart';
import '../../../database/state_db.dart';
import '../../../database/vendor_db.dart';

class AddVendor extends StatefulWidget {
  final Map<String, dynamic>? vendorData; // Optional for edit mode

  const AddVendor({super.key, this.vendorData});

  @override
  State<AddVendor> createState() => _AddVendorState();
}

class _AddVendorState extends State<AddVendor> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  List<String> _states = [];
  bool _isLoadingStates = true;

  bool get isEditMode => widget.vendorData != null;

  @override
  void initState() {
    super.initState();
    _loadStates();
    if (isEditMode) _loadVendorData();
  }

  void _loadVendorData() {
    final data = widget.vendorData!;
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

    // Validate required fields
    if (name.isEmpty || phone.isEmpty || gstin.isEmpty || state.isEmpty) {
      _showSnackBar("Please fill in all required fields");
      return;
    }

    // Validate phone number (10 digits)
    if (phone.length != 10) {
      _showSnackBar("Phone number must be exactly 10 digits");
      return;
    }

    // Validate GSTIN (15 alphanumeric characters)
    if (gstin.length != 15) {
      _showSnackBar("GSTIN must be exactly 15 characters");
      return;
    }

    // Validate GSTIN format (alphanumeric)
    final gstinRegex = RegExp(r'^[A-Z0-9]{15}$');
    if (!gstinRegex.hasMatch(gstin)) {
      _showSnackBar("GSTIN must contain only letters and numbers");
      return;
    }

    // Validate pincode (6 digits if provided)
    if (pincode.isNotEmpty && pincode.length != 6) {
      _showSnackBar("Pincode must be 6 digits");
      return;
    }

    final Map<String, dynamic> vendorMap = {
      'name': name,
      'phone': phone,
      'gstin': gstin, // Now stored in uppercase
      'address': address,
      'pincode': pincode,
      'city': city,
      'state': state,
    };

    if (isEditMode) {
      vendorMap['id'] = int.tryParse(widget.vendorData!['id'].toString()) ?? 0;

      final result = await VendorDB.updateVendor(vendorMap);
      if (result == 0) {
        _showSnackBar("Failed to update vendor. Please try again.");
        return;
      }
    } else {
      await VendorDB.insertVendor(vendorMap);
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
        isEditMode ? "Edit Vendor" : "Add Vendor",
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
