import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../config/app_config.dart';
import '../models/models.dart';

BaseOptions _options() => BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    );

/// Client for public endpoints (health, pairing, refresh). No auth header.
final publicDioProvider = Provider<Dio>((ref) {
  final dio = Dio(_options());
  ref.onDispose(dio.close);
  return dio;
});

/// Client for the user's API. Adds the access token; on a 401 it refreshes once (requests that
/// fail meanwhile wait in the queue) and retries. If refreshing fails, the user is signed out.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_options());
  dio.interceptors.add(_AuthInterceptor(ref, dio));
  ref.onDispose(dio.close);
  return dio;
});

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor(this.ref, this.dio);

  final Ref ref;
  final Dio dio;

  TokenStore get _tokens => ref.read(tokenStoreProvider);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokens.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    if (err.response?.statusCode != 401 || req.extra['retried'] == true) return handler.next(err);

    // Another queued request may already have refreshed: retry with the new token first.
    final sent = req.headers['Authorization'];
    final current = _tokens.accessToken;
    if (current != null && sent != 'Bearer $current') return _retry(req, current, handler, err);

    final refresh = _tokens.refreshToken;
    if (refresh == null) return _signOut(handler, err);
    try {
      final res = await ref.read(publicDioProvider).post<Json>('/v1/auth/refresh', data: {'refreshToken': refresh});
      final tokens = AuthTokens.fromJson(res.data!);
      await _tokens.save(tokens);
      return await _retry(req, tokens.accessToken, handler, err);
    } on DioException catch (e) {
      // Only a definite "no" from the server ends the session; offline keeps the user signed in.
      if (e.response?.statusCode == 401) return _signOut(handler, err);
      return handler.next(err);
    }
  }

  Future<void> _retry(RequestOptions req, String token, ErrorInterceptorHandler handler, DioException original) async {
    try {
      req.headers['Authorization'] = 'Bearer $token';
      req.extra['retried'] = true;
      handler.resolve(await dio.fetch<dynamic>(req));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<void> _signOut(ErrorInterceptorHandler handler, DioException err) async {
    await ref.read(sessionProvider.notifier).signedOut();
    handler.next(err);
  }
}

/// A failed API call, with a short machine-readable code from the server (`error`).
class ApiException implements Exception {
  const ApiException(this.code, {this.status, this.message});

  factory ApiException.from(DioException e) {
    final data = e.response?.data;
    final code = data is Map ? (data['error'] as String? ?? 'error') : _networkCode(e);
    return ApiException(code, status: e.response?.statusCode, message: data is Map ? data['message'] as String? : null);
  }

  static String _networkCode(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout || DioExceptionType.sendTimeout => 'timeout',
        DioExceptionType.connectionError => 'offline',
        _ => 'error',
      };

  final String code;
  final int? status;
  final String? message;

  bool get isNetwork => code == 'offline' || code == 'timeout';

  @override
  String toString() => 'ApiException($code, $status${message == null ? '' : ', $message'})';
}

/// `true` when the backend answers `/health/ready`. Shown on the More screen.
final serverHealthProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    final res = await ref.watch(publicDioProvider).get<Json>('/health/ready');
    return res.statusCode == 200 && res.data?['status'] == 'ok';
  } on DioException {
    return false;
  }
});
