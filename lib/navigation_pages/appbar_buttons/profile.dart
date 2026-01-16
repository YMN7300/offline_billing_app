import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/common/components/custom_files/NumberOnlyFormatter.dart';
import 'package:offline_billing/common/components/custom_files/custom_selector_bottom_sheet.dart';
import 'package:offline_billing/common/components/custom_files/custom_text_field.dart';
import 'package:offline_billing/database/profile_db.dart';
import 'package:offline_billing/database/state_db.dart';

import '../../database/business_categories_db.dart';
import '../../database/business_types_db.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _gstController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _businessCategoryController = TextEditingController();
  File? _profileImage;
  String? _imagePath;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final croppedFile = await _cropImage(pickedFile.path);
      if (croppedFile != null) {
        setState(() {
          _profileImage = File(croppedFile.path);
          _imagePath = croppedFile.path;
        });
      }
    }
  }

  Future<CroppedFile?> _cropImage(String filePath) async {
    return await ImageCropper().cropImage(
      sourcePath: filePath,
      aspectRatio: const CropAspectRatio(
        ratioX: 1,
        ratioY: 1,
      ), // Default to square
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Profile Image',
          toolbarColor: primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: primary,
          dimmedLayerColor: Colors.black.withOpacity(0.6),
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: 'Profile Image',
          aspectRatioPickerButtonHidden: false,
          resetButtonHidden: false,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: false,
        ),
      ],
    );
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Top row with close button, title, and delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Profile images",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_profileImage != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _profileImage = null;
                          _imagePath = null;
                        });
                      },
                    )
                  else
                    const SizedBox(
                      width: 48,
                    ), // For alignment when no delete button
                ],
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Camera option
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt, size: 32),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _pickImage(ImageSource.camera);
                        },
                      ),
                      const Text('Camera'),
                    ],
                  ),

                  // Gallery option
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library, size: 32),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _pickImage(ImageSource.gallery);
                        },
                      ),
                      const Text('Gallery'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  List<String> _states = [];
  List<String> _businessTypes = [];
  List<String> _businessCategories = [];
  bool _isLoadingStates = true;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _loadProfileData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final states = await StateDB.getAllStates();
      final types = await BusinessTypeDB.getAllTypes();
      final categories = await BusinessCategoryDB.getAllCategories();
      setState(() {
        _states = states;
        _businessTypes = types;
        _businessCategories = categories;
        _isLoadingStates = false;
      });
    } catch (e) {
      _showSnackBar("Failed to load data");
      setState(() {
        _isLoadingStates = false;
      });
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await ProfileDB.getProfile();
      if (profile != null) {
        setState(() {
          _businessNameController.text = profile.businessName;
          _phoneController.text = profile.phone;
          _emailController.text = profile.email;
          _addressController.text = profile.address;
          _cityController.text = profile.city;
          _pincodeController.text = profile.pincode;
          _stateController.text = profile.state;
          _gstController.text = profile.gst;
          _businessTypeController.text = profile.businessType;
          _businessCategoryController.text = profile.businessCategory;
          _imagePath = profile.imagePath;
          if (profile.imagePath != null) {
            _profileImage = File(profile.imagePath!);
          }
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load profile data");
    } finally {
      setState(() {
        _isLoadingProfile = false;
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

  Future<void> _showSelectionBottomSheet({
    required String title,
    required List<String> options,
    required TextEditingController controller,
    bool enableAdd = true,
  }) async {
    final selected = await showOptionSelectorBottomSheet(
      context: context,
      title: title,
      initialOptions: options,
      selectedOption: controller.text,
      enableCustomAdd: enableAdd,
    );

    if (selected != null && selected.isNotEmpty) {
      if (enableAdd && !options.contains(selected)) {
        setState(() {
          if (title == 'Business Type') {
            _businessTypes.add(selected);
            BusinessTypeDB.insertType(selected);
          } else if (title == 'Business Category') {
            _businessCategories.add(selected);
            BusinessCategoryDB.insertCategory(selected);
          }
        });
      }
      controller.text = selected;
    }
  }

  Future<void> _submitForm() async {
    if (_businessNameController.text.isEmpty) {
      _showSnackBar("Please enter business name");
      return;
    }

    try {
      final profile = ProfileModel(
        businessName: _businessNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        city: _cityController.text,
        pincode: _pincodeController.text,
        state: _stateController.text,
        gst: _gstController.text,
        businessType: _businessTypeController.text,
        businessCategory: _businessCategoryController.text,
        imagePath: _imagePath,
      );

      final result = await ProfileDB.insertOrUpdateProfile(profile);

      if (result > 0) {
        _showSuccessSnackBar("Profile saved successfully");
        Navigator.pop(context, _businessNameController.text); // return new name
      } else {
        _showSnackBar("Failed to save profile - no changes made");
      }
    } catch (e) {
      print('Error saving profile: $e');
      _showSnackBar("Failed to save profile: ${e.toString()}");
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFullScreenImage() {
    if (_profileImage == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.file(_profileImage!),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 30),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _showImagePickerOptions();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePicture() {
    return Column(
      children: [
        GestureDetector(
          onTap:
              _profileImage != null
                  ? _showFullScreenImage
                  : _showImagePickerOptions,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child:
                    _profileImage == null
                        ? Icon(Icons.person, size: 60, color: Colors.grey[700])
                        : null,
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue[700],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Text(
            _profileImage == null ? "Add photo" : "Edit",
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorField({
    required String label,
    required TextEditingController controller,
    required List<String> options,
    required String dialogTitle,
    bool enableAdd = true,
  }) {
    return GestureDetector(
      onTap:
          () => _showSelectionBottomSheet(
            title: dialogTitle,
            options: options,
            controller: controller,
            enableAdd: enableAdd,
          ),
      child: AbsorbPointer(
        child: CustomTextField(
          labelText: label,
          controller: controller,
          icon: Icons.arrow_drop_down,
        ),
      ),
    );
  }

  Widget sizedBox20() => const SizedBox(height: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, _businessNameController.text);
          },
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
        ),
      ),
      body:
          _isLoadingStates || _isLoadingProfile
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfilePicture(),
                    sizedBox20(),
                    CustomTextField(
                      labelText: 'Business Name',
                      controller: _businessNameController,
                    ),
                    sizedBox20(),
                    CustomTextField(
                      labelText: 'Phone No.',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        NumberOnlyFormatter(context, onError: _showSnackBar),
                      ],
                    ),
                    sizedBox20(),
                    CustomTextField(
                      labelText: 'Email ID',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    sizedBox20(),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Business Address'),
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
                      ],
                    ),
                    sizedBox20(),
                    _buildSelectorField(
                      label: 'State',
                      controller: _stateController,
                      options: _states,
                      dialogTitle: 'State',
                      enableAdd: false,
                    ),
                    sizedBox20(),
                    // In the ProfilePage class, replace the current GST TextField with this:
                    CustomTextField(
                      labelText: 'GST No.',
                      controller: _gstController,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                        GstinFormatter(context, onError: _showSnackBar),
                      ],
                      onChanged: (value) {
                        // Force uppercase in case the formatter didn't catch it
                        if (value != value.toUpperCase()) {
                          _gstController.value = _gstController.value.copyWith(
                            text: value.toUpperCase(),
                            selection: TextSelection.collapsed(
                              offset: value.length,
                            ),
                          );
                        }
                      },
                    ),
                    sizedBox20(),
                    _buildSelectorField(
                      label: 'Business Type',
                      controller: _businessTypeController,
                      options: _businessTypes,
                      dialogTitle: 'Business Type',
                    ),
                    sizedBox20(),
                    _buildSelectorField(
                      label: 'Business Category',
                      controller: _businessCategoryController,
                      options: _businessCategories,
                      dialogTitle: 'Business Category',
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(350, 50),
            backgroundColor: primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "SAVE",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
