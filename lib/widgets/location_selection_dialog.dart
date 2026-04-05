import 'package:flutter/material.dart';
import 'package:carsbuzz/models/address_response.dart';
import 'package:carsbuzz/services/location_service.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/repository_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationSelectionDialog extends StatefulWidget {
  final Function(String address, String? title) onLocationSelected;
  
  const LocationSelectionDialog({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationSelectionDialog> createState() => _LocationSelectionDialogState();
}

class _LocationSelectionDialogState extends State<LocationSelectionDialog> {
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
      
      if (userIdStr != null) {
        int userId = int.parse(userIdStr);
        List<AddressResponse> addresses = await _api.getAllAddresses(userId);
        
        if (mounted) {
          setState(() {
            savedAddresses = addresses;
            isLoadingSavedAddresses = false;
          });
        }
      } else {
        setState(() => isLoadingSavedAddresses = false);
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
    Navigator.pop(context);
    // TODO: Navigate to add address screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add new address feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
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
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Location
                    _buildCurrentLocationTile(),
                    
                    const SizedBox(height: 16),
                    
                    // Add new address
                    _buildAddNewAddressTile(),
                    
                    const SizedBox(height: 24),
                    
                    // Saved Addresses
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
    );
  }

  Widget _buildCurrentLocationTile() {
    return GestureDetector(
      onTap: currentLocationData != null ? _selectCurrentLocation : _getCurrentLocation,
      child: Container(
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
                    'Use Cur\rent Location',
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
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (savedAddresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
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
                    address.title ?? 'Unknown location',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (address.locality != null)
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