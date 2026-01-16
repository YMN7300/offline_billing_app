import 'package:flutter/material.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/database/profile_db.dart';

/// Singleton cache for business name
/// Singleton cache for business name
class BusinessNameCache {
  static String? businessName;
  static final List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static Future<void> load() async {
    final profile = await ProfileDB.getProfile();
    businessName = profile?.businessName ?? '';
    _notifyListeners();
  }

  static void set(String name) {
    businessName = name;
    _notifyListeners();
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}

class FixAppBar extends StatefulWidget implements PreferredSizeWidget {
  const FixAppBar({super.key});

  @override
  State<FixAppBar> createState() => _FixAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _FixAppBarState extends State<FixAppBar> {
  final TextEditingController _businessNameController = TextEditingController();
  final FocusNode _businessNameFocusNode = FocusNode();
  bool _showSaveButton = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessName();
    _businessNameFocusNode.addListener(_handleFocusChange);
    BusinessNameCache.addListener(_onBusinessNameChanged);
  }

  @override
  void dispose() {
    _businessNameFocusNode.removeListener(_handleFocusChange);
    _businessNameController.dispose();
    _businessNameFocusNode.dispose();
    BusinessNameCache.removeListener(_onBusinessNameChanged);
    super.dispose();
  }

  void _onBusinessNameChanged() {
    if (mounted) {
      setState(() {
        _businessNameController.text = BusinessNameCache.businessName ?? '';
      });
    }
  }

  void _handleFocusChange() {
    setState(() {
      _showSaveButton =
          _businessNameFocusNode.hasFocus &&
          _businessNameController.text.isNotEmpty;
    });
  }

  void _loadBusinessName() {
    // use cached name immediately if exists
    _businessNameController.text = BusinessNameCache.businessName ?? '';
    if ((_businessNameController.text).isEmpty) {
      // fallback: load from db
      ProfileDB.getProfile().then((profile) {
        if (profile != null && profile.businessName.isNotEmpty) {
          _businessNameController.text = profile.businessName;
          BusinessNameCache.set(profile.businessName);
          setState(() {});
        }
      });
    }
  }

  Future<void> _saveBusinessName() async {
    if (_businessNameController.text.isEmpty) return;

    try {
      // Get the current profile from DB
      final existingProfile = await ProfileDB.getProfile();

      if (existingProfile != null) {
        // Keep all other values, just update businessName
        final updatedProfile = existingProfile.copyWith(
          businessName: _businessNameController.text,
        );

        await ProfileDB.insertOrUpdateProfile(updatedProfile);
      } else {
        // No profile exists yet, create new with just name
        final newProfile = ProfileModel(
          businessName: _businessNameController.text,
          phone: '',
          email: '',
          address: '',
          city: '',
          pincode: '',
          state: '',
          gst: '',
          businessType: '',
          businessCategory: '',
        );
        await ProfileDB.insertOrUpdateProfile(newProfile);
      }

      BusinessNameCache.set(_businessNameController.text);
      _businessNameFocusNode.unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Business name saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error saving business name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: primary,
      leading: IconButton(
        onPressed: () {
          Navigator.pushNamed(context, "profile_page").then((newName) {
            if (newName != null && newName is String && newName.isNotEmpty) {
              setState(() {
                _businessNameController.text = newName;
                BusinessNameCache.set(newName);
              });
            } else {
              _loadBusinessName();
            }
          });
        },
        icon: const Icon(Icons.person, color: Colors.white, size: 20),
      ),

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _businessNameController,
                focusNode: _businessNameFocusNode,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  hintText: "Business Name",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  prefixIcon: Icon(Icons.edit, color: Colors.white, size: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {
                    _showSaveButton =
                        _businessNameFocusNode.hasFocus && value.isNotEmpty;
                  });
                },
              ),
            ),
          ),
          if (_showSaveButton)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: OutlinedButton(
                onPressed: _saveBusinessName,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.pushNamed(context, "notification");
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white, size: 20),
          onPressed: () async {
            final result = await Navigator.pushNamed(context, "setting");
            if (result != null && result is String) {
              setState(() {
                _businessNameController.text = result;
                BusinessNameCache.set(result);
              });
            }
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
