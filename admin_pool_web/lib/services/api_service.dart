import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';

/// Centraliza a comunicação HTTP entre o Flutter e o Spring Boot.
///
/// As telas informam somente a rota, por exemplo `/api/clientes`.
class ApiService {
  String? _authorization;
  DateTime? _expires;
  String? nomeUsuario;
  void logout() {
    _authorization = null;
    _expires = null;
    nomeUsuario = null;
  }

  Map<String, String> get _headers {
    if (_expires != null && DateTime.now().isAfter(_expires!)) logout();
    return {
      'Content-Type': 'application/json',
      'X-Requested-With': 'AdminPool',
      if (_authorization != null) 'Authorization': _authorization!,
    };
  }

  Future<String> login(String usuario, String senha) async {
    logout();
    final authorization =
        'Basic ${base64Encode(utf8.encode('$usuario:$senha'))}';
    final response = await http
        .get(
          ApiConfig.uri('/api/auth/me'),
          headers: {
            'Authorization': authorization,
            'X-Requested-With': 'AdminPool',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Usuário ou senha inválidos.');
    }
    if (response.statusCode != 200)
      throw Exception('Não foi possível acessar o sistema.');
    final dados = jsonDecode(response.body) as Map<String, dynamic>;
    final perfil = dados['perfil'] as String;
    nomeUsuario = dados['nome'] as String? ?? usuario;
    _authorization = authorization;
    _expires = DateTime.now().add(const Duration(hours: 8));
    return perfil;
  }

  Future<http.Response> get(String rota) {
    return http
        .get(ApiConfig.uri(rota), headers: _headers)
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> post(String rota, {Object? body}) {
    return http.post(
      ApiConfig.uri(rota),
      headers: _headers,
      body: body is String ? body : jsonEncode(body),
    );
  }

  Future<http.Response> put(String rota, {Object? body}) {
    return http.put(
      ApiConfig.uri(rota),
      headers: _headers,
      body: body == null ? null : (body is String ? body : jsonEncode(body)),
    );
  }

  Future<http.Response> delete(String rota) {
    return http.delete(ApiConfig.uri(rota), headers: _headers);
  }
}

final apiService = ApiService();
