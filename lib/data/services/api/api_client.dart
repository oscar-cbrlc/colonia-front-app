import 'dart:convert';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:colonia_front_app/env/env.dart';

class ApiClient {
  final http.Client _httpClient;
  AuthRepository? _authRepository;

  ApiClient({http.Client? httpClient}) : _httpClient  = httpClient ?? http.Client();

  void setAuthRepository(AuthRepository repository) {
    _authRepository = repository;
  }

  Map<String, String> _getHeaders({Map<String, String>? extraHeaders}) {
    final headers = {
      'Content-Type': 'application/json',
      'accept': 'application/json',
      'X_API_Key': Env.apiKey,
    };

    if (_authRepository != null) {
      final token = _authRepository?.cachedToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Future<http.Response> _requestWithRetry(Future<http.Response> Function() request, String endpoint) async {
    final response = await request();

    final bool isAuthAction = endpoint.contains('/session/refresh') || endpoint.contains('/session/logout');

    if (response.statusCode == 401 && _authRepository != null && !isAuthAction) {
      final refreshed = await _authRepository!.refreshSession();
      if (refreshed) {
        return await request();
      } else {
        _authRepository!.logout();
      }
    }

    return response;
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    var url = Uri.parse(Env.apiUrl).resolve(endpoint);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      url = url.replace(queryParameters: queryParameters);
    }

    return await _requestWithRetry(() => _httpClient.post(
      url,
      headers: _getHeaders(extraHeaders: headers),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 10)), endpoint);
  }

  Future<http.Response> get(
      String endpoint, {
        Map<String, String>? queryParameters,
        Map<String, String>? headers,
      }) async {
    var url = Uri.parse(Env.apiUrl).resolve(endpoint);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      url = url.replace(queryParameters: queryParameters);
    }
    return await _requestWithRetry(() => _httpClient.get(
      url,
      headers: _getHeaders(extraHeaders: headers),
    ).timeout(const Duration(seconds: 10)), endpoint);
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    var url = Uri.parse(Env.apiUrl).resolve(endpoint);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      url = url.replace(queryParameters: queryParameters);
    }

    return await _requestWithRetry(() => _httpClient.patch(
      url,
      headers: _getHeaders(extraHeaders: headers),
      body: body != null? jsonEncode(body): null,
    ).timeout(const Duration(seconds: 10)), endpoint);
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    var url = Uri.parse(Env.apiUrl).resolve(endpoint);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      url = url.replace(queryParameters: queryParameters);
    }

    return await _requestWithRetry(() => _httpClient.put(
      url,
      headers: _getHeaders(extraHeaders: headers),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 10)), endpoint);
  }

  Future<http.Response> delete(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final url = Uri.parse(Env.apiUrl).resolve(endpoint);
    return await _requestWithRetry(() => _httpClient.delete(
      url,
      headers: _getHeaders(extraHeaders: headers),
      body: body != null? jsonEncode(body): null,
    ).timeout(const Duration(seconds: 10)), endpoint);
  }
}
