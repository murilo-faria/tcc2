part of '../main.dart';

class _CobrancasPageNova extends StatefulWidget {
  const _CobrancasPageNova();

  @override
  State<_CobrancasPageNova> createState() => _CobrancasPageNovaState();
}

class _CobrancasPageNovaState extends State<_CobrancasPageNova> {
  late Future<Map<String, dynamic>> _dados;
  String _busca = '';
  String? _clienteSelecionado;
  String? _mesSelecionado;
  int? _diaVencimentoSelecionado;
  bool _mostrarFiltros = false;
  DateTime? _dataInicial;
  DateTime? _dataFinal;

  @override
  void initState() {
    super.initState();
    _dados = _carregar();
  }

  Future<Map<String, dynamic>> _carregar() async {
    final respostas = await Future.wait([
      apiService.get('/api/cobrancas/clientes'),
      apiService.get('/api/cobrancas/meses'),
      apiService.get('/api/clientes'),
    ]);
    if (respostas[0].statusCode != 200 ||
        respostas[1].statusCode != 200 ||
        respostas[2].statusCode != 200) {
      throw Exception('Não foi possível carregar as cobranças.');
    }
    final meses = jsonDecode(respostas[1].body) as List<dynamic>;
    final cobrancas = await Future.wait(
      meses.map((mes) async {
        final resposta = await apiService.get('/api/cobrancas?referencia=$mes');
        return resposta.statusCode == 200
            ? jsonDecode(resposta.body) as List<dynamic>
            : <dynamic>[];
      }),
    );
    return {
      'resumos': jsonDecode(respostas[0].body) as List<dynamic>,
      'meses': meses,
      'clientesCadastrados': jsonDecode(respostas[2].body) as List<dynamic>,
      'cobrancas': cobrancas.expand((itens) => itens).toList(),
    };
  }

  void _atualizar() {
    atualizacaoFinanceira.value++;
    setState(() => _dados = _carregar());
  }

  DateTime? _data(dynamic valor) => DateTime.tryParse(valor?.toString() ?? '');
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

  bool _noPeriodo(Map<String, dynamic> cobranca) {
    final data = _data(cobranca['vencimento']);
    if (data == null) return false;
    final dia = DateTime(data.year, data.month, data.day);
    return (_mesSelecionado == null ||
            cobranca['referencia'] == _mesSelecionado) &&
        (_diaVencimentoSelecionado == null ||
            data.day == _diaVencimentoSelecionado) &&
        (_dataInicial == null || !dia.isBefore(_dataInicial!)) &&
        (_dataFinal == null || !dia.isAfter(_dataFinal!));
  }

