part of '../main.dart';

class _PedidosPageNova extends StatefulWidget {
  const _PedidosPageNova({required this.gestor});
  final bool gestor;

  @override
  State<_PedidosPageNova> createState() => _PedidosPageNovaState();
}

class _PedidosPageNovaState extends State<_PedidosPageNova> {
  late Future<List<dynamic>> _pedidos;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _pedidos = _carregar();
  }

  Future<List<dynamic>> _lista(String rota) async {
    final resposta = await apiService.get(rota);
    if (resposta.statusCode != 200)
      throw Exception('Não foi possível carregar os dados.');
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  Future<List<dynamic>> _carregar() => _lista('/api/pedidos-produto');

  void _recarregar() {
    atualizacaoOperacional.value++;
    atualizacaoFinanceira.value++;
    setState(() => _pedidos = _carregar());
  }

  Future<void> _novoPedido() async {
    final resultados = await Future.wait([
      _lista('/api/clientes'),
      _lista('/api/produtos'),
      _lista('/api/piscinas'),
    ]);
    if (!mounted || resultados[0].isEmpty || resultados[1].isEmpty) return;
    final pedido = await mostrarDialogPedidoMultiplo(
      context: context,
      clientes: resultados[0],
      produtos: resultados[1],
      piscinas: resultados[2],
      titulo: 'Novo pedido de produtos',
    );
    if (pedido == null) return;
    final resposta = await apiService.post(
      '/api/pedidos-produto/lote',
      body: pedido,
    );
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) _recarregar();
  }

  Future<void> _concluir(int codigo) async {
    String pagador = 'EMPRESA';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (_, setLocal) => AlertDialog(
          title: Text('Concluir Pedido #$codigo'),
          content: SizedBox(
            width: 470,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'EMPRESA',
                  groupValue: pagador,
                  title: const Text('Pago pela empresa'),
                  subtitle: const Text(
                    'Entra na cobrança do cliente e no resultado de produtos.',
                  ),
                  onChanged: (v) => setLocal(() => pagador = v!),
                ),
                RadioListTile<String>(
                  value: 'CLIENTE',
                  groupValue: pagador,
                  title: const Text('Pago pelo cliente'),
                  subtitle: const Text(
                    'Conclui sem cobrança e sem lucro para a empresa.',
                  ),
                  onChanged: (v) => setLocal(() => pagador = v!),
                ),
                const Divider(),
                const Text(
                  'Confira a opção antes de confirmar. Esta conclusão gera o lançamento financeiro quando aplicável.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirmar conclusão'),
            ),
          ],
        ),
      ),
    );
    if (confirmar != true) return;
    final resposta = await apiService.put(
      '/api/pedidos-produto/codigo/$codigo/concluir',
      body: {'pagoPor': pagador},
    );
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      _recarregar();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pedido concluído.')));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível concluir o pedido.')),
      );
    }
  }

  Future<void> _reabrir(int codigo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desfazer conclusão do Pedido #$codigo?'),
        content: const Text(
          'O pedido voltará para solicitado e a cobrança vinculada será removida. Isso só é permitido se o cliente ainda não tiver pago esse pedido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.undo),
            label: const Text('Desfazer conclusão'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final resposta = await apiService.put(
      '/api/pedidos-produto/codigo/$codigo/reabrir',
    );
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      _recarregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido reaberto e cobrança removida.')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível desfazer: o pedido pode já ter pagamento recebido.',
          ),
        ),
      );
    }
  }

  Future<void> _detalhar(int codigo) async {
    final itens = await _lista('/api/pedidos-produto/codigo/$codigo');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pedido #$codigo'),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: itens.map((linha) {
                final produto = linha['produto'] ?? {};
                return ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(produto['nome'] ?? ''),
                  subtitle: Text(
                    '${linha['quantidade']} unidade(s) • venda ${formatarMoeda((linha['valorUnitario'] as num?) ?? 0)}',
                  ),
                  trailing: Text(
                    formatarMoeda((linha['totalVenda'] as num?) ?? 0),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Map<int, List<Map<String, dynamic>>> _agrupar(List<dynamic> linhas) {
    final grupos = <int, List<Map<String, dynamic>>>{};
    for (final linha in linhas.cast<Map<String, dynamic>>()) {
      final codigo = (linha['codigoPedido'] ?? linha['id']) as int;
      grupos.putIfAbsent(codigo, () => []).add(linha);
    }
    return grupos;
  }

  String _nomeStatus(String status) =>
      const {
        'SOLICITADO': 'Solicitado',
        'PEDIDO_REALIZADO': 'Pedido realizado',
        'AGUARDANDO_ENTREGA': 'Aguardando entrega',
        'ENTREGUE': 'Entregue',
        'CONCLUIDO': 'Concluído',
      }[status] ??
      status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width < 600 ? 16 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CabecalhoResponsivo(
            titulo: 'Pedidos de produtos',
            subtitulo: 'Pedidos por encomenda, sem controle de estoque.',
            acao: FilledButton.icon(
              onPressed: _novoPedido,
              icon: const Icon(Icons.add),
              label: const Text('Novo pedido'),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Pesquisar cliente ou produto',
              border: OutlineInputBorder(),
            ),
            onChanged: (valor) =>
                setState(() => _filtro = valor.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _pedidos,
              builder: (_, estado) {
                if (!estado.hasData)
                  return const Center(child: CircularProgressIndicator());
                if (estado.hasError)
                  return Center(child: Text('${estado.error}'));
                final grupos = _agrupar(estado.data!).entries.where((grupo) {
                  final cliente = (grupo.value.first['cliente'] ?? {})['nome']
                      .toString()
                      .toLowerCase();
                  final produtos = grupo.value
                      .map(
                        (item) => (item['produto'] ?? {})['nome']
                            .toString()
                            .toLowerCase(),
                      )
                      .join(' ');
                  return cliente.contains(_filtro) ||
                      produtos.contains(_filtro);
                }).toList();
                if (grupos.isEmpty)
                  return const Center(child: Text('Nenhum pedido cadastrado.'));
                return Card(
                  child: ListView.separated(
                    itemCount: grupos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, indice) {
                      final grupo = grupos[indice];
                      final primeiro = grupo.value.first;
                      final concluido = primeiro['status'] == 'CONCLUIDO';
                      final total = grupo.value.fold<double>(
                        0,
                        (soma, item) =>
                            soma +
                            ((item['totalVenda'] as num?) ?? 0).toDouble(),
                      );
                      return ListTile(
                        onTap: () => _detalhar(grupo.key),
                        leading: CircleAvatar(child: Text('#${grupo.key}')),
                        title: Text(primeiro['cliente']['nome']),
                        subtitle: Text(
                          '${grupo.value.length} produto(s) • ${_nomeStatus(primeiro['status'])} • ${primeiro['dataPedido']}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatarMoeda(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Ver produtos',
                              onPressed: () => _detalhar(grupo.key),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            if (widget.gestor)
                              IconButton(
                                tooltip: concluido
                                    ? 'Desfazer conclusão'
                                    : 'Concluir pedido',
                                onPressed: () => concluido
                                    ? _reabrir(grupo.key)
                                    : _concluir(grupo.key),
                                icon: Icon(
                                  concluido
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: concluido
                                      ? Colors.green
                                      : Colors.grey.shade600,
                                ),
                              ),
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

class _ResultadoProdutosCard extends StatelessWidget {
  const _ResultadoProdutosCard();

  Future<Map<String, dynamic>> _carregar() async {
    final resposta = await apiService.get('/api/pedidos-produto/resultado');
    if (resposta.statusCode != 200) throw Exception('Resultado indisponível');
    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }

  Future<void> _detalhar(BuildContext context) async {
    final resposta = await apiService.get('/api/pedidos-produto');
    if (resposta.statusCode != 200 || !context.mounted) return;
    final pedidos = (jsonDecode(resposta.body) as List<dynamic>)
        .where(
          (item) =>
              item['pagador'] == 'EMPRESA' &&
              (item['dataConclusao'] ?? '').toString().startsWith(
                referenciaAtual,
              ),
        )
        .toList();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Produtos vendidos no mês'),
        content: SizedBox(
          width: 600,
          height: 420,
          child: pedidos.isEmpty
              ? const Center(child: Text('Nenhum produto vendido neste mês.'))
              : ListView.separated(
                  itemCount: pedidos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, indice) {
                    final pedido = pedidos[indice];
                    final lucro =
                        ((pedido['totalVenda'] as num?) ?? 0) -
                        ((pedido['totalCompra'] as num?) ?? 0);
                    return ListTile(
                      leading: const Icon(Icons.shopping_bag_outlined),
                      title: Text((pedido['produto'] ?? {})['nome'] ?? ''),
                      subtitle: Text(
                        'Pedido #${pedido['codigoPedido']} • ${(pedido['cliente'] ?? {})['nome']}',
                      ),
                      trailing: Text(
                        '+ ${formatarMoeda(lucro)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: atualizacaoFinanceira,
    builder: (_, __, ___) => FutureBuilder<Map<String, dynamic>>(
      future: _carregar(),
      builder: (_, estado) {
        final dados = estado.data ?? const <String, dynamic>{};
        return SizedBox(
          width: 476,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _detalhar(context),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.teal),
                        SizedBox(width: 10),
                        Text(
                          'Resultado de produtos do mês',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 22,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Compras: ${formatarMoeda((dados['totalCompras'] as num?) ?? 0)}',
                        ),
                        Text(
                          'Vendas: ${formatarMoeda((dados['totalVendas'] as num?) ?? 0)}',
                        ),
                        Text(
                          'Lucro: ${formatarMoeda((dados['lucroBruto'] as num?) ?? 0)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Margem: ${((dados['margemPercentual'] as num?) ?? 0).toStringAsFixed(2)}%',
                        ),
                        Text(
                          'A receber: ${formatarMoeda((dados['totalAReceber'] as num?) ?? 0)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Clique para ver os produtos vendidos.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
