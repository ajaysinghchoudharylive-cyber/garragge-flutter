import 'package:flutter/material.dart';
import 'package:carsbuzz/models/address_response.dart';
import 'package:carsbuzz/services/location_service.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/repository_api.dart';
import 'package:carsbuzz/screens/location/confirm_map_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationSelectionBottomSheet extends StatefulWidget {
  final Function(String address, String? title) onLocationSelected;
  
  const LocationSelectionBottomSheet({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationSelectionBottomSheet> createState() => _LocationSelectionBottomSheetState();
}

class _LocationSelectionBottomSheetState extends State<LocationSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final RepositoryApi _api = ApiClient.create();
  
  List<AddressResponse> savedAddresses = [];
  Map<String, dynamic>? currentLocationData;
  bool isLoadingSavedAddresses = true;
  bool isLoadingCurrentLocation = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSavedAddresses(),
      _loadCurrentLocation(),
    ]);
  }

    Future<void> _loadSavedAddresses() async {
      try {
        setState(() => isLoadingSavedAddresses = true);
        
        // Get user ID from shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userIdStr = prefs.getString('user_id');
        
        // Debug: Check what's in SharedPreferences
        print('SharedPreferences keys: ${prefs.getKeys()}');
        print('User ID from SharedPreferences: $userIdStr');
        
        // Ensure user ID is available from API response
        if (userIdStr == null) {
          throw Exception('User not properly authenticated. Please login again.');
        }
        
        int userId = int.parse(userIdStr);
        print('Loading addresses for user ID: $userId');
        
        List<AddressResponse> addresses = await _api.getAllAddresses(userId);
        
        // Debug logging
        print('Received ${addresses.length} addresses from API:');
        for (int i = 0; i < addresses.length; i++) {
          final address = addresses[i];
          print('Address $i: type="${address.addressType}", title="${address.title}", address="${address.address}", active=${address.active}');
        }
        
        if (mounted) {
          setState(() {
            savedAddresses = addresses;
            isLoadingSavedAddresses = false;
          });
        }
      } catch (e) {
        print('Error loading saved addresses: $e');
        if (mounted) {
          setState(() => isLoadingSavedAddresses = false);
        }
      }
    }
  Future<void> _loadCurrentLocation() async {
    try {
      // First check if we have saved current location
      Map<String, dynamic>? savedLocation = await LocationService.getSavedCurrentLocation();
      
      if (savedLocation != null) {
        setState(() => currentLocationData = savedLocation);
      }
    } catch (e) {
      print('Error loading current location: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => isLoadingCurrentLocation = true);
      
      Map<String, dynamic>? location = await LocationService.getCurrentLocationWithAddress();
      
      if (mounted) {
        setState(() {
          currentLocationData = location;
          isLoadingCurrentLocation = false;
        });
        
        if (location == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get current location. Please check location permissions.'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        setState(() => isLoadingCurrentLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _selectCurrentLocation() {
    if (currentLocationData != null) {
      String address = currentLocationData!['address'];
      widget.onLocationSelected(address, 'Current Location');
      Navigator.pop(context);
    }
  }

  void _selectSavedAddress(AddressResponse address) {
    widget.onLocationSelected(address.address, address.title);
    Navigator.pop(context);
  }

  void _addNewAddress() {
    try {
      print('🔍 Add new location button pressed');
      Navigator.pop(context);
      print('🔍 Bottom sheet closed, navigating to ConfirmMapPinScreen...');
      
      // Navigate to confirm map pin screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            print('🔍 ConfirmMapPinScreen MaterialPageRoute builder called');
            return const ConfirmMapPinScreen();
          },
        ),
      ).then((result) {
        print('🔍 Navigation to ConfirmMapPinScreen completed with result: $result');
      }).catchError((error, stackTrace) {
        print('🔥 Navigation error: $error');
        print('🔥 Stack trace: $stackTrace');
      });
    } catch (e, stackTrace) {
      print('🔥 Error in _addNewAddress: $e');
      print('🔥 Stack trace: $stackTrace');
    }
  }


@override
Widget build(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85, // prevents full screen
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🔥 KEY for wrap content
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Select delivery location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search for area, street name...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content (scrollable when needed)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentLocationTile(),
                    const SizedBox(height: 8),
                    _buildAddNewAddressTile(),
                    const SizedBox(height: 24),

                    if (savedAddresses.isNotEmpty || isLoadingSavedAddresses)
                      _buildSavedAddressesSection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildCurrentLocationTile() {
    return GestureDetector(
      onTap: currentLocationData != null ? _selectCurrentLocation : _getCurrentLocation,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Use Current Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (currentLocationData != null)
                    Text(
                      LocationService.formatAddressForDisplay(
                        currentLocationData!['address'],
                        maxLength: 60,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Tap to get your current location',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (isLoadingCurrentLocation)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewAddressTile() {
    return GestureDetector(
      onTap: _addNewAddress,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_location,
                color: Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Add new address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddressesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SAVED ADDRESSES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (isLoadingSavedAddresses)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          )
        else if (savedAddresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            child: const Text(
              'No saved addresses yet',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...savedAddresses.map((address) => _buildSavedAddressTile(address)),
      ],
    );
  }

  Widget _buildSavedAddressTile(AddressResponse address) {
    IconData icon = _getAddressTypeIcon(address.addressType);
    
    return GestureDetector(
      onTap: () => _selectSavedAddress(address),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.orange.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.addressType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.title ?? address.address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.title != null && address.title!.isNotEmpty)
                    Text(
                      LocationService.formatAddressForDisplay(
                        address.address,
                        maxLength: 50,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressTypeIcon(String addressType) {
    switch (addressType.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
      case 'office':
        return Icons.work;
      case 'other':
      default:
        return Icons.location_on;
    }
  }
}