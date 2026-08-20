import 'dart:io';
import 'package:dio/dio.dart';
import 'package:carsbuzz/models/car_brand_model.dart';
import 'package:carsbuzz/sellcar/models/car_variant_response.dart';
import 'package:carsbuzz/sellcar/models/sell_car_form_data.dart';
import 'package:carsbuzz/network/api_constants.dart';

/// Repository for all Sell Car API calls.
/// Mirrors native: CarsLogoNameRepository, CarsModelNameLogoRepo,
/// PostCarAdsDetailsDataRepository, RemoteDraftRepository, SellCarAllBrandsRepository
class SellCarRepository {
  final Dio _dio;

  SellCarRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Content-Type': 'application/json'},
            ));

  // ─────────────────────────────────────────────────────────────────────────────
  // BRANDS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch all car brands with logos - mirrors native CARS_LOGO_NAME endpoint
  Future<List<CarBrandModel>> getCarBrands() async {
    try {
      final response = await _dio.get('cars/carLogoAndNames');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((e) => CarBrandModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODELS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch car models for a brand - mirrors native CARS_MODELS_NAMES
  Future<List<String>> getCarModels(String brandName) async {
    try {
      final response = await _dio.get('cars/$brandName/models');
      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List).map((e) => e.toString()).toList();
        }
        // Handle if API returns object with models list
        if (response.data is Map && response.data['models'] != null) {
          return (response.data['models'] as List)
              .map((e) => e.toString())
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // VARIANTS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch variants for a brand + model - mirrors native GET_VARIANTS
  Future<List<CarVariantResponse>> getVariants(
      String brandName, int modelId) async {
    try {
      final response =
          await _dio.get('cars/$brandName/models/$modelId/variants');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => CarVariantResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CITIES
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch all Indian cities - mirrors native GET_CITIES_NEW
  Future<List<String>> getAllCities() async {
    try {
      final response = await _dio.get('cars/cities');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // POST AD (mirrors native POST_YOUR_AD = "cars/postad")
  // ─────────────────────────────────────────────────────────────────────────────

  /// Upload car ad with images - mirrors native PostCarAdsDetailsDataRepository
  /// This uses multipart form data matching the native implementation
  Future<PostAdResult> postCarAd(
    SellCarFormData formData,
    List<String> imagePaths,
  ) async {
    try {
      final formDataMap = FormData();

      // Add all text fields
      final jsonFields = formData.toPostAdJson();
      jsonFields.forEach((key, value) {
        if (value != null) {
          formDataMap.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Add image files
      for (final path in imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split('/').last;
          formDataMap.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(path, filename: fileName),
          ));
        }
      }

      final response = await _dio.post(
        'cars/postad',
        data: formDataMap,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final message =
            response.data is Map ? response.data['message'] ?? 'Success' : 'Ad posted successfully';
        return PostAdResult(success: true, message: message);
      }

      return PostAdResult(
        success: false,
        message: response.data?['message'] ?? 'Failed to post ad',
      );
    } on DioException catch (e) {
      return PostAdResult(
        success: false,
        message: e.response?.data?['message'] ?? e.message ?? 'Network error',
      );
    } catch (e) {
      return PostAdResult(success: false, message: 'Unexpected error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DRAFTS (mirrors native RemoteDraftRepository)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Create a new remote draft
  Future<int?> createDraft(int userId, SellCarFormData formData) async {
    try {
      final response = await _dio.post(
        'cars/sell-car/draft',
        data: {
          'userId': userId,
          ...formData.toDraftJson(),
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['id'] as int?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update an existing remote draft
  Future<bool> updateDraft(int draftId, int userId, SellCarFormData formData) async {
    try {
      final response = await _dio.put(
        'cars/sell-car/draft/$draftId',
        data: {
          'userId': userId,
          ...formData.toDraftJson(),
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get all drafts for a user
  Future<List<Map<String, dynamic>>> getAllDrafts(int userId) async {
    try {
      final response = await _dio.get('cars/sell-car/draft/$userId');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Delete a draft
  Future<bool> deleteDraft(int draftId, int userId) async {
    try {
      final response = await _dio.delete(
        'cars/sell-car/draft/$draftId',
        queryParameters: {'userId': userId},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Upload images to a draft
  Future<bool> uploadDraftImages(
      int draftId, int userId, List<String> imagePaths) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('userId', userId.toString()));

      for (final path in imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          formData.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(path, filename: path.split('/').last),
          ));
        }
      }

      final response = await _dio.post(
        'cars/sell-car/draft/$draftId/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Mark a draft as complete
  Future<bool> markDraftComplete(int draftId, int userId) async {
    try {
      final response = await _dio.put(
        'cars/sell-car/draft/$draftId/complete',
        data: {'userId': userId},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // REGISTRATION YEARS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch registration years - mirrors native CARS_REGISTRATION_YEAR
  Future<List<int>> getRegistrationYears() async {
    try {
      final response = await _dio.get('cars/carsRegistrationsYears');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((e) => e as int).toList();
      }
      // Fallback: generate years locally
      final currentYear = DateTime.now().year;
      return List.generate(16, (i) => currentYear - i);
    } catch (e) {
      final currentYear = DateTime.now().year;
      return List.generate(16, (i) => currentYear - i);
    }
  }
}

/// Result of posting a car ad
class PostAdResult {
  final bool success;
  final String message;

  PostAdResult({required this.success, required this.message});
}
