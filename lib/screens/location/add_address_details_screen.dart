import 'package:flutter/material.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/repository_api.dart';
import 'package:carsbuzz/models/address_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddAddressDetailsScreen extends StatefulWidget {
  final String address;
  final double latitude;
  final double longitude;

  const AddAddressDetailsScreen({
    super.key,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<AddAddressDetailsScreen> createState() =>
      _AddAddressDetailsScreenState();
}

class _AddAddressDetailsScreenState extends State<AddAddressDetailsScreen> {
  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final RepositoryApi _api = ApiClient.create();

  String selectedAddressType = 'home';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Pre-fill the area field with the address
    _areaController.text = widget.address;

    // Pre-fill phone number if available in preferences
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Load saved phone number if available
      String? savedPhone = prefs.getString('user_phone');
      if (savedPhone != null && savedPhone.isNotEmpty) {
        _phoneController.text = savedPhone;
      } else {
        // Default phone number as shown in the screenshot
        _phoneController.text = '+91 8058076637';
      }

      // Load saved name if available
      String? savedName = prefs.getString('user_name');
      if (savedName != null && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _saveAddress() async {
    if (!_validateForm()) return;

    setState(() => isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userIdStr = prefs.getString('user_id');

      // Ensure user ID is available from API response
      if (userIdStr == null) {
        throw Exception('User not properly authenticated. Please login again.');
      }
      
      int userId = int.parse(userIdStr);

      AddressRequest addressRequest = AddressRequest(
        userId: userId,
        addressType: selectedAddressType.toLowerCase(),
        title: _flatController.text.trim().isNotEmpty
            ? _flatController.text.trim()
            : null,
        address: widget.address,
        locality: _areaController.text.trim(),
        latitude: widget.latitude,
        longitude: widget.longitude,
        active: true,
      );

      // Save address via API
      await _api.saveAddress(addressRequest);

      if (mounted) {
        // Save user data to preferences for future use
        if (_nameController.text.trim().isNotEmpty) {
          await prefs.setString('user_name', _nameController.text.trim());
        }
        if (_phoneController.text.trim().isNotEmpty) {
          await prefs.setString('user_phone', _phoneController.text.trim());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home screen
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      print('Error saving address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _validateForm() {
    if (_areaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter area/locality')),
      );
      return false;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return false;
    }

    return true;
  }

  Widget _buildAddressTypeSelector() {
    return Row(
      children: [
        _buildAddressTypeOption('home', 'Home', Icons.home, Colors.orange),
        const SizedBox(width: 16),
        _buildAddressTypeOption('work', 'Work', Icons.work, Colors.blue),
        const SizedBox(width: 16),
        _buildAddressTypeOption(
            'other', 'Other', Icons.location_on, Colors.purple),
      ],
    );
  }

  Widget _buildAddressTypeOption(
      String type, String label, IconData icon, Color color) {
    bool isSelected = selectedAddressType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedAddressType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).viewInsets.bottom, // ✅ no extra +16
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 🔥 IMPORTANT
            children: [
              /// 🔥 DRAG HANDLE
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// 🔥 TITLE
              const Text(
                "Add more address details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Save address as",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 10),
              _buildAddressTypeSelector(),

              const SizedBox(height: 20),

              /// FLAT
              TextField(
                controller: _flatController,
                decoration: InputDecoration(
                  hintText: "Flat / Floor / Landmark",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 6),
              const Text(
                "E.g. Floor, House no.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 16),

              const Text(
                "Area/Sector/Locality",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 8),

              /// ADDRESS CARD
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF3F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _areaController.text,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Change",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// NAME
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Name",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// PHONE
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Phone Number",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// 🔥 SAVE BUTTON (NOW SCROLLABLE ✅)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flatController.dispose();
    _areaController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
