import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'repository_api.dart';

class ApiClient {
  ApiClient._();

  static RepositoryApi create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          "Content-Type": "application/json",
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (object) {
          // ignore: avoid_print
          print(object);
        },
      ),
    );

    return RepositoryApi(dio);
  }
}
