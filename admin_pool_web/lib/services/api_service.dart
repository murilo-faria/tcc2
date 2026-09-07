import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';

/// Centraliza a comunicação HTTP entre o Flutter e o Spring Boot.
///
/// As telas informam somente a rota, por exemplo `/api/clientes`.
class ApiService {
  const ApiService();

  Future<http.Response> get(String rota) {
    return http.get(ApiConfig.uri(rota));
  }

  Future<http.Response> post(String rota, {Object? body}) {
    return http.post(
      ApiConfig.uri(rota),
      headers: const {'Content-Type': 'application/json'},
      body: body is String ? body : jsonEncode(body),
    );
  }

  Future<http.Response> put(String rota, {Object? body}) {
    return http.put(
      ApiConfig.uri(rota),
      headers: const {'Content-Type': 'application/json'},
      body: body == null ? null : (body is String ? body : jsonEncode(body)),
    );
  }

  Future<http.Response> delete(String rota) {
    return http.delete(ApiConfig.uri(rota));
  }
}

const apiService = ApiService();
