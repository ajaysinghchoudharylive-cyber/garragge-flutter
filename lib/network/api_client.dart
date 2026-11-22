import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_constants.dart';
import 'auth_interceptor.dart';
import 'repository_api.dart';

/// Single shared HTTP client for the whole app (mirrors the Android RetrofitModule + OkHttp
/// interceptors): HTTPS base URL, JWT auth header, silent token refresh on 401.
class ApiClient {
  ApiClient._();

  static Dio? _dio;

  /// Use this for hand-written API calls (e.g. the sell-car repository).
  static Dio get dio => _dio ??= _build();

  static Dio _build() {
    final options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      // Photo uploads can take a while on mobile networks.
      sendTimeout: const Duration(minutes: 3),
      // No fixed Content-Type here: Dio picks JSON for maps and the correct multipart boundary
      // for FormData.
    );
    final dio = Dio(options);

    dio.interceptors.add(AuthInterceptor(options));

    if (kDebugMode) {
      // Never log headers/bodies: they contain the Authorization token and phone numbers.
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }
    return dio;
  }

  /// Retrofit-generated API (login, categories, addresses, ...) running on the shared client.
  static RepositoryApi create() => RepositoryApi(dio);
}