  Future<void> _gerarRelatorio() async {
    final dados = await _dados;
    final cobrancas = (dados['cobrancas'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((c) {
          final cliente = (c['cliente'] ?? {})['nome'].toString();
          return (_clienteSelecionado == null ||
                  cliente == _clienteSelecionado) &&
              _noPeriodo(c) &&
              cliente.toLowerCase().contains(_busca);
        })
        .toList();
    if (!mounted) return;
    final total = cobrancas.fold<double>(
      0,
      (soma, item) => soma + ((item['total'] as num?) ?? 0).toDouble(),
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatório de cobranças'),
        content: SizedBox(
          width: 620,
          height: 420,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${cobrancas.length} cobrança(s) • Total: ${formatarMoeda(total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: cobrancas.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma cobrança para os filtros escolhidos.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: cobrancas.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) {
                          final c = cobrancas[i];
                          return ListTile(
                            title: Text((c['cliente'] ?? {})['nome'] ?? ''),
                            subtitle: Text(
                              '${c['referencia']} • vence ${c['vencimento']} • ${c['status']}',
                            ),
                            trailing: Text(
                              formatarMoeda((c['total'] as num?) ?? 0),
                            ),
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

  Future<void> _baixarRelatorio() async {
    final dados = await _dados;
    final resumos = dados['resumos'] as List<dynamic>;
    final cliente = _clienteSelecionado == null
        ? null
        : resumos
              .firstWhere(
                (c) => c['clienteNome'] == _clienteSelecionado,
              )['clienteId']
              .toString();
    final consulta = consultaPdf({
      'clienteId': cliente,
      'referencia': _mesSelecionado,
      'diaVencimento': _diaVencimentoSelecionado?.toString(),
      'inicio': _dataInicial?.toIso8601String().substring(0, 10),
      'fim': _dataFinal?.toIso8601String().substring(0, 10),
    });
    final resposta = await apiService.get(
      '/api/cobrancas/relatorio.pdf?$consulta',
    );
    if (resposta.statusCode == 200) {
      abrirPdf(resposta, 'relatorio-cobrancas.pdf');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível gerar o relatório (${resposta.statusCode}).',
          ),
        ),
      );
    }
  }

  Future<void> _abrirCliente(Map<String, dynamic> cliente) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _PainelCobrancaCliente(cliente: cliente, aoAtualizar: _atualizar),
    );
  }

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
            titulo: 'Cobranças',
            subtitulo:
                'Abra um cliente para conferir, detalhar e baixar cada valor.',
            acao: OutlinedButton.icon(
              onPressed: _baixarRelatorio,
              icon: const Icon(Icons.summarize_outlined),
              label: const Text('Gerar relatório'),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _mostrarFiltros = !_mostrarFiltros),
              icon: Icon(
                _mostrarFiltros
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              label: Text(
                _mostrarFiltros ? 'Fechar pesquisa' : 'Abrir pesquisa',
              ),
            ),
          ),
          if (_mostrarFiltros) ...[
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: _dados,
              builder: (_, estado) {
                if (!estado.hasData) return const SizedBox.shrink();
                final dias =
                    (estado.data!['clientesCadastrados'] as List<dynamic>)
                        .where((cliente) => cliente['ativo'] != false)
                        .map((cliente) => cliente['diaVencimento'])
                        .whereType<int>()
                        .toSet()
                        .toList()
                      ..sort();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtrar por dia de vencimento',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: _diaVencimentoSelecionado == null,
                          onSelected: (_) =>
                              setState(() => _diaVencimentoSelecionado = null),
                        ),
                        ...dias.map(
                          (dia) => ChoiceChip(
                            label: Text('Dia $dia'),
                            selected: _diaVencimentoSelecionado == dia,
                            onSelected: (_) =>
                                setState(() => _diaVencimentoSelecionado = dia),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Pesquisar cliente',
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) =>
                  setState(() => _busca = valor.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: _dados,
              builder: (_, estado) {
                if (!estado.hasData) return const SizedBox.shrink();
                final resumos = estado.data!['resumos'] as List<dynamic>;
                final clientes =
                    resumos
                        .map((item) => item['clienteNome'].toString())
                        .toList()
                      ..sort();
                final meses =
                    (estado.data!['meses'] as List<dynamic>)
                        .map((item) => item.toString())
                        .toList()
                      ..sort();
                return _FiltrosRelatorio(
                  clientes: clientes,
                  meses: meses,
                  clienteSelecionado: _clienteSelecionado,
                  mesSelecionado: _mesSelecionado,
                  dataInicial: _dataInicial,
                  dataFinal: _dataFinal,
                  aoMudarCliente: (v) =>
                      setState(() => _clienteSelecionado = v),
                  aoMudarMes: (v) => setState(() => _mesSelecionado = v),
                  aoEscolherData: _escolherData,
                  aoLimpar: () => setState(() {
                    _clienteSelecionado = null;
                    _mesSelecionado = null;
                    _diaVencimentoSelecionado = null;
                    _dataInicial = null;
                    _dataFinal = null;
                  }),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dados,
              builder: (context, estado) {
                if (estado.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (estado.hasError)
                  return Center(child: Text('${estado.error}'));
                final cobrancas = (estado.data!['cobrancas'] as List<dynamic>)
                    .cast<Map<String, dynamic>>();
                final filtroPeriodoAtivo =
                    _mesSelecionado != null ||
                    _diaVencimentoSelecionado != null ||
                    _dataInicial != null ||
                    _dataFinal != null;
                final clientes = (estado.data!['resumos'] as List<dynamic>)
                    .cast<Map<String, dynamic>>()
                    .where((item) {
                      final nome = (item['clienteNome'] ?? '').toString();
                      final id = item['clienteId'];
                      return (_clienteSelecionado == null ||
                              nome == _clienteSelecionado) &&
                          nome.toLowerCase().contains(_busca) &&
                          (!filtroPeriodoAtivo ||
                              cobrancas.any(
                                (c) =>
                                    (c['cliente'] ?? {})['id'] == id &&
                                    _noPeriodo(c),
                              ));
                    })
                    .toList();
                if (clientes.isEmpty)
                  return const Center(
                    child: Text('Nenhum cliente encontrado.'),
                  );
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
                          backgroundColor: atrasado
                              ? Colors.red.shade50
                              : Colors.blue.shade50,
                          child: Icon(
                            atrasado
                                ? Icons.warning_amber_rounded
                                : Icons.person_outline,
                            color: atrasado ? Colors.red : Colors.blue,
                          ),
                        ),
                        title: Text(cliente['clienteNome'] ?? ''),
                        subtitle: Text(
                          total == 0
                              ? 'Em dia'
                              : '${cliente['quantidadePendente']} item(ns) ${atrasado ? '• possui atraso' : '• pendente'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatarMoeda(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
  const _PainelCobrancaCliente({
    required this.cliente,
    required this.aoAtualizar,
  });
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
    final resposta = await apiService.get(
      '/api/cobrancas/clientes/$clienteId/itens',
    );
    if (resposta.statusCode != 200)
      throw Exception('Não foi possível carregar os itens.');
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
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(botao),
              ),
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
    final resposta = await apiService.put(
      '/api/cobrancas/itens/${item['id']}/baixar',
      body: {},
    );
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
    final resposta = await apiService.put(
      '/api/cobrancas/itens/baixar',
      body: {'itemIds': _selecionados.toList()},
    );
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
    final resposta = await apiService.put(
      '/api/cobrancas/clientes/$clienteId/baixar-total',
      body: {},
    );
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controlador.text.replaceAll(',', '.')),
            ),
            child: const Text('Confirmar baixa parcial'),
          ),
        ],
      ),
    );
    if (valor == null || valor <= 0) return;
    final resposta = await apiService.put(
      '/api/cobrancas/clientes/$clienteId/baixar-parcial',
      body: {'valor': valor},
    );
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      _recarregar();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confira o valor informado.')),
      );
    }
  }

  Future<void> _abrirDetalhes(Map<String, dynamic> item) async {
    final detalhes = await _carregarDetalhes(item);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['descricao'] ?? 'Detalhes'),
        content: SizedBox(
          width: 520,
          child: _ConteudoDetalheCobranca(item: item, detalhes: detalhes),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<dynamic> _carregarDetalhes(
    Map<String, dynamic> item, [
    int nivel = 0,
  ]) async {
    if (nivel > 6) return null;
    final origemId = item['origemId'];
    if (item['tipo'] == 'PEDIDO' && origemId != null) {
      final resposta = await apiService.get(
        '/api/pedidos-produto/codigo/$origemId',
      );
      if (resposta.statusCode == 200) return jsonDecode(resposta.body);
    } else if (item['tipo'] == 'ORDEM_SERVICO' && origemId != null) {
      final resposta = await apiService.get('/api/ordens-servico/$origemId');
      if (resposta.statusCode == 200) return jsonDecode(resposta.body);
    } else if (item['tipo'] == 'SALDO_ANTERIOR' && origemId != null) {
      final resposta = await apiService.get('/api/cobrancas/itens/$origemId');
      if (resposta.statusCode == 200) {
        return _carregarDetalhes(
          jsonDecode(resposta.body) as Map<String, dynamic>,
          nivel + 1,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final celular = MediaQuery.of(context).size.width < 600;
    return AlertDialog(
      insetPadding: EdgeInsets.all(celular ? 18 : 24),
      title: Text('Valores a receber — ${widget.cliente['clienteNome']}'),
      content: SizedBox(
        width: celular ? double.maxFinite : 780,
        height: celular ? 470 : 520,
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _baixarTotal,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Confirmar pagamento total'),
                ),
                OutlinedButton.icon(
                  onPressed: _baixarParcial,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Baixa parcial'),
                ),
                OutlinedButton.icon(
                  onPressed: _selecionados.isEmpty ? null : _baixarSelecionados,
                  icon: const Icon(Icons.checklist),
                  label: Text('Baixar selecionados (${_selecionados.length})'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _itens,
                builder: (_, estado) {
                  if (!estado.hasData)
                    return const Center(child: CircularProgressIndicator());
                  if (estado.hasError)
                    return Center(child: Text('${estado.error}'));
                  if (estado.data!.isEmpty)
                    return const Center(child: Text('Nenhum valor lançado.'));
                  return ListView.separated(
                    itemCount: estado.data!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, indice) {
                      final item = estado.data![indice] as Map<String, dynamic>;
                      final aberto = _aberto(item);
                      final id = item['id'] as int;
                      final valor = formatarMoeda(
                        (item['saldoPendente'] as num?) ?? 0,
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: celular ? 2 : 16,
                        ),
                        onTap: () => _abrirDetalhes(item),
                        leading: Checkbox(
                          value: _selecionados.contains(id),
                          onChanged: aberto
                              ? (marcado) => setState(
                                  () => marcado == true
                                      ? _selecionados.add(id)
                                      : _selecionados.remove(id),
                                )
                              : null,
                        ),
                        title: Text(
                          item['descricao'] ?? item['tipo'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          celular
                              ? '${item['referencia']} • vence ${item['vencimento']}\n$valor • ${item['atrasado'] == true ? 'ATRASADO' : item['status']}'
                              : '${item['referencia']} • vence ${item['vencimento']} • ${item['atrasado'] == true ? 'ATRASADO' : item['status']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: celular
                            ? (aberto
                                  ? PopupMenuButton<String>(
                                      tooltip: 'Opções da cobrança',
                                      onSelected: (opcao) {
                                        if (opcao == 'confirmar') {
                                          _baixarItem(item);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'confirmar',
                                          child: Text('Confirmar pagamento'),
                                        ),
                                      ],
                                    )
                                  : null)
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    valor,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Ver detalhes',
                                    onPressed: () => _abrirDetalhes(item),
                                    icon: const Icon(Icons.visibility_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Confirmar pagamento',
                                    onPressed: aberto
                                        ? () => _baixarItem(item)
                                        : null,
                                    icon: Icon(
                                      Icons.check_circle_outline,
                                      color: aberto ? Colors.green : null,
                                    ),
                                  ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
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
              subtitle: Text(
                '${linha['quantidade']} unidade(s) × ${formatarMoeda((linha['valorUnitario'] as num?) ?? 0)}',
              ),
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
          Text(
            'Cobrado do cliente: ${formatarMoeda((os['valorCobrado'] as num?) ?? 0)}',
          ),
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
        Text(
          'Valor original: ${formatarMoeda((item['valorOriginal'] as num?) ?? 0)}',
        ),
        Text(
          'Valor recebido: ${formatarMoeda((item['valorPago'] as num?) ?? 0)}',
        ),
        Text('Saldo: ${formatarMoeda((item['saldoPendente'] as num?) ?? 0)}'),
      ],
    );
  }
}
