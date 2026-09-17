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
  String? _clienteSelecionado;
  String? _mesSelecionado;
  DateTime? _dataInicial;
  DateTime? _dataFinal;

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

  DateTime? _data(dynamic valor) => DateTime.tryParse(valor?.toString() ?? '');

  String _mes(dynamic valor) {
    final data = _data(valor);
    return data == null
        ? ''
        : '${data.year}-${data.month.toString().padLeft(2, '0')}';
  }

  Future<void> _escolherData(bool inicial) async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: (inicial ? _dataInicial : _dataFinal) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (escolhida != null)
      setState(
        () => inicial ? _dataInicial = escolhida : _dataFinal = escolhida,
      );
  }

  bool _noPeriodo(dynamic valor) {
    final data = _data(valor);
    if (data == null) return false;
    final dia = DateTime(data.year, data.month, data.day);
    if (_mesSelecionado != null && _mes(data) != _mesSelecionado) return false;
    if (_dataInicial != null && dia.isBefore(_dataInicial!)) return false;
    if (_dataFinal != null && dia.isAfter(_dataFinal!)) return false;
    return true;
  }

  List<MapEntry<int, List<Map<String, dynamic>>>> _filtrarGrupos(
    List<dynamic> linhas,
  ) => _agrupar(linhas).entries.where((grupo) {
    final primeiro = grupo.value.first;
    final cliente = (primeiro['cliente'] ?? {})['nome'].toString();
    final produtos = grupo.value
        .map((item) => (item['produto'] ?? {})['nome'].toString().toLowerCase())
        .join(' ');
    return (_clienteSelecionado == null || cliente == _clienteSelecionado) &&
        _noPeriodo(primeiro['dataPedido']) &&
        (cliente.toLowerCase().contains(_filtro) || produtos.contains(_filtro));
  }).toList();

  Future<void> _gerarRelatorio() async {
    final grupos = _filtrarGrupos(await _pedidos);
    if (!mounted) return;
    final total = grupos.fold<double>(
      0,
      (soma, grupo) =>
          soma +
          grupo.value.fold<double>(
            0,
            (subtotal, item) =>
                subtotal + ((item['totalLiquido'] as num?) ?? (item['totalVenda'] as num?) ?? 0).toDouble(),
          ),
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatório de pedidos'),
        content: SizedBox(
          width: 620,
          height: 420,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${grupos.length} pedido(s) • Total: ${formatarMoeda(total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: grupos.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum pedido para os filtros escolhidos.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: grupos.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) {
                          final grupo = grupos[i];
                          final primeiro = grupo.value.first;
                          final valor = grupo.value.fold<double>(
                            0,
                            (soma, item) =>
                                soma +
                                ((item['totalLiquido'] as num?) ?? (item['totalVenda'] as num?) ?? 0).toDouble(),
                          );
                          return ListTile(
                            title: Text(
                              'Pedido #${grupo.key} — ${(primeiro['cliente'] ?? {})['nome'] ?? ''}',
                            ),
                            subtitle: Text(
                              '${primeiro['dataPedido']} • ${grupo.value.length} produto(s)',
                            ),
                            trailing: Text(formatarMoeda(valor)),
                          );
                        },
                      ),
              ),
            ],
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

  Future<void> _alterarStatus(int codigo, String atual) async {
    const opcoes = [
      'SOLICITADO',
      'PEDIDO_REALIZADO',
      'AGUARDANDO_ENTREGA',
      'ENTREGUE',
    ];
    String escolhido = opcoes.contains(atual) ? atual : opcoes.first;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (_, setLocal) => AlertDialog(
          title: Text('Atualizar Pedido #$codigo'),
          content: DropdownButtonFormField<String>(
            initialValue: escolhido,
            decoration: const InputDecoration(labelText: 'Situação'),
            items: opcoes
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(_nomeStatus(status)),
                  ),
                )
                .toList(),
            onChanged: (status) => setLocal(() => escolhido = status!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (confirmar != true) return;
    final resposta = await apiService.put(
      '/api/pedidos-produto/codigo/$codigo/status?status=$escolhido',
    );
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) _recarregar();
  }

  Future<void> _concluir(int codigo) async {
    String pagador = 'EMPRESA';
    final desconto = TextEditingController();
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
                  title: const Text('Pago pelo cliente na Beluga'),
                  subtitle: const Text(
                    'Conclui sem cobrança e sem lucro para a empresa.',
                  ),
                  onChanged: (v) => setLocal(() => pagador = v!),
                ),
                TextField(
                  controller: desconto,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Desconto do pedido',
                    prefixText: 'R\$ ',
                    helperText: 'Opcional. Será abatido antes de gerar a cobrança.',
                  ),
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
      body: {
        'pagoPor': pagador,
        'desconto': double.tryParse(desconto.text.replaceAll(',', '.')) ?? 0,
      },
    );
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) _recarregar();
  }

  Future<void> _excluir(int codigo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Pedido #$codigo?'),
        content: const Text('O pedido será removido definitivamente. Se estiver concluído, a cobrança vinculada também será desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true) return;
    final resposta = await apiService.delete('/api/pedidos-produto/codigo/$codigo');
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) _recarregar();
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
                    '${linha['quantidade']} unidade(s) • venda ${formatarMoeda((linha['valorUnitario'] as num?) ?? 0)}${((linha['desconto'] as num?) ?? 0) > 0 ? ' • desconto ${formatarMoeda(linha['desconto'] as num)}' : ''}',
                  ),
                  trailing: Text(
                    formatarMoeda((linha['totalLiquido'] as num?) ?? (linha['totalVenda'] as num?) ?? 0),
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
        'PEDIDO_REALIZADO': 'Pedido realizado na Beluga',
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
            acao: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _gerarRelatorio,
                  icon: const Icon(Icons.summarize_outlined),
                  label: const Text('Gerar relatório'),
                ),
                FilledButton.icon(
                  onPressed: _novoPedido,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo pedido'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Pesquisar cliente ou produto',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(),
            ),
            onChanged: (valor) =>
                setState(() => _filtro = valor.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: _pedidos,
            builder: (_, estado) {
              if (!estado.hasData) return const SizedBox.shrink();
              final grupos = _agrupar(estado.data!);
              final clientes =
                  grupos.values
                      .map(
                        (grupo) =>
                            (grupo.first['cliente'] ?? {})['nome'].toString(),
                      )
                      .toSet()
                      .toList()
                    ..sort();
              final meses =
                  grupos.values
                      .map((grupo) => _mes(grupo.first['dataPedido']))
                      .where((mes) => mes.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
              return _FiltrosRelatorio(
                clientes: clientes,
                meses: meses,
                clienteSelecionado: _clienteSelecionado,
                mesSelecionado: _mesSelecionado,
                dataInicial: _dataInicial,
                dataFinal: _dataFinal,
                aoMudarCliente: (v) => setState(() => _clienteSelecionado = v),
                aoMudarMes: (v) => setState(() => _mesSelecionado = v),
                aoEscolherData: _escolherData,
                aoLimpar: () => setState(() {
                  _clienteSelecionado = null;
                  _mesSelecionado = null;
                  _dataInicial = null;
                  _dataFinal = null;
                }),
              );
            },
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
                final grupos = _filtrarGrupos(estado.data!);
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
                            ((item['totalLiquido'] as num?) ?? (item['totalVenda'] as num?) ?? 0).toDouble(),
                      );
                      final compacto = MediaQuery.of(context).size.width < 600;
                      return ListTile(
                        onTap: () => _detalhar(grupo.key),
                        leading: CircleAvatar(child: Text('#${grupo.key}')),
                        title: Text(
                          primeiro['cliente']['nome'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${grupo.value.length} produto(s) • ${_nomeStatus(primeiro['status'])} • ${primeiro['dataPedido']}',
                        ),
                        trailing: compacto
                            ? Text(formatarMoeda(total), style: const TextStyle(fontWeight: FontWeight.bold))
                            : Row(
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
                            if (!concluido)
                              IconButton(
                                tooltip: 'Atualizar andamento',
                                onPressed: () => _alterarStatus(
                                  grupo.key,
                                  primeiro['status'],
                                ),
                                icon: const Icon(Icons.local_shipping_outlined),
                              ),
                            if (widget.gestor)
                              IconButton(
                                tooltip: 'Concluir pedido',
                                onPressed: () => _concluir(grupo.key),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                              ),
                            if (widget.gestor && !concluido)
                              IconButton(
                                tooltip: 'Excluir pedido, inclusive concluído',
                                onPressed: () => _excluir(grupo.key),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                        ((pedido['totalLiquido'] as num?) ?? (pedido['totalVenda'] as num?) ?? 0) -
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
