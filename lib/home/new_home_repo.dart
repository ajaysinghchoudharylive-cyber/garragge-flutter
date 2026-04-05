import 'package:carsbuzz/models/address_response.dart';
import 'package:carsbuzz/models/banner_data_response.dart';
import 'package:carsbuzz/models/category_response.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:flutter/foundation.dart';

class NewHomeRepo {
  final _apiClient = ApiClient.create();

  // Fetch current user address
  Future<AddressResponse?> getCurrentAddress(int userId) async {
    try {
      final response = await _apiClient.getCurrentAddress(userId);
      return response;
    } catch (e) {
      debugPrint('Error fetching current address: $e');
      return null;
    }
  }

  // Fetch all addresses for user
  Future<List<AddressResponse>> getAllAddresses(int userId) async {
    try {
      final response = await _apiClient.getAllAddresses(userId);
      return response;
    } catch (e) {
      debugPrint('Error fetching all addresses: $e');
      return [];
    }
  }

  // Fetch banners for home screen
  Future<List<BannerDataResponse>> getBanners() async {
    try {
      final response = await _apiClient.getBanners();
      return response.where((banner) => banner.shouldShow).toList();
    } catch (e) {
      debugPrint('Error fetching banners: $e');
      return [];
    }
  }

  // Fetch categories (existing functionality)
  Future<List<CategoryResponse>> getCategories() async {
    try {
      final response = await _apiClient.getAllCategories();
      return response;
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  // Fetch all home data at once
  Future<Map<String, dynamic>> fetchHomeData(int userId) async {
    try {
      final results = await Future.wait([
        getCurrentAddress(userId),
        getBanners(),
        getCategories(),
      ]);

      return {
        'currentAddress': results[0] as AddressResponse?,
        'banners': results[1] as List<BannerDataResponse>,
        'categories': results[2] as List<CategoryResponse>,
      };
    } catch (e) {
      debugPrint('Error fetching home data: $e');
      return {
        'currentAddress': null,
        'banners': <BannerDataResponse>[],
        'categories': <CategoryResponse>[],
      };
    }
  }
}