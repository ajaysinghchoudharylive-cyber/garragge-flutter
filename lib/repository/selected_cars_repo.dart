import 'dart:convert';
import 'package:carsbuzz/models/selected_car.dart';
import 'package:carsbuzz/network/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarBrand {
  final String logoUrl;
  final String brandName;

  CarBrand({required this.logoUrl, required this.brandName});

  factory CarBrand.fromJson(Map<String, dynamic> json) {
    return CarBrand(
      logoUrl: json['cars_logo'] ?? '', // API uses cars_logo
      brandName: json['cars_name'] ?? '', // API uses cars_name
    );
  }
}

class CarModel {
  final String modelName;
  final String? imageUrl;

  CarModel({required this.modelName, this.imageUrl});

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      modelName: json['model_name'] ?? '', // API uses model_name
      imageUrl: json['imageUrl'],
    );
  }
}

class SelectedCarsRepo {
  static const String _carBrandsEndpoint = 'cars/carLogoAndNames';
  static const String _carModelsEndpoint = 'cars/cars/{brandName}/models';
  
  late final Dio _dio;

  SelectedCarsRepo() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          "Content-Type": "application/json",
        },
      ),
    );
    
    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (object) {
          print(object);
        },
      ),
    );
  }

  // Fetch all car brands
  Future<List<CarBrand>> fetchAllCarBrands() async {
    try {
      print('🚗 Fetching car brands from: $_carBrandsEndpoint');

      final response = await _dio.get(_carBrandsEndpoint);
      print('🚗 Car brands response status: ${response.statusCode}');
      print('🚗 Car brands response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => CarBrand.fromJson(json)).toList();
      } else {
        print('❌ Failed to fetch car brands: ${response.statusCode}');
        throw Exception('Failed to load car brands');
      }
    } catch (e) {
      print('❌ Error fetching car brands: $e');
      throw Exception('Failed to load car brands: $e');
    }
  }

  // Fetch models for a specific brand
  Future<List<CarModel>> fetchCarModels(String brandName) async {
    try {
      if (brandName.trim().isEmpty) {
        print('❌ Brand name is empty, cannot fetch models');
        return [];
      }
      
      final endpoint = _carModelsEndpoint.replaceAll('{brandName}', brandName.trim());
      print('🚗 Fetching car models from: $endpoint');

      final response = await _dio.get(endpoint);
      print('🚗 Car models response status: ${response.statusCode}');
      print('🚗 Car models response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => CarModel.fromJson(json)).toList();
      } else {
        print('❌ Failed to fetch car models: ${response.statusCode}');
        return []; // Return empty list instead of throwing
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 405) {
        print('⚠️ Car models endpoint not implemented yet (405), returning empty list');
        return []; // Return empty list for 405 Method Not Allowed
      }
      print('❌ Error fetching car models: $e');
      return []; // Return empty list instead of throwing
    } catch (e) {
      print('❌ Error fetching car models: $e');
      return []; // Return empty list instead of throwing
    }
  }

  // Fetch user's selected cars
  Future<List<SelectedCar>> fetchSelectedCars(int userId) async {
    try {
      final endpoint = ApiConstants.getSelectedCars.replaceAll('{userId}', userId.toString());
      print('🚗 Fetching selected cars from: $endpoint');

      final response = await _dio.get(endpoint);
      print('🚗 Selected cars response status: ${response.statusCode}');
      print('🚗 Selected cars response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => SelectedCar.fromJson(json)).toList();
      } else {
        print('❌ Failed to fetch selected cars: ${response.statusCode}');
        return []; // Return empty list instead of throwing
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 405) {
        print('⚠️ Selected cars endpoint not implemented yet (405), returning empty list');
        return []; // Return empty list for 405 Method Not Allowed
      }
      print('❌ Error fetching selected cars: $e');
      return []; // Return empty list instead of throwing
    } catch (e) {
      print('❌ Error fetching selected cars: $e');
      return []; // Return empty list instead of throwing
    }
  }

  // Get the primary/active selected car for the user
  Future<SelectedCar?> fetchPrimarySelectedCar(int userId) async {
    try {
      final selectedCars = await fetchSelectedCars(userId);
      if (selectedCars.isNotEmpty) {
        // Find the car marked as primary
        try {
          return selectedCars.firstWhere((car) => car.primary);
        } catch (e) {
          // No primary car found, return first car if available
          print('🚗 No primary car found, returning first available car');
          return selectedCars.first;
        }
      }
    } catch (e) {
      print('❌ Error fetching primary selected car from API: $e');
    }
    
    // Fallback to local storage
    return await _fetchPrimaryCarFromLocalStorage();
  }

        Future<SelectedCar?> _fetchPrimaryCarFromLocalStorage() async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final carName = prefs.getString('selected_car_name');
            final carImage = prefs.getString('selected_car_image');
            final isPrimary = prefs.getBool('selected_car_primary') ?? true;
      
            if (carName != null && carImage != null) {
              print('🚗 Loading car from local storage: $carName');
              return SelectedCar(
                carImage: carImage,
                carName: carName,
                primary: isPrimary,
              );
            }
          } catch (e) {
            print('❌ Error loading car from local storage: $e');
          }
      
          print('🚗 No car found in local storage either');
          return null;
        }
      
        // Add a new selected car for the user
        Future<bool> addSelectedCar({    required int userId,
    required String carName,
    required String carImage,
    bool setPrimary = false,
  }) async {
    try {
      final endpoint = ApiConstants.postSelectedCars.replaceAll('{userId}', userId.toString());
      
      // First, fetch existing selected cars
      final existingCars = await fetchSelectedCars(userId);
      print('🚗 Found ${existingCars.length} existing selected cars');
      
      // Create the new car object
      final newCar = SelectedCar(
        carName: carName,
        carImage: carImage,
        primary: setPrimary,
      );
      
      // If setPrimary is true, update existing cars to not be primary
      final updatedExistingCars = existingCars.map((car) {
        if (setPrimary) {
          return SelectedCar(
            carName: car.carName,
            carImage: car.carImage,
            primary: false, // Set all existing cars to non-primary
          );
        }
        return car;
      }).toList();
      
      // Combine existing cars with the new car
      final allCars = [...updatedExistingCars, newCar];
      
      // Convert all cars to JSON format
      final requestBody = allCars.map((car) => car.toJson()).toList();

      print('🚗 Adding selected car to: $endpoint');
      print('🚗 Including ${existingCars.length} existing cars + 1 new car');
      print('🚗 Request body: ${json.encode(requestBody)}');

      final response = await _dio.post(
        endpoint,
        data: requestBody, // Send all cars (existing + new)
      );

      print('🚗 Add selected car response status: ${response.statusCode}');
      print('🚗 Add selected car response data: ${response.data}');

      return response.statusCode! >= 200 && response.statusCode! < 300;
    } on DioException catch (e) {
      print('❌ DioException adding selected car: ${e.response?.statusCode} - ${e.response?.statusMessage}');
      print('❌ Response data: ${e.response?.data}');
      
      // Try alternative format if first attempt fails
      if (e.response?.statusCode == 400) {
        return await _addSelectedCarAlternativeFormat(
          userId: userId,
          carName: carName,
          carImage: carImage,
          setPrimary: setPrimary,
        );
      }
      return false;
    } catch (e) {
      print('❌ Error adding selected car: $e');
      return false;
    }
  }

  // Alternative format for API request
  Future<bool> _addSelectedCarAlternativeFormat({
    required int userId,
    required String carName,
    required String carImage,
    bool setPrimary = false,
  }) async {
    try {
      final endpoint = ApiConstants.postSelectedCars.replaceAll('{userId}', userId.toString());
      
      // First, fetch existing selected cars (same as main method)
      final existingCars = await fetchSelectedCars(userId);
      print('🚗 (Alternative format) Found ${existingCars.length} existing selected cars');
      
      // Create the new car object
      final newCar = SelectedCar(
        carName: carName,
        carImage: carImage,
        primary: setPrimary,
      );
      
      // If setPrimary is true, update existing cars to not be primary
      final updatedExistingCars = existingCars.map((car) {
        if (setPrimary) {
          return SelectedCar(
            carName: car.carName,
            carImage: car.carImage,
            primary: false, // Set all existing cars to non-primary
          );
        }
        return car;
      }).toList();
      
      // Combine existing cars with the new car
      final allCars = [...updatedExistingCars, newCar];
      
      // Try alternative object format with all cars
      final requestBody = {
        'cars': allCars.map((car) => car.toJson()).toList()
      };

      print('🚗 Trying alternative format to: $endpoint');
      print('🚗 (Alternative format) Including ${existingCars.length} existing cars + 1 new car');
      print('🚗 Alternative request body: ${json.encode(requestBody)}');

      final response = await _dio.post(
        endpoint,
        data: requestBody,
      );

      print('🚗 Alternative response status: ${response.statusCode}');
      print('🚗 Alternative response data: ${response.data}');

      return response.statusCode! >= 200 && response.statusCode! < 300;
    } catch (e) {
      print('❌ Alternative format also failed: $e');
      return false;
    }
  }

  // Update selected cars (replace all user's selected cars)
  Future<bool> updateSelectedCars(int userId, List<SelectedCar> cars) async {
    try {
      final endpoint = ApiConstants.postSelectedCars.replaceAll('{userId}', userId.toString());
      
      final requestBody = cars.map((car) => car.toJson()).toList();

      print('🚗 Updating selected cars to: $endpoint');
      print('🚗 Request body: ${json.encode(requestBody)}');

      final response = await _dio.post(
        endpoint,
        data: requestBody,
      );

      print('🚗 Update selected cars response status: ${response.statusCode}');
      print('🚗 Update selected cars response data: ${response.data}');

      return response.statusCode! >= 200 && response.statusCode! < 300;
    } catch (e) {
      print('❌ Error updating selected cars: $e');
      return false;
    }
  }
}