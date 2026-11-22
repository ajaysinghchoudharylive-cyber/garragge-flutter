import 'package:dio/dio.dart';
import 'package:carsbuzz/network/api_constants.dart';
import 'package:carsbuzz/network/session_events.dart';
import 'package:carsbuzz/network/token_store.dart';

enum _RefreshResult { ok, rejected, unavailable }

/// Dio equivalent of the Android app's AuthInterceptor + UserSessionRefresher.
///
/// - Adds `Authorization: Bearer <jwt>` to every request except the public auth endpoints.
/// - On a 401 for a logged-in user, silently renews the short-lived access token with the
///   long-lived refresh token (the server rotates BOTH tokens), then retries the request once.
/// - Only when the refresh itself is refused (refresh token expired/revoked) is the session
///   cleared and the user sent back to login. A network failure or a 5xx during refresh never
///   logs the user out.
///
/// Guest sessions (Play Integrity) are not implemented in Flutter; the sell-car flow needs a
/// logged-in user anyway.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(BaseOptions baseOptions)
      // Interceptor-free clients, so refreshing/retrying can never loop back into this class
      // (and, because this is a QueuedInterceptor, can never deadlock waiting on its own queue).
      : _refreshDio = Dio(BaseOptions(
          baseUrl: baseOptions.baseUrl,
          connectTimeout: baseOptions.connectTimeout,
          receiveTimeout: baseOptions.receiveTimeout,
          validateStatus: (_) => true,
        )),
        _retryDio = Dio(BaseOptions(
          baseUrl: baseOptions.baseUrl,
          connectTimeout: baseOptions.connectTimeout,
          receiveTimeout: baseOptions.receiveTimeout,
          sendTimeout: baseOptions.sendTimeout,
        ));

  final Dio _refreshDio;
  final Dio _retryDio;

  static const String _retriedKey = 'auth_retried';

  bool _isNoAuth(RequestOptions options) {
    final path = options.uri.path;
    return ApiConstants.noAuthPaths.any(path.startsWith);
  }

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isNoAuth(options)) {
      final token = await TokenStore.getJwt();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        _isNoAuth(request) ||
        request.extra[_retriedKey] == true ||
        !await TokenStore.isLoggedIn()) {
      return handler.next(err);
    }

    // Another request queued ahead of this one may already have renewed the token. In that case
    // just retry with the stored token instead of refreshing (and rotating) a second time.
    final stored = await TokenStore.getJwt();
    final sent = request.headers['Authorization'];
    String? token = stored;
    if (stored == null || stored.isEmpty || sent == 'Bearer $stored') {
      final result = await _refresh();
      if (result == _RefreshResult.rejected) {
        await TokenStore.clearLogin();
        SessionEvents.notifyExpired();
        return handler.next(err);
      }
      if (result == _RefreshResult.unavailable) {
        return handler.next(err);
      }
      token = await TokenStore.getJwt();
    }
    if (token == null || token.isEmpty) return handler.next(err);

    try {
      final data = request.data;
      final retry = request.copyWith(
        headers: {...request.headers, 'Authorization': 'Bearer $token'},
        extra: {...request.extra, _retriedKey: true},
        // A multipart body can only be sent once; send a fresh copy.
        data: data is FormData ? data.clone() : data,
      );
      final response = await _retryDio.fetch<dynamic>(retry);
      handler.resolve(response);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Even a freshly renewed token was refused: the session is dead.
        await TokenStore.clearLogin();
        SessionEvents.notifyExpired();
      }
      handler.next(e);
    }
  }

  Future<_RefreshResult> _refresh() async {
    final refreshToken = await TokenStore.getRefresh();
    if (refreshToken == null || refreshToken.isEmpty) {
      return _RefreshResult.rejected;
    }
    try {
      final response = await _refreshDio.post<dynamic>(
        ApiConstants.loginRefresh,
        data: {'refreshToken': refreshToken},
      );
      final code = response.statusCode ?? 0;
      final body = response.data;
      if (code >= 200 && code < 300 && body is Map) {
        final jwt = body['jwtToken']?.toString();
        if (jwt != null && jwt.isNotEmpty) {
          await TokenStore.saveTokens(jwt, body['refreshToken']?.toString());
          return _RefreshResult.ok;
        }
        return _RefreshResult.rejected;
      }
      // 400/401/403: the refresh token itself is invalid or expired.
      if (code == 400 || code == 401 || code == 403) {
        return _RefreshResult.rejected;
      }
      return _RefreshResult.unavailable; // 5xx etc.
    } on DioException {
      return _RefreshResult.unavailable; // offline / timeout: don't log the user out
    }
  }
}
