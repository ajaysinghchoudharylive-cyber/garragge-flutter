import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocationService {
  static const String _currentLocationKey = 'current_location';
  
  /// Check if location services are enabled and permissions are granted
  static Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get address from coordinates
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}, ${place.country}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return null;
  }

  /// Get current location with address
  static Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) return null;

      String? address = await getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );

      if (address == null) return null;

      Map<String, dynamic> locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Save to local storage
      await _saveCurrentLocationToLocal(locationData);

      return locationData;
    } catch (e) {
      print('Error getting current location with address: $e');
      return null;
    }
  }

  /// Save current location to local storage
  static Future<void> _saveCurrentLocationToLocal(Map<String, dynamic> locationData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String locationJson = json.encode(locationData);
      await prefs.setString(_currentLocationKey, locationJson);
      print('Current location saved to local storage');
    } catch (e) {
      print('Error saving current location: $e');
    }
  }

  /// Get saved current location from local storage
  static Future<Map<String, dynamic>?> getSavedCurrentLocation() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? locationJson = prefs.getString(_currentLocationKey);
      if (locationJson != null) {
        Map<String, dynamic> locationData = json.decode(locationJson);
        return locationData;
      }
    } catch (e) {
      print('Error getting saved current location: $e');
    }
    return null;
  }

  /// Clear saved current location
  static Future<void> clearSavedCurrentLocation() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentLocationKey);
    } catch (e) {
      print('Error clearing saved current location: $e');
    }
  }

  /// Format address for display (shortened version)
  static String formatAddressForDisplay(String fullAddress, {int maxLength = 50}) {
    if (fullAddress.length <= maxLength) {
      return fullAddress;
    }
    return '${fullAddress.substring(0, maxLength)}...';
  }
}