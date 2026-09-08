import 'package:flutter/material.dart';

import '../core/formatadores.dart';

/// Abre o formulário reutilizado para pedidos com um ou mais produtos.
Future<Map<String, dynamic>?> mostrarDialogPedidoMultiplo({
  required BuildContext context,
  required List<dynamic> produtos,
  required List<dynamic> clientes,
  required List<dynamic> piscinas,
  int? clienteFixo,
  required String titulo,
}) async {
  int clienteId = clienteFixo ?? clientes.first['id'] as int;
  int? piscinaId = piscinas.where((p) => p['cliente']['id'] == clienteId).length == 1
      ? piscinas.firstWhere((p) => p['cliente']['id'] == clienteId)['id'] as int
      : null;
  final itens = <Map<String, int>>[
    {'produtoId': produtos.first['id'] as int, 'quantidade': 1},
  ];

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) {
        num total = 0;
        for (final item in itens) {
          final produto = produtos.firstWhere(
            (p) => p['id'] == item['produtoId'],
          );
          total += (produto['precoVenda'] as num) * item['quantidade']!;
        }

        return AlertDialog(
          title: Text(titulo),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (clienteFixo == null)
                    DropdownButtonFormField<int>(
                      initialValue: clienteId,
                      decoration: const InputDecoration(labelText: 'Cliente'),
                      items: clientes
                          .map<DropdownMenuItem<int>>(
                            (cliente) => DropdownMenuItem(
                              value: cliente['id'] as int,
                              child: Text(cliente['nome']),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        setLocal(() {
                          clienteId = valor!;
                          final disponiveis = piscinas.where((p) => p['cliente']['id'] == clienteId).toList();
                          piscinaId = disponiveis.length == 1 ? disponiveis.first['id'] as int : null;
                        });
                      },
                    ),
                  DropdownButtonFormField<int>(
                    key: ValueKey('piscina-$clienteId'),
                    initialValue: piscinaId,
                    decoration: const InputDecoration(labelText: 'Piscina *'),
                    items: piscinas.where((p) => p['cliente']['id'] == clienteId).map<DropdownMenuItem<int>>(
                      (p) => DropdownMenuItem(value: p['id'] as int, child: Text('${p['nome']} — ${p['endereco'] ?? ''}')),
                    ).toList(),
                    onChanged: (valor) => setLocal(() => piscinaId = valor),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(itens.length, (indice) {
                    final item = itens[indice];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: item['produtoId'],
                              decoration: InputDecoration(
                                labelText: 'Produto ${indice + 1}',
                              ),
                              items: produtos
                                  .map<DropdownMenuItem<int>>(
                                    (produto) => DropdownMenuItem(
                                      value: produto['id'] as int,
                                      child: Text(
                                        '${produto['nome']} — '
                                        '${formatarMoeda(produto['precoVenda'] as num)}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (valor) {
                                setLocal(() => item['produtoId'] = valor!);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 115,
                            child: TextFormField(
                              key: ValueKey(
                                'qtd-$indice-${item['produtoId']}',
                              ),
                              initialValue: '${item['quantidade']}',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantidade',
                              ),
                              onChanged: (valor) {
                                setLocal(() {
                                  item['quantidade'] =
                                      int.tryParse(valor) ?? 1;
                                });
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: itens.length == 1
                                ? null
                                : () => setLocal(
                                    () => itens.removeAt(indice),
                                  ),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setLocal(
                        () => itens.add({
                          'produtoId': produtos.first['id'] as int,
                          'quantidade': 1,
                        }),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar outro produto'),
                    ),
                  ),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total do pedido: ${formatarMoeda(total)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: piscinaId == null ? null : () => Navigator.pop(context, {
                'clienteId': clienteId, 'piscinaId': piscinaId,
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
