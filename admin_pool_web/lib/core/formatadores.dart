/// Converte um número para o formato monetário brasileiro.
String formatarMoeda(num valor) {
  final partes = valor.toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $inteiro,${partes[1]}';
}

/// Exibe datas da API no padrão brasileiro: dd/MM/aaaa.
/// A API continua recebendo e enviando datas técnicas no padrão ISO (AAAA-MM-dd).
String formatarData(dynamic valor) {
  final texto = valor?.toString().trim() ?? '';
  if (texto.isEmpty) return '-';
  final data = DateTime.tryParse(texto);
  if (data == null) return texto;
  return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}

/// Exibe a referência mensal técnica (AAAA-MM) sem inverter ano e mês na tela.
String formatarReferencia(dynamic valor) {
  final texto = valor?.toString().trim() ?? '';
  final partes = texto.split('-');
  if (partes.length != 2 || partes[0].length != 4 || partes[1].length != 2) return texto;
  return '${partes[1]}/${partes[0]}';
}

/// Corrige referências mensais inseridas no texto de descrições antigas.
String formatarDescricaoComReferencia(dynamic valor) => (valor?.toString() ?? '').replaceAllMapped(
  RegExp(r'\b(\d{4})-(\d{2})\b'),
  (encontro) => '${encontro.group(2)}/${encontro.group(1)}',
);

/// Referência do mês atual no padrão usado pela API: AAAA-MM.
String get referenciaAtual {
  final agora = DateTime.now();
  return '${agora.year}-${agora.month.toString().padLeft(2, '0')}';
}
