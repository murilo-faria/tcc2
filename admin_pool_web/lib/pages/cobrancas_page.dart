part of '../main.dart';

class _CobrancasPageNova extends StatefulWidget {
  const _CobrancasPageNova();

  @override
  State<_CobrancasPageNova> createState() => _CobrancasPageNovaState();
}

class _CobrancasPageNovaState extends State<_CobrancasPageNova> {
  late Future<List<dynamic>> _clientes;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _clientes = _carregar();
  }

  Future<List<dynamic>> _carregar() async {
    final resposta = await apiService.get('/api/cobrancas/clientes');
    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível carregar as cobranças.');
    }
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  void _atualizar() {
    atualizacaoFinanceira.value++;
    setState(() => _clientes = _carregar());
  }

  Future<void> _abrirCliente(Map<String, dynamic> cliente) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _PainelCobrancaCliente(
        cliente: cliente,
        aoAtualizar: _atualizar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cobranças', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Abra um cliente para conferir, detalhar e baixar cada valor.'),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Pesquisar cliente',
              border: OutlineInputBorder(),
            ),
            onChanged: (valor) => setState(() => _busca = valor.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _clientes,
              builder: (context, estado) {
                if (estado.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (estado.hasError) return Center(child: Text('${estado.error}'));
                final clientes = estado.data!.where((item) =>
                    (item['clienteNome'] ?? '').toString().toLowerCase().contains(_busca)).toList();
                if (clientes.isEmpty) return const Center(child: Text('Nenhum cliente encontrado.'));
                return Card(
                  child: ListView.separated(
                    itemCount: clientes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, indice) {
                      final cliente = clientes[indice] as Map<String, dynamic>;
                      final total = (cliente['totalPendente'] as num?) ?? 0;
                      final atrasado = cliente['possuiAtraso'] == true;
                      return ListTile(
                        onTap: () => _abrirCliente(cliente),
                        leading: CircleAvatar(
                          backgroundColor: atrasado ? Colors.red.shade50 : Colors.blue.shade50,
                          child: Icon(atrasado ? Icons.warning_amber_rounded : Icons.person_outline,
                              color: atrasado ? Colors.red : Colors.blue),
                        ),
                        title: Text(cliente['clienteNome'] ?? ''),
                        subtitle: Text(total == 0
                            ? 'Em dia'
                            : '${cliente['quantidadePendente']} item(ns) ${atrasado ? '• possui atraso' : '• pendente'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatarMoeda(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PainelCobrancaCliente extends StatefulWidget {
  const _PainelCobrancaCliente({required this.cliente, required this.aoAtualizar});
  final Map<String, dynamic> cliente;
  final VoidCallback aoAtualizar;

  @override
  State<_PainelCobrancaCliente> createState() => _PainelCobrancaClienteState();
}

class _PainelCobrancaClienteState extends State<_PainelCobrancaCliente> {
  late Future<List<dynamic>> _itens;
  final Set<int> _selecionados = {};

  int get clienteId => widget.cliente['clienteId'] as int;

  @override
  void initState() {
    super.initState();
    _itens = _carregar();
  }

  Future<List<dynamic>> _carregar() async {
    final resposta = await apiService.get('/api/cobrancas/clientes/$clienteId/itens');
    if (resposta.statusCode != 200) throw Exception('Não foi possível carregar os itens.');
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  bool _aberto(Map<String, dynamic> item) =>
      item['status'] == 'PENDENTE' || item['status'] == 'PARCIAL';

  void _recarregar() {
    _selecionados.clear();
    widget.aoAtualizar();
    setState(() => _itens = _carregar());
  }

  Future<bool> _confirmar(String titulo, String mensagem, String botao) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(titulo),
            content: Text(mensagem),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(botao)),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _baixarItem(Map<String, dynamic> item) async {
    final saldo = (item['saldoPendente'] as num?) ?? 0;
    final ok = await _confirmar(
      'Confirmar recebimento?',
      'Dar baixa em ${item['descricao']} no valor de ${formatarMoeda(saldo)}?',
      'Confirmar pagamento',
    );
    if (!ok) return;
    final resposta = await apiService.put('/api/cobrancas/itens/${item['id']}/baixar', body: {});
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) _recarregar();
  }

  Future<void> _baixarSelecionados() async {
    if (_selecionados.isEmpty) return;
    final ok = await _confirmar(
      'Confirmar itens selecionados?',
      'Dar baixa em ${_selecionados.length} item(ns) selecionado(s)?',
      'Confirmar recebimento',
    );
    if (!ok) return;
    final resposta = await apiService.put('/api/cobrancas/itens/baixar', body: {
      'itemIds': _selecionados.toList(),
    });
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) _recarregar();
  }

  Future<void> _baixarTotal() async {
    final total = (widget.cliente['totalPendente'] as num?) ?? 0;
    final ok = await _confirmar(
      'Confirmar pagamento total?',
      'Todos os valores pendentes de ${widget.cliente['clienteNome']} serão baixados. Total: ${formatarMoeda(total)}.',
      'Confirmar pagamento total',
    );
    if (!ok) return;
    final resposta = await apiService.put('/api/cobrancas/clientes/$clienteId/baixar-total', body: {});
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) _recarregar();
  }

  Future<void> _baixarParcial() async {
    final controlador = TextEditingController();
    final valor = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dar baixa parcial'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor recebido',
            prefixText: 'R\$ ',
            helperText: 'O saldo restante será levado para o próximo mês.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controlador.text.replaceAll(',', '.'))),
            child: const Text('Confirmar baixa parcial'),
          ),
        ],
      ),
    );
    if (valor == null || valor <= 0) return;
    final resposta = await apiService.put('/api/cobrancas/clientes/$clienteId/baixar-parcial', body: {'valor': valor});
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      _recarregar();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confira o valor informado.')));
    }
  }

  Future<void> _abrirDetalhes(Map<String, dynamic> item) async {
    final detalhes = await _carregarDetalhes(item);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['descricao'] ?? 'Detalhes'),
        content: SizedBox(width: 520, child: _ConteudoDetalheCobranca(item: item, detalhes: detalhes)),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
      ),
    );
  }

  Future<dynamic> _carregarDetalhes(Map<String, dynamic> item, [int nivel = 0]) async {
    if (nivel > 6) return null;
    final origemId = item['origemId'];
    if (item['tipo'] == 'PEDIDO' && origemId != null) {
      final resposta = await apiService.get('/api/pedidos-produto/codigo/$origemId');
      if (resposta.statusCode == 200) return jsonDecode(resposta.body);
    } else if (item['tipo'] == 'ORDEM_SERVICO' && origemId != null) {
      final resposta = await apiService.get('/api/ordens-servico/$origemId');
      if (resposta.statusCode == 200) return jsonDecode(resposta.body);
    } else if (item['tipo'] == 'SALDO_ANTERIOR' && origemId != null) {
      final resposta = await apiService.get('/api/cobrancas/itens/$origemId');
      if (resposta.statusCode == 200) {
        return _carregarDetalhes(jsonDecode(resposta.body) as Map<String, dynamic>, nivel + 1);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Valores a receber — ${widget.cliente['clienteNome']}'),
      content: SizedBox(
        width: 780,
        height: 520,
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(onPressed: _baixarTotal, icon: const Icon(Icons.done_all), label: const Text('Confirmar pagamento total')),
                OutlinedButton.icon(onPressed: _baixarParcial, icon: const Icon(Icons.payments_outlined), label: const Text('Baixa parcial')),
                OutlinedButton.icon(onPressed: _selecionados.isEmpty ? null : _baixarSelecionados, icon: const Icon(Icons.checklist), label: Text('Baixar selecionados (${_selecionados.length})')),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _itens,
                builder: (_, estado) {
                  if (!estado.hasData) return const Center(child: CircularProgressIndicator());
                  if (estado.hasError) return Center(child: Text('${estado.error}'));
                  if (estado.data!.isEmpty) return const Center(child: Text('Nenhum valor lançado.'));
                  return ListView.separated(
                    itemCount: estado.data!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, indice) {
                      final item = estado.data![indice] as Map<String, dynamic>;
                      final aberto = _aberto(item);
                      final id = item['id'] as int;
                      return ListTile(
                        onTap: () => _abrirDetalhes(item),
                        leading: Checkbox(
                          value: _selecionados.contains(id),
                          onChanged: aberto ? (marcado) => setState(() => marcado == true ? _selecionados.add(id) : _selecionados.remove(id)) : null,
                        ),
                        title: Text(item['descricao'] ?? item['tipo'] ?? ''),
                        subtitle: Text('${item['referencia']} • vence ${item['vencimento']} • ${item['atrasado'] == true ? 'ATRASADO' : item['status']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatarMoeda((item['saldoPendente'] as num?) ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(tooltip: 'Ver detalhes', onPressed: () => _abrirDetalhes(item), icon: const Icon(Icons.visibility_outlined)),
                            IconButton(tooltip: 'Confirmar pagamento', onPressed: aberto ? () => _baixarItem(item) : null, icon: Icon(Icons.check_circle_outline, color: aberto ? Colors.green : null)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    );
  }
}

class _ConteudoDetalheCobranca extends StatelessWidget {
  const _ConteudoDetalheCobranca({required this.item, required this.detalhes});
  final Map<String, dynamic> item;
  final dynamic detalhes;

  @override
  Widget build(BuildContext context) {
    if (detalhes is List) {
      final produtos = detalhes as List<dynamic>;
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: produtos.map((linha) {
            final produto = linha['produto'] ?? {};
            return ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: Text(produto['nome'] ?? 'Produto'),
              subtitle: Text('${linha['quantidade']} unidade(s) × ${formatarMoeda((linha['valorUnitario'] as num?) ?? 0)}'),
              trailing: Text(formatarMoeda((linha['totalVenda'] as num?) ?? 0)),
            );
          }).toList(),
        ),
      );
    }
    if (detalhes is Map) {
      final os = detalhes as Map<String, dynamic>;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(os['descricao'] ?? ''),
          const SizedBox(height: 12),
          Text('Data do serviço: ${os['dataServico'] ?? '-'}'),
          Text('Custo: ${formatarMoeda((os['valorCusto'] as num?) ?? 0)}'),
          Text('Cobrado do cliente: ${formatarMoeda((os['valorCobrado'] as num?) ?? 0)}'),
          Text('Pago por: ${os['pagoPor'] ?? '-'}'),
          Text('Situação: ${os['status'] ?? '-'}'),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo: ${item['tipo']}'),
        Text('Lançamento: ${item['dataLancamento']}'),
        Text('Valor original: ${formatarMoeda((item['valorOriginal'] as num?) ?? 0)}'),
        Text('Valor recebido: ${formatarMoeda((item['valorPago'] as num?) ?? 0)}'),
        Text('Saldo: ${formatarMoeda((item['saldoPendente'] as num?) ?? 0)}'),
      ],
    );
  }
}
