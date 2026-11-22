import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:carsbuzz/screens/location/add_address_details_screen.dart';
import 'package:carsbuzz/services/location_service.dart';

class ConfirmMapPinScreen extends StatefulWidget {
  const ConfirmMapPinScreen({super.key});

  @override
  State<ConfirmMapPinScreen> createState() => _ConfirmMapPinScreenState();
}

class _ConfirmMapPinScreenState extends State<ConfirmMapPinScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  final LatLng _topLeft = const LatLng(37.4321, -122.0941);
  final LatLng _bottomRight = const LatLng(37.4121, -122.0641);

  // Default location (Mountain View, CA)
  LatLng _currentPosition = const LatLng(37.4221, -122.0841);
  String _currentAddress = '';
  bool _isLoading = false;
  bool _isLoadingCurrentLocation = false;
  bool _isUpdatingAddress = false;

  // Map offset tracking for dragging the map background
  Offset _mapOffset = Offset.zero;

  LatLng _convertOffsetToLatLng(Offset offset, Size size) {
    final lat = _topLeft.latitude +
        (offset.dy / size.height) * (_bottomRight.latitude - _topLeft.latitude);

    final lng = _topLeft.longitude +
        (offset.dx / size.width) *
            (_bottomRight.longitude - _topLeft.longitude);

    return LatLng(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);

    try {
      Map<String, dynamic>? locationData =
          await LocationService.getCurrentLocationWithAddress();

      if (locationData != null && mounted) {
        setState(() {
          _currentPosition = LatLng(
            locationData['latitude'],
            locationData['longitude'],
          );
          _currentAddress = locationData['address'];
          _searchController.text = locationData['address'];
        });

        // Update map camera to current location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_currentPosition),
          );
        }
      } else if (mounted) {
        // Fallback: get address for default location
        await _updateAddressForPosition(_currentPosition);
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        // Fallback: get address for default location
        await _updateAddressForPosition(_currentPosition);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCurrentLocation = false);
      }
    }
  }

  Future<void> _updateAddressForPosition(LatLng position) async {
    setState(() => _isUpdatingAddress = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        String address = _formatAddress(placemarks.first);
        setState(() {
          _currentAddress = address;
          _searchController.text = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAddress = false);
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    // Update the current position as the camera moves
    setState(() {
      _currentPosition = position.target;
    });
  }

  void _onCameraIdle() {
    // Update the address when the camera stops moving
    _updateAddressForPosition(_currentPosition);
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      List<Location> locations =
          await locationFromAddress(_searchController.text);

      if (locations.isNotEmpty && mounted) {
        final location = locations.first;
        final newPosition = LatLng(location.latitude, location.longitude);

        setState(() {
          _currentPosition = newPosition;
          _currentAddress = _searchController.text;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(newPosition),
          );
        }

        // Get more precise address for the searched location
        await _updateAddressForPosition(newPosition);
      }
    } catch (e) {
      print('Search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onMapTapped(LatLng position) async {
    setState(() => _currentPosition = position);
    await _updateAddressForPosition(position);
  }

  void _animateTapResponse(Offset tapPosition) {
    // Simple tap response without complex state management
    final mockAddresses = [
      "123 Main Street, Downtown, San Francisco, CA 94105",
      "456 Oak Avenue, Mission District, San Francisco, CA 94110",
      "789 Pine Road, SOMA, San Francisco, CA 94103",
    ];

    final newAddress =
        mockAddresses[DateTime.now().millisecond % mockAddresses.length];

    setState(() {
      _currentAddress = newAddress;
      _searchController.text = newAddress;
    });
  }

  // Extension method for Offset clamping
  Offset _clampOffset(Offset offset, Offset min, Offset max) {
    return Offset(
      offset.dx.clamp(min.dx, max.dx),
      offset.dy.clamp(min.dy, max.dy),
    );
  }

  String _formatAddress(Placemark placemark) {
    List<String> parts = [];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      parts.add(placemark.postalCode!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }

    return parts.join(', ');
  }

  Widget _buildMapOrFallback() {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: _currentPosition,
            zoom: 16,
          ),

          // 🔥 KEY PART
          onCameraMove: (position) {
            _currentPosition = position.target;
          },

          onCameraIdle: () {
            _updateAddressForPosition(_currentPosition);
          },

          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),

        // ✅ FIXED CENTER PIN
        Center(
          child: Transform.translate(
            offset: const Offset(0, -20), // 🔥 perfect anchor fix
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 40,
                  color: Colors.red,
                ),
                Container(
                  width: 10,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Optional loading indicator
        if (_isUpdatingAddress)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildFallbackMap() {
    return Stack(
      children: [
        // Simple draggable map
        GestureDetector(
          onPanUpdate: (details) {
            _mapOffset += details.delta;
            setState(() {}); // Simple state update
          },
          onPanEnd: (details) {
            // Simple address update without complex geocoding
            final mockAddresses = [
              "123 Main Street, Downtown, San Francisco, CA 94105",
              "456 Oak Avenue, Mission District, San Francisco, CA 94110",
              "789 Pine Road, SOMA, San Francisco, CA 94103",
              "321 Elm Drive, Castro, San Francisco, CA 94114",
              "654 Cedar Lane, Richmond, San Francisco, CA 94118",
              "987 Maple Court, Sunset, San Francisco, CA 94122",
              "147 Birch Street, Chinatown, San Francisco, CA 94108",
              "258 Willow Way, Haight-Ashbury, San Francisco, CA 94117",
            ];

            final newAddress = mockAddresses[
                DateTime.now().millisecond % mockAddresses.length];

            setState(() {
              _currentAddress = newAddress;
              _searchController.text = newAddress;
            });
          },
          child: Transform.translate(
            offset: _mapOffset,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade100,
                    Colors.green.shade50,
                    Colors.blue.shade50,
                  ],
                ),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: SimpleMapPainter(),
              ),
            ),
          ),
        ),

        // Move map instruction
        Positioned(
          bottom: 120,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pan_tool, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Move map to adjust location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Fixed center pin
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin shadow
              Transform.translate(
                offset: const Offset(0, 35),
                child: Container(
                  width: 20,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Main pin
              const Icon(
                Icons.location_on,
                size: 40,
                color: Colors.red,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black26,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Map offset display
        Positioned(
          bottom: 80,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              "Dragged: ${_mapOffset.dx.toStringAsFixed(0)}, ${_mapOffset.dy.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToAddressDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddAddressDetailsScreen(
          address: _currentAddress,
          latitude: _currentPosition.latitude,
          longitude: _currentPosition.longitude,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// ✅ GOOGLE MAP
          Positioned.fill(
            child: _buildMapOrFallback(),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          /// 🔥 FIXED HEADER WITH BACKGROUND
          /// 🔥 TOP SECTION (EXACT LIKE IMAGE)
          /// 🔥 TOP SECTION (FIXED HEADER + YOUR SEARCH)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                /// 🔥 PERFECT HEADER (CENTERED TITLE)
                SizedBox(
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      /// 🔙 Back button (left)
                      Positioned(
                        left: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 6,
                                color: Colors.black.withValues(alpha: 0.15),
                              )
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),

                      /// 🎯 TRUE CENTER TITLE
                      const Center(
                        child: Text(
                          "Confirm Map Pin Location",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔍 YOUR EXISTING SEARCH BAR (UNCHANGED)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withValues(alpha: 0.1),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey),
                        hintText: "Search for area, street name...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => _searchLocation(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 CENTER INSTRUCTION
          Positioned(
            top: MediaQuery.of(context).size.height * 0.40,
            left: 60,
            right: 60,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withValues(alpha: 0.3),
                    )
                  ],
                ),
                child: const Text(
                  "Move map to adjust location",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          /// 🔥 BOTTOM SHEET
          /// 🔥 BOTTOM AREA WITH FLOATING BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                /// 🔥 BOTTOM SHEET
                Container(
                  margin:
                      const EdgeInsets.only(top: 30), // 👈 space for overlap
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Delivery details",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.purple),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_currentAddress),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _navigateToAddressDetails,
                          child: const Text("Add more address details",
                              style: TextStyle(
                                color: Colors.white, // ✅ this is correct
                              )),
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔥 FLOATING BUTTON (ATTACHED)
                Positioned(
                  top: 0, // 👈 KEY FIX (not bottom!)
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _getCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black.withValues(alpha: 0.15),
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.my_location,
                                size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              "Go to current location",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Simple map painter that won't crash
class SimpleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Simple background
    final backgroundPaint = Paint()..color = Colors.green.shade50;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Simple grid pattern
    final gridPaint = Paint()
      ..color = Colors.grey.shade300.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    // Draw simple grid
    for (double x = 0; x < size.width * 2; x += 50) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (double y = 0; y < size.height * 2; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Simple features
    final parkPaint = Paint()..color = Colors.green.shade200;
    final waterPaint = Paint()..color = Colors.blue.shade200;
    final buildingPaint = Paint()..color = Colors.grey.shade400;

    // Add some simple features scattered around
    final features = [
      // Parks
      Rect.fromLTWH(size.width * 0.2, size.height * 0.3, 60, 60),
      Rect.fromLTWH(size.width * 0.7, size.height * 0.6, 80, 50),

      // Water
      Rect.fromLTWH(size.width * 0.1, size.height * 0.7, 100, 40),
      Rect.fromLTWH(size.width * 0.8, size.height * 0.2, 70, 70),

      // Buildings
      Rect.fromLTWH(size.width * 0.4, size.height * 0.4, 30, 40),
      Rect.fromLTWH(size.width * 0.6, size.height * 0.3, 25, 35),
      Rect.fromLTWH(size.width * 0.3, size.height * 0.6, 35, 30),
    ];

    // Draw parks
    canvas.drawOval(features[0], parkPaint);
    canvas.drawOval(features[1], parkPaint);

    // Draw water
    canvas.drawRRect(
      RRect.fromRectAndRadius(features[2], const Radius.circular(8)),
      waterPaint,
    );
    canvas.drawOval(features[3], waterPaint);

    // Draw buildings
    canvas.drawRect(features[4], buildingPaint);
    canvas.drawRect(features[5], buildingPaint);
    canvas.drawRect(features[6], buildingPaint);

    // Simple roads
    final roadPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 4.0;

    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
