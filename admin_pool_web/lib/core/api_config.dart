/// Endereço único da API Java.
///
/// Se a porta da API mudar, altere somente este arquivo.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tcc2-production.up.railway.app',
  );

  static Uri uri(String caminho) => Uri.parse('$baseUrl$caminho');
}
