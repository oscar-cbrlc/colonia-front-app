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

  Future<Map<String, String>> _getHeaders() async {
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
    return headers;
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${Env.apiUrl}$endpoint');
    return await _httpClient.post(
      url,
      headers: await _getHeaders(),
      body: body != null? jsonEncode(body): null,
    );
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$Env.apiUrl$endpoint');
    return await _httpClient.get(
      url,
      headers: await _getHeaders(),
    );
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$Env.apiUrl$endpoint');
    return await _httpClient.patch(
      url,
      headers: await _getHeaders(),
      body: body != null? jsonEncode(body): null,
    );
  }
}