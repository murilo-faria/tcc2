/// Endereço único da API Java.
///
/// Se a porta da API mudar, altere somente este arquivo.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );

  static Uri uri(String caminho) => Uri.parse('$baseUrl$caminho');
}
