/// Converte um número para o formato monetário brasileiro.
String formatarMoeda(num valor) {
  final partes = valor.toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $inteiro,${partes[1]}';
}

/// Referência do mês atual no padrão usado pela API: AAAA-MM.
String get referenciaAtual {
  final agora = DateTime.now();
  return '${agora.year}-${agora.month.toString().padLeft(2, '0')}';
}
