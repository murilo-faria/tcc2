import 'package:flutter/foundation.dart';

/// Notificadores simples usados para recarregar apenas a parte alterada da tela.
final ValueNotifier<int> atualizacaoFinanceira = ValueNotifier<int>(0);
final ValueNotifier<int> atualizacaoOperacional = ValueNotifier<int>(0);
final ValueNotifier<int> atualizacaoClientes = ValueNotifier<int>(0);
