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
  required String titulo,
}) async {
  final clientesOrdenados = [...clientes]
    ..sort((a, b) => (a['nome'] ?? '').toString().toLowerCase().compareTo((b['nome'] ?? '').toString().toLowerCase()));
  int clienteId = clienteFixo ?? clientesOrdenados.first['id'] as int;
  bool usoInterno = false;
  int? funcionarioId = funcionarios.isEmpty ? null : funcionarios.first['id'] as int;
  int? piscinaId = piscinas.where((p) => p['cliente']['id'] == clienteId).length == 1
      ? piscinas.firstWhere((p) => p['cliente']['id'] == clienteId)['id'] as int : null;
  final itens = <Map<String, int>>[{'produtoId': produtos.first['id'] as int, 'quantidade': 1}];

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
        return AlertDialog(
          insetPadding: EdgeInsets.all(celular ? 16 : 24),
          title: Text(titulo),
          content: SizedBox(
            width: celular ? double.maxFinite : 650,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (clienteFixo == null && funcionarios.isNotEmpty) ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, icon: Icon(Icons.person_outline), label: Text('Para cliente')),
                      ButtonSegment(value: true, icon: Icon(Icons.inventory_2_outlined), label: Text('Uso interno')),
                    ],
                    selected: {usoInterno},
                    onSelectionChanged: (v) => setLocal(() => usoInterno = v.first),
                  ),
                  const SizedBox(height: 12),
                ],
                if (usoInterno)
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
                else ...[
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
                const Divider(),
                Align(alignment: Alignment.centerRight, child: Text(
                  '${usoInterno ? 'Custo estimado' : 'Total do pedido'}: ${formatarMoeda(total)}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                )),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: (usoInterno && funcionarioId == null) || (!usoInterno && piscinaId == null) ? null : () => Navigator.pop(context, {
                if (usoInterno) 'funcionarioId': funcionarioId else ...{'clienteId': clienteId, 'piscinaId': piscinaId},
                'itens': itens,
              }),
              child: const Text('Salvar pedido'),
            ),
          ],
        );
      },
    ),
  );
}
