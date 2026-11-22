import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:carsbuzz/models/car_brand_model.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/api_constants.dart';
import 'package:carsbuzz/sellcar/models/sell_car_form_data.dart';
import 'package:carsbuzz/sellcar/models/sell_car_models.dart';

/// All Sell Car API calls. Mirrors the Android repositories (CarsLogoNameRepository,
/// CarsModelNameLogoRepo, PostCarAdsDetailsDataRepository, RemoteDraftRepository) and runs on the
/// shared [ApiClient.dio], so every call carries the JWT and renews it on 401.
///
/// Read calls THROW on failure so the screens can show a retry; best-effort calls (draft sync,
/// upload pre-check) swallow errors and return a safe default.
class SellCarRepository {
  final Dio _dio;

  SellCarRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  // ── Brands / models / variants / years ───────────────────────────────────────

  /// GET cars/carLogoAndNames
  Future<List<CarBrandModel>> getCarBrands() async {
    final response = await _dio.get<dynamic>(ApiConstants.carBrands);
    final data = response.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => CarBrandModel.fromJson(Map<String, dynamic>.from(e)))
        .where((b) => b.brandName.isNotEmpty)
        .toList();
  }

  /// GET cars/{brandName}/models. The backend appends the synthetic "Other" entry (id -1).
  Future<List<CarModelItem>> getModels(String brandName) async {
    final response =
        await _dio.get<dynamic>(ApiConstants.modelsOf(brandName));
    final data = response.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => CarModelItem.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.name.isNotEmpty)
        .toList();
  }

  /// GET cars/{brandName}/models/{modelId}/variants
  Future<List<CarVariantItem>> getVariants(String brandName, int modelId) async {
    if (modelId <= 0) return [];
    final response =
        await _dio.get<dynamic>(ApiConstants.variantsOf(brandName, modelId));
    final data = response.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => CarVariantItem.fromJson(Map<String, dynamic>.from(e)))
        .where((v) => v.name.isNotEmpty)
        .toList();
  }

  /// GET cars/carsRegistrationsYears -> [{registration_years: 2024}, ...]. Falls back to the last
  /// 25 years if the call fails, since this list is only a convenience.
  Future<List<int>> getRegistrationYears() async {
    try {
      final response =
          await _dio.get<dynamic>(ApiConstants.registrationYears);
      final data = response.data;
      if (data is List) {
        final years = data
            .whereType<Map>()
            .map((e) => (e['registration_years'] as num?)?.toInt())
            .whereType<int>()
            .toList()
          ..sort((a, b) => b.compareTo(a));
        if (years.isNotEmpty) return years;
      }
    } catch (_) {}
    final current = DateTime.now().year;
    return List.generate(25, (i) => current - i);
  }

  // ── Upload limit ─────────────────────────────────────────────────────────────

  /// Advisory pre-check before posting (the server is authoritative). Only applies when the admin
  /// "upload limit" flag is on. On any failure the user is allowed through.
  Future<UploadStatus> checkUploadStatus(int userId) async {
    try {
      final flags = await _dio.get<dynamic>(ApiConstants.featureFlags);
      final flagData = flags.data;
      final limitOn = flagData is Map && flagData['uploadLimitEnabled'] == true;
      if (!limitOn) return UploadStatus.allowed;

      final response = await _dio.get<dynamic>(
        ApiConstants.uploadStatus,
        queryParameters: {'userId': userId},
      );
      final data = response.data;
      if (data is Map) {
        return UploadStatus.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return UploadStatus.allowed;
  }

  // ── Post ad ──────────────────────────────────────────────────────────────────

  /// POST cars/postad (multipart), identical to the Android request:
  /// - part `carDetails`: the ad as JSON (content-type application/json)
  /// - repeated part `file`: one per photo
  /// - optional part `rcFile`: RC proof photo (required when an "Other" option was picked)
  /// - query `draftId`: the server removes that draft once the ad is saved
  Future<PostAdResult> postAd(
    SellCarFormData formData, {
    int? draftId,
    void Function(int percent)? onProgress,
  }) async {
    try {
      final form = FormData();

      form.files.add(MapEntry(
        'carDetails',
        MultipartFile.fromString(
          jsonEncode(formData.toPostAdJson()),
          contentType: MediaType('application', 'json'),
        ),
      ));

      for (final path in formData.imagePaths) {
        form.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(path, filename: _fileName(path)),
        ));
      }

      final rc = formData.rcImagePath;
      if (formData.requiresRc && rc != null && rc.isNotEmpty) {
        form.files.add(MapEntry(
          'rcFile',
          await MultipartFile.fromFile(rc, filename: _fileName(rc)),
        ));
      }

      final response = await _dio.post<dynamic>(
        ApiConstants.postAd,
        data: form,
        queryParameters: {if (draftId != null) 'draftId': draftId},
        options: Options(receiveTimeout: const Duration(minutes: 3)),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call((sent * 100 ~/ total).clamp(0, 100));
        },
      );

      final data = response.data;
      final status = data is Map
          ? ((data['status'] ?? data['statusCode']) as num?)?.toInt()
          : null;
      final message =
          data is Map ? data['message']?.toString() : null;
      if (status != null && status >= 400) {
        return PostAdResult(
          success: false,
          message: message ?? 'Failed to post ad',
          errorCode: data is Map ? data['errorCode']?.toString() : null,
        );
      }
      return PostAdResult(
        success: true,
        message: message ?? 'Your ad has been submitted',
        adId: data is Map ? (data['adId'] as num?)?.toInt() : null,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      return PostAdResult(
        success: false,
        message: (data is Map ? data['message']?.toString() : null) ??
            _networkMessage(e),
        errorCode: data is Map ? data['errorCode']?.toString() : null,
      );
    } catch (e) {
      return PostAdResult(success: false, message: 'Unexpected error: $e');
    }
  }

  // ── Remote drafts (best effort) ──────────────────────────────────────────────

  /// POST cars/drafts?userId= -> returns the new draft id, or null on failure.
  Future<int?> createDraft(int userId, SellCarFormData formData) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiConstants.drafts,
        queryParameters: {'userId': userId},
        data: formData.toDraftFields(),
      );
      final data = response.data;
      return data is Map ? (data['id'] as num?)?.toInt() : null;
    } catch (_) {
      return null;
    }
  }

  /// PUT cars/drafts/{id}?userId=
  Future<bool> updateDraft(
      int draftId, int userId, SellCarFormData formData) async {
    try {
      await _dio.put<dynamic>(
        ApiConstants.draftById(draftId),
        queryParameters: {'userId': userId},
        data: formData.toDraftFields(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// DELETE cars/drafts/{id}?userId=
  Future<bool> deleteDraft(int draftId, int userId) async {
    try {
      await _dio.delete<dynamic>(
        ApiConstants.draftById(draftId),
        queryParameters: {'userId': userId},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────────

  String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;

  String _networkMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The upload timed out. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      default:
        return e.message ?? 'Network error';
    }
  }
}

/// Result of posting a car ad.
class PostAdResult {
  final bool success;
  final String message;

  /// Server error code, e.g. `UPLOAD_LIMIT_REACHED` (HTTP 403).
  final String? errorCode;
  final int? adId;

  PostAdResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.adId,
  });

  bool get isUploadLimitReached => errorCode == 'UPLOAD_LIMIT_REACHED';
}
