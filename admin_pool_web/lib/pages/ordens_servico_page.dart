part of '../main.dart';

class _OrdensServicoPageNova extends StatefulWidget {
  const _OrdensServicoPageNova({required this.gestor});
  final bool gestor;

  @override
  State<_OrdensServicoPageNova> createState() => _OrdensServicoPageNovaState();
}

class _OrdensServicoPageNovaState extends State<_OrdensServicoPageNova> {
  late Future<List<dynamic>> _ordens;
  String _filtro = '';
  String? _clienteSelecionado;
  String? _mesSelecionado;
  DateTime? _dataInicial;
  DateTime? _dataFinal;

  @override
  void initState() {
    super.initState();
    _ordens = _carregar();
  }

  Future<List<dynamic>> _buscar(String rota) async {
    final resposta = await apiService.get(rota);
    if (resposta.statusCode != 200)
      throw Exception('Não foi possível carregar os dados.');
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  Future<List<dynamic>> _carregar() => _buscar('/api/ordens-servico');

  void _recarregar() {
    atualizacaoOperacional.value++;
    atualizacaoFinanceira.value++;
    setState(() => _ordens = _carregar());
  }

  DateTime? _data(dynamic valor) => DateTime.tryParse(valor?.toString() ?? '');
  String _mes(dynamic valor) {
    final d = _data(valor);
    return d == null ? '' : '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  Future<void> _escolherData(bool inicial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (inicial ? _dataInicial : _dataFinal) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null)
      setState(() {
        if (inicial) {
          _dataInicial = d;
        } else {
          _dataFinal = d;
        }
      });
  }

  List<dynamic> _filtrarOrdens(List<dynamic> itens) => itens.where((o) {
    final nome = (o['cliente'] ?? {})['nome'].toString();
    final d = _data(o['dataServico']);
    final dia = d == null ? null : DateTime(d.year, d.month, d.day);
    return (_clienteSelecionado == null || nome == _clienteSelecionado) &&
        (_mesSelecionado == null ||
            _mes(o['dataServico']) == _mesSelecionado) &&
        (_dataInicial == null ||
            (dia != null && !dia.isBefore(_dataInicial!))) &&
        (_dataFinal == null || (dia != null && !dia.isAfter(_dataFinal!))) &&
        (nome.toLowerCase().contains(_filtro) ||
            o['descricao'].toString().toLowerCase().contains(_filtro));
  }).toList();
  Future<void> _gerarRelatorio() async {
    final lista = _filtrarOrdens(await _ordens);
    if (!mounted) return;
    final total = lista.fold<double>(
      0,
      (s, o) => s + ((o['valorCobrado'] as num?) ?? 0).toDouble(),
    );
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Relatório de ordens de serviço'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            children: [
              Text(
                '${lista.length} OS(s) • Total: ${formatarMoeda(total)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final o = lista[i];
                    return ListTile(
                      title: Text(
                        'OS #${o['id']} — ${(o['cliente'] ?? {})['nome'] ?? ''}',
                      ),
                      subtitle: Text('${o['dataServico']} • ${o['descricao']}'),
                      trailing: Text(
                        formatarMoeda((o['valorCobrado'] as num?) ?? 0),
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
            onPressed: () => Navigator.pop(c),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _novaOrdem() async {
    final clientes = await _buscar('/api/clientes');
    if (clientes.isEmpty || !mounted) return;
    int clienteId = clientes.first['id'] as int;
    List<dynamic> piscinas = await _buscar('/api/piscinas/cliente/$clienteId');
    int? piscinaId = piscinas.length == 1 ? piscinas.first['id'] as int : null;
    final descricao = TextEditingController();
    final valorCobrado = TextEditingController();
    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (_, setLocal) => AlertDialog(
          title: const Text('Nova ordem de serviço'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: clienteId,
                    decoration: const InputDecoration(labelText: 'Cliente *'),
                    items: clientes
                        .map<DropdownMenuItem<int>>(
                          (cliente) => DropdownMenuItem(
                            value: cliente['id'],
                            child: Text(cliente['nome']),
                          ),
                        )
                        .toList(),
                    onChanged: (id) async {
                      final novasPiscinas = await _buscar(
                        '/api/piscinas/cliente/$id',
                      );
                      setLocal(() {
                        clienteId = id!;
                        piscinas = novasPiscinas;
                        piscinaId = novasPiscinas.length == 1
                            ? novasPiscinas.first['id'] as int
                            : null;
                      });
                    },
                  ),
                  DropdownButtonFormField<int>(
                    key: ValueKey(clienteId),
                    initialValue: piscinaId,
                    decoration: const InputDecoration(labelText: 'Piscina *'),
                    items: piscinas
                        .map<DropdownMenuItem<int>>(
                          (piscina) => DropdownMenuItem(
                            value: piscina['id'],
                            child: Text(piscina['nome']),
                          ),
                        )
                        .toList(),
                    onChanged: (id) => setLocal(() => piscinaId = id),
                  ),
                  TextField(
                    controller: descricao,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descrição do serviço *',
                    ),
                  ),
                  TextField(
                    controller: valorCobrado,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor sugerido para cobrar do cliente',
                      prefixText: 'R\$ ',
                      helperText:
                          'O gestor poderá confirmar ou alterar este valor ao concluir.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: piscinaId == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Criar OS'),
            ),
          ],
        ),
      ),
    );
    if (salvar != true || descricao.text.trim().isEmpty || piscinaId == null)
      return;
    final resposta = await apiService.post(
      '/api/ordens-servico',
      body: {
        'clienteId': clienteId,
        'piscinaId': piscinaId,
        'descricao': descricao.text.trim(),
        'dataServico': DateTime.now().toIso8601String().substring(0, 10),
        'valorAdicional':
            double.tryParse(valorCobrado.text.replaceAll(',', '.')) ?? 0,
      },
    );
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) _recarregar();
  }

  Future<void> _editar(Map<String, dynamic> ordem) async {
    final descricao = TextEditingController(text: ordem['descricao'] ?? '');
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text('Editar OS #${ordem['id']}'), content: TextField(controller: descricao, maxLines: 4, decoration: const InputDecoration(labelText: 'Descrição do serviço')), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Salvar'))]));
    if (ok != true || descricao.text.trim().isEmpty) return;
    final r = await apiService.put('/api/ordens-servico/${ordem['id']}', body: {'clienteId': (ordem['cliente'] ?? {})['id'], 'piscinaId': (ordem['piscina'] ?? {})['id'], 'descricao': descricao.text.trim(), 'dataServico': ordem['dataServico'], 'valorAdicional': ordem['valorAdicional'] ?? ordem['valorCobrado'] ?? 0});
    if (r.statusCode >= 200 && r.statusCode < 300) _recarregar();
  }

  Future<void> _concluir(Map<String, dynamic> ordem) async {
    final custo = TextEditingController(
      text: (ordem['valorCusto'] ?? 0).toString(),
    );
    final cobrado = TextEditingController(
      text: (ordem['valorCobrado'] ?? ordem['valorAdicional'] ?? 0).toString(),
    );
    String pagador = 'EMPRESA';
    final temCriador = ordem['criadoPor'] != null;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (_, setLocal) => AlertDialog(
          title: Text('Concluir OS #${ordem['id']}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: custo,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor pago/custo',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  TextField(
                    controller: cobrado,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor cobrado do cliente',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    value: 'EMPRESA',
                    groupValue: pagador,
                    title: const Text('Pago pela empresa'),
                    subtitle: const Text(
                      'Entra na cobrança do cliente, sem reembolso.',
                    ),
                    onChanged: (v) => setLocal(() => pagador = v!),
                  ),
                  RadioListTile<String>(
                    value: 'FUNCIONARIO',
                    groupValue: pagador,
                    title: const Text('Pago pelo funcionário'),
                    subtitle: Text(
                      temCriador
                          ? 'Gera cobrança e reembolso para quem criou a OS.'
                          : 'Indisponível: esta OS não possui funcionário criador.',
                    ),
                    onChanged: temCriador
                        ? (v) => setLocal(() => pagador = v!)
                        : null,
                  ),
                  RadioListTile<String>(
                    value: 'CLIENTE',
                    groupValue: pagador,
                    title: const Text('Pago pelo cliente'),
                    subtitle: const Text(
                      'Já está quitado: não entra em cobrança nem gera reembolso.',
                    ),
                    onChanged: (v) => setLocal(() => pagador = v!),
                  ),
                  const Divider(),
                  const Text(
                    'Ao confirmar, os lançamentos financeiros serão criados conforme a opção escolhida.',
                  ),
                ],
              ),
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
      '/api/ordens-servico/${ordem['id']}/concluir',
      body: {
        'valorCusto': double.tryParse(custo.text.replaceAll(',', '.')) ?? 0,
        'valorCobrado': double.tryParse(cobrado.text.replaceAll(',', '.')) ?? 0,
        'pagoPor': pagador,
      },
    );
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      _recarregar();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível concluir a OS (${resposta.statusCode}).',
          ),
        ),
      );
    }
  }

  Future<void> _cancelar(Map<String, dynamic> ordem) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar ordem de serviço?'),
        content: Text('Cancelar a OS #${ordem['id']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar OS'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final resposta = await apiService.put(
      '/api/ordens-servico/${ordem['id']}/cancelar',
    );
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) _recarregar();
  }

  Future<void> _detalhar(Map<String, dynamic> ordem) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('OS #${ordem['id']}'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ordem['descricao'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const Divider(),
              Text('Cliente: ${(ordem['cliente'] ?? {})['nome'] ?? ''}'),
              Text('Piscina: ${(ordem['piscina'] ?? {})['nome'] ?? ''}'),
              Text('Data: ${ordem['dataServico'] ?? '-'}'),
              Text(
                'Custo: ${formatarMoeda((ordem['valorCusto'] as num?) ?? 0)}',
              ),
              Text(
                'Cobrado: ${formatarMoeda((ordem['valorCobrado'] as num?) ?? 0)}',
              ),
              Text('Pago por: ${ordem['pagoPor'] ?? '-'}'),
              Text('Situação: ${ordem['status'] ?? '-'}'),
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
            titulo: 'Ordens de serviço',
            subtitulo:
                'Registre o serviço; o gestor define quem pagou ao concluir.',
            acao: Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _gerarRelatorio,
                  icon: const Icon(Icons.summarize_outlined),
                  label: const Text('Gerar relatório'),
                ),
                FilledButton.icon(
                  onPressed: _novaOrdem,
                  icon: const Icon(Icons.add),
                  label: const Text('Nova OS'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Pesquisar cliente ou serviço',
              border: OutlineInputBorder(),
            ),
            onChanged: (valor) =>
                setState(() => _filtro = valor.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: _ordens,
            builder: (_, estado) {
              if (!estado.hasData) return const SizedBox.shrink();
              final clientes =
                  estado.data!
                      .map((o) => (o['cliente'] ?? {})['nome'].toString())
                      .toSet()
                      .toList()
                    ..sort();
              final meses =
                  estado.data!
                      .map((o) => _mes(o['dataServico']))
                      .where((m) => m.isNotEmpty)
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
              future: _ordens,
              builder: (_, estado) {
                if (!estado.hasData)
                  return const Center(child: CircularProgressIndicator());
                if (estado.hasError)
                  return Center(child: Text('${estado.error}'));
                final ordens = _filtrarOrdens(estado.data!);
                if (ordens.isEmpty)
                  return const Center(child: Text('Nenhuma ordem de serviço.'));
                return Card(
                  child: ListView.separated(
                    itemCount: ordens.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, indice) {
                      final ordem = ordens[indice] as Map<String, dynamic>;
                      final aberta = ordem['status'] == 'ABERTA';
                      final celular = MediaQuery.of(context).size.width < 600;
                      if (celular) {
                        return ListTile(
                          onTap: () => _detalhar(ordem),
                          leading: CircleAvatar(child: Text('#${ordem['id']}')),
                          title: Text(
                            (ordem['cliente'] ?? {})['nome'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${ordem['descricao']}\n${ordem['dataServico']} • ${ordem['status']} • ${formatarMoeda((ordem['valorCobrado'] as num?) ?? 0)}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (acao) {
                              if (acao == 'ver') _detalhar(ordem);
                              if (acao == 'editar') _editar(ordem);
                              if (acao == 'concluir') _concluir(ordem);
                              if (acao == 'cancelar') _cancelar(ordem);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'ver',
                                child: Text('Ver detalhes'),
                              ),
                              if (widget.gestor && aberta)
                                const PopupMenuItem(
                                  value: 'editar',
                                  child: Text('Editar OS'),
                                ),
                              if (widget.gestor && aberta)
                                const PopupMenuItem(
                                  value: 'concluir',
                                  child: Text('Concluir OS'),
                                ),
                              if (aberta)
                                const PopupMenuItem(
                                  value: 'cancelar',
                                  child: Text('Cancelar OS'),
                                ),
                            ],
                          ),
                        );
                      }
                      return ListTile(
                        onTap: () => _detalhar(ordem),
                        leading: CircleAvatar(child: Text('#${ordem['id']}')),
                        title: Text((ordem['cliente'] ?? {})['nome'] ?? ''),
                        subtitle: Text(
                          '${ordem['descricao']}\n${ordem['dataServico']} • ${ordem['status']}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if ((ordem['valorCobrado'] as num?) != null)
                              Text(formatarMoeda(ordem['valorCobrado'] as num)),
                            IconButton(
                              tooltip: 'Ver detalhes',
                              onPressed: () => _detalhar(ordem),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            if (widget.gestor && aberta)
                              IconButton(
                                tooltip: 'Concluir OS',
                                onPressed: () => _concluir(ordem),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                              ),
                            if (aberta)
                              IconButton(
                                tooltip: 'Cancelar OS',
                                onPressed: () => _cancelar(ordem),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red,
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
