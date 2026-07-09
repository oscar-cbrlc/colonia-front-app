import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:colonia_front_app/env/env.dart';

class ApiClient {
  final http.Client _httpClient;
  ApiClient({http.Client? httpClient}) : _httpClient  = httpClient ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'accept': 'application/json',
    'X_API_Key': Env.apiKey,
  };

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${Env.apiUrl}$endpoint');
    return await _httpClient.post(
      url,
      headers: _headers,
      body: body != null? jsonEncode(body): null,
    );
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$Env.apiUrl$endpoint');
    return await _httpClient.get(
      url,
      headers: _headers,
    );
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$Env.apiUrl$endpoint');
    return await _httpClient.patch(
      url,
      headers: _headers,
      body: body != null? jsonEncode(body): null,
    );
  }
}