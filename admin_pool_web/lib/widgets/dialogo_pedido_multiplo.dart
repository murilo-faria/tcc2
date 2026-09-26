import 'package:flutter/material.dart';

import '../core/formatadores.dart';

/// Formulário reutilizado para pedidos de cliente ou material de uso interno.
Future<Map<String, dynamic>?> mostrarDialogPedidoMultiplo({
  required BuildContext context,
  required List<dynamic> produtos,
  required List<dynamic> clientes,
  required List<dynamic> piscinas,
  List<dynamic> funcionarios = const [],
  int? clienteFixo,
  int? piscinaFixa,
  int? funcionarioFixo,
  bool? usoInternoInicial,
  bool permitirCapa = false,
  bool capaInicial = false,
  num? custoMetroQuadradoInicial,
  num? freteInicial,
  num? lucroInicial,
  int? espessuraMicrasInicial,
  List<Map<String, int>>? itensIniciais,
  required String titulo,
}) async {
  final clientesOrdenados = [...clientes]
    ..sort((a, b) => (a['nome'] ?? '').toString().toLowerCase().compareTo((b['nome'] ?? '').toString().toLowerCase()));
  int clienteId = clienteFixo ?? clientesOrdenados.first['id'] as int;
  bool usoInterno = usoInternoInicial ?? false;
  bool capaSobMedida = capaInicial;
  int? funcionarioId = funcionarioFixo ?? (funcionarios.isEmpty ? null : funcionarios.first['id'] as int);
  int? piscinaId = piscinaFixa ?? (piscinas.where((p) => p['cliente']['id'] == clienteId).length == 1
      ? piscinas.firstWhere((p) => p['cliente']['id'] == clienteId)['id'] as int : null);
  final itens = itensIniciais == null
      ? <Map<String, int>>[{'produtoId': produtos.first['id'] as int, 'quantidade': 1}]
      : itensIniciais.map((item) => Map<String, int>.from(item)).toList();
  final custoMetroQuadrado = TextEditingController(text: custoMetroQuadradoInicial?.toString() ?? '');
  final frete = TextEditingController(text: freteInicial?.toString() ?? '');
  final lucro = TextEditingController(text: lucroInicial?.toString() ?? '');
  int espessuraMicras = espessuraMicrasInicial ?? 300;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) {
        num total = 0;
        for (final item in itens) {
          final produto = produtos.firstWhere((p) => p['id'] == item['produtoId']);
          total += ((usoInterno ? produto['precoCompra'] : produto['precoVenda']) as num? ?? 0) * item['quantidade']!;
        }
        final celular = MediaQuery.of(context).size.width < 600;
        final piscinaSelecionada = piscinaId == null ? null : piscinas.firstWhere(
          (p) => p['id'] == piscinaId,
          orElse: () => <String, dynamic>{},
        );
        final comprimento = (piscinaSelecionada?['comprimento'] as num?) ?? 0;
        final largura = (piscinaSelecionada?['largura'] as num?) ?? 0;
        final area = comprimento * largura;
        final custoM2 = double.tryParse(custoMetroQuadrado.text.replaceAll(',', '.')) ?? 0;
        final valorFrete = double.tryParse(frete.text.replaceAll(',', '.')) ?? 0;
        final valorLucro = double.tryParse(lucro.text.replaceAll(',', '.')) ?? 0;
        final valorCapa = area * custoM2;
        final totalCapa = valorCapa + valorFrete + valorLucro;
        return AlertDialog(
          insetPadding: EdgeInsets.all(celular ? 16 : 24),
          title: Text(titulo),
          content: SizedBox(
            width: celular ? double.maxFinite : 650,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (clienteFixo == null && usoInternoInicial == null && (funcionarios.isNotEmpty || permitirCapa)) ...[
                  SegmentedButton<String>(
                    segments: [
                      const ButtonSegment(value: 'CLIENTE', icon: Icon(Icons.person_outline), label: Text('Para cliente')),
                      if (funcionarios.isNotEmpty)
                        const ButtonSegment(value: 'INTERNO', icon: Icon(Icons.inventory_2_outlined), label: Text('Uso interno')),
                      if (permitirCapa)
                        const ButtonSegment(value: 'CAPA', icon: Icon(Icons.pool_outlined), label: Text('Capa sob medida')),
                    ],
                    selected: {capaSobMedida ? 'CAPA' : usoInterno ? 'INTERNO' : 'CLIENTE'},
                    onSelectionChanged: (v) => setLocal(() {
                      usoInterno = v.first == 'INTERNO';
                      capaSobMedida = v.first == 'CAPA';
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
                if (usoInterno && funcionarioFixo == null)
                  DropdownButtonFormField<int>(
                    initialValue: funcionarioId,
                    decoration: const InputDecoration(
                      labelText: 'Colaborador que receberá o material *',
                      helperText: 'Não gera cobrança para cliente.',
                    ),
                    items: funcionarios.map<DropdownMenuItem<int>>((f) => DropdownMenuItem(
                      value: f['id'] as int, child: Text((f['usuario'] ?? {})['nome']?.toString() ?? ''),
                    )).toList(),
                    onChanged: (v) => setLocal(() => funcionarioId = v),
                  )
                else if (usoInterno) ...[
                  const ListTile(
                    leading: Icon(Icons.inventory_2_outlined),
                    title: Text('Material para o mesmo colaborador solicitante'),
                  ),
                ] else ...[
                  if (clienteFixo == null)
                    DropdownButtonFormField<int>(
                      initialValue: clienteId,
                      decoration: const InputDecoration(labelText: 'Cliente'),
                      items: clientesOrdenados.map<DropdownMenuItem<int>>((cliente) => DropdownMenuItem(
                        value: cliente['id'] as int, child: Text(cliente['nome']),
                      )).toList(),
                      onChanged: (v) => setLocal(() {
                        clienteId = v!;
                        final disponiveis = piscinas.where((p) => p['cliente']['id'] == clienteId).toList();
                        piscinaId = disponiveis.length == 1 ? disponiveis.first['id'] as int : null;
                      }),
                    ),
                  DropdownButtonFormField<int>(
                    key: ValueKey('piscina-$clienteId'), initialValue: piscinaId,
                    decoration: const InputDecoration(labelText: 'Piscina *'),
                    items: piscinas.where((p) => p['cliente']['id'] == clienteId).map<DropdownMenuItem<int>>(
                      (p) => DropdownMenuItem(value: p['id'] as int, child: Text('${p['nome']} — ${p['endereco'] ?? ''}')),
                    ).toList(),
                    onChanged: (v) => setLocal(() => piscinaId = v),
                  ),
                  if (piscinaId != null) Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(padding: const EdgeInsets.only(top: 8), child: Text(
                      'Endereço: ${(piscinas.firstWhere((p) => p['id'] == piscinaId)['endereco'] ?? 'A informar')}',
                    )),
                  ),
                ],
                const SizedBox(height: 8),
                if (capaSobMedida) ...[
                  if (piscinaId != null && area <= 0)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Informe comprimento e largura na piscina antes de gerar a capa.', style: TextStyle(color: Colors.red)),
                    )
                  else if (piscinaId != null) ...[
                    Align(alignment: Alignment.centerLeft, child: Text('Área da piscina: ${area.toStringAsFixed(2).replaceAll('.', ',')} m²', style: const TextStyle(fontWeight: FontWeight.w600))),
                    const SizedBox(height: 8),
                    TextField(controller: custoMetroQuadrado, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setLocal(() {}), decoration: const InputDecoration(labelText: 'Custo por m²', prefixText: 'R\$ ')),
                    DropdownButtonFormField<int>(
                      initialValue: espessuraMicras,
                      decoration: const InputDecoration(labelText: 'Tipo da capa'),
                      items: const [
                        DropdownMenuItem(value: 300, child: Text('Capa 300 micras')),
                        DropdownMenuItem(value: 500, child: Text('Capa 500 micras')),
                      ],
                      onChanged: (valor) => setLocal(() => espessuraMicras = valor ?? 300),
                    ),
                    TextField(controller: frete, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setLocal(() {}), decoration: const InputDecoration(labelText: 'Frete', prefixText: 'R\$ ')),
                    TextField(controller: lucro, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setLocal(() {}), decoration: const InputDecoration(labelText: 'Lucro desejado', prefixText: 'R\$ ')),
                    const Divider(),
                    _ResumoCapa(linha: 'Valor da capa', valor: valorCapa),
                    _ResumoCapa(linha: 'Frete', valor: valorFrete),
                    _ResumoCapa(linha: 'Lucro', valor: valorLucro),
                  ],
                ] else ...[
                ...List.generate(itens.length, (indice) {
                  final item = itens[indice];
                  final produtoCampo = DropdownButtonFormField<int>(
                    initialValue: item['produtoId'], isExpanded: true,
                    decoration: InputDecoration(labelText: 'Produto ${indice + 1}'),
                    items: produtos.map<DropdownMenuItem<int>>((produto) => DropdownMenuItem(
                      value: produto['id'] as int,
                      child: Text('${produto['nome']} — ${formatarMoeda((usoInterno ? produto['precoCompra'] : produto['precoVenda']) as num? ?? 0)}', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setLocal(() => item['produtoId'] = v!),
                  );
                  final quantidade = SizedBox(width: celular ? double.infinity : 115, child: TextFormField(
                    initialValue: '${item['quantidade']}', keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                    onChanged: (v) => setLocal(() => item['quantidade'] = int.tryParse(v) ?? 1),
                  ));
                  final remover = IconButton(onPressed: itens.length == 1 ? null : () => setLocal(() => itens.removeAt(indice)), icon: const Icon(Icons.remove_circle_outline, color: Colors.red));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: celular ? Column(children: [produtoCampo, const SizedBox(height: 8), Row(children: [Expanded(child: quantidade), remover])])
                        : Row(children: [Expanded(child: produtoCampo), const SizedBox(width: 10), quantidade, remover]),
                  );
                }),
                Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                  onPressed: () => setLocal(() => itens.add({'produtoId': produtos.first['id'] as int, 'quantidade': 1})),
                  icon: const Icon(Icons.add), label: const Text('Adicionar outro produto'),
                )),
                ],
                const Divider(),
                Align(alignment: Alignment.centerRight, child: Text(
                  '${capaSobMedida ? 'Valor final da capa' : usoInterno ? 'Custo estimado' : 'Total do pedido'}: ${formatarMoeda(capaSobMedida ? totalCapa : total)}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                )),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: (usoInterno && funcionarioId == null) || (!usoInterno && piscinaId == null) || (capaSobMedida && area <= 0) ? null : () => Navigator.pop(context, {
                if (usoInterno) 'funcionarioId': funcionarioId else ...{'clienteId': clienteId, 'piscinaId': piscinaId},
                if (capaSobMedida) ...{
                  'tipo': 'CAPA',
                  'custoMetroQuadrado': custoM2,
                  'frete': valorFrete,
                  'lucro': valorLucro,
                  'espessuraMicras': espessuraMicras,
                } else 'itens': itens,
              }),
              child: Text(capaSobMedida ? 'Gerar pedido de capa' : 'Salvar pedido'),
            ),
          ],
        );
      },
    ),
  );
}

class _ResumoCapa extends StatelessWidget {
  const _ResumoCapa({required this.linha, required this.valor});
  final String linha;
  final num valor;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [Text(linha), const Spacer(), Text(formatarMoeda(valor))]),
  );
}
