part of '../main.dart';

class _SalariosPageNova extends StatefulWidget {
  const _SalariosPageNova({required this.gestor});
  final bool gestor;

  @override
  State<_SalariosPageNova> createState() => _SalariosPageNovaState();
}

class _SalariosPageNovaState extends State<_SalariosPageNova> {
  late Future<List<dynamic>> _salarios;
  late DateTime _mesSelecionado;

  String get _referencia => '${_mesSelecionado.year}-${_mesSelecionado.month.toString().padLeft(2, '0')}';
  DateTime get _mesAtual {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month);
  }
  DateTime get _proximoMes => DateTime(_mesAtual.year, _mesAtual.month + 1);
  bool _mesIgual(DateTime primeiro, DateTime segundo) => primeiro.year == segundo.year && primeiro.month == segundo.month;

  String _nomeMes(DateTime mes) {
    const nomes = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    return '${nomes[mes.month - 1]} de ${mes.year}';
  }

  @override
  void initState() {
    super.initState();
    _mesSelecionado = _mesAtual;
    _salarios = _carregar();
  }

  Future<List<dynamic>> _carregar() async {
    final resposta = await apiService.get('/api/salarios?referencia=$_referencia');
    if (resposta.statusCode != 200) throw Exception('Não foi possível carregar os salários.');
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  Future<void> _abrirReembolsos(Map<String, dynamic> resumo) async {
    final funcionario = resumo['funcionario'] as Map<String, dynamic>;
    await showDialog<void>(
      context: context,
      builder: (_) => _DialogoReembolsos(
        funcionario: funcionario,
        gestor: widget.gestor,
        referencia: _referencia,
        aoAtualizar: () => setState(() => _salarios = _carregar()),
      ),
    );
  }
  Color _cor(Map<String,dynamic> f) => corDoColaborador(f);
  Future<void> _abrirVales() async { await showDialog<void>(context: context, builder: (_) => _DialogoVales(aoAtualizar: () => setState(() => _salarios = _carregar()))); }

  Widget _cartaoResumo(Map<String, dynamic> resumo) {
    final funcionario = resumo['funcionario'] ?? {};
    final usuario = funcionario['usuario'] ?? {};
    final salario = (resumo['salario'] as num?) ?? 0;
    final reembolsos = (resumo['reembolsos'] as num?) ?? 0;
    final total = (resumo['totalPagar'] as num?) ?? salario + reembolsos;
    return Card(
      child: InkWell(
        onTap: () => _abrirReembolsos(resumo),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(backgroundColor: _cor(funcionario).withValues(alpha:.15), foregroundColor:_cor(funcionario), child: const Icon(Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(child: Text(usuario['nome'] ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                const Icon(Icons.chevron_right),
              ]),
              const Divider(),
              Text('Comissão: ${formatarMoeda(salario)}'),
              Text('Reembolsos pendentes: ${formatarMoeda(reembolsos)}'),
              Text('Vales do mês: - ${formatarMoeda((resumo['vales'] as num?) ?? 0)}'),
              const SizedBox(height: 6),
              Text('Total a pagar: ${formatarMoeda(total)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 6),
              Text('${resumo['piscinas']} piscina(s) • ${resumo['clientes']} cliente(s)', style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
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
          Text(widget.gestor ? 'Salários' : 'Meu salário', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('A comissão e os reembolsos são calculados separadamente.'),
          if (widget.gestor) Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: _abrirVales, icon: const Icon(Icons.payments_outlined), label: const Text('Vale'))),
          const SizedBox(height: 12),
          Text('Referência: ${_nomeMes(_mesSelecionado)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text('Mês atual — ${_nomeMes(_mesAtual)}'),
                selected: _mesIgual(_mesSelecionado, _mesAtual),
                onSelected: (_) => setState(() {
                  _mesSelecionado = _mesAtual;
                  _salarios = _carregar();
                }),
              ),
              ChoiceChip(
                label: Text('Próximo mês — ${_nomeMes(_proximoMes)}'),
                selected: _mesIgual(_mesSelecionado, _proximoMes),
                onSelected: (_) => setState(() {
                  _mesSelecionado = _proximoMes;
                  _salarios = _carregar();
                }),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _salarios,
              builder: (_, estado) {
                if (!estado.hasData) return const Center(child: CircularProgressIndicator());
                if (estado.hasError) return Center(child: Text('${estado.error}'));
                if (estado.data!.isEmpty) return const Center(child: Text('Nenhum salário encontrado.'));
                return ListView(
                  children: [
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: estado.data!.map((item) => SizedBox(width: 390, child: _cartaoResumo(item as Map<String, dynamic>))).toList(),
                    ),
                    if (!widget.gestor) ...[
                      const SizedBox(height: 28),
                      const Text('Roteiro semanal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const _RoteiroSemanal(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogoVales extends StatefulWidget {
  const _DialogoVales({required this.aoAtualizar});
  final VoidCallback aoAtualizar;

  @override
  State<_DialogoVales> createState() => _DialogoValesState();
}

class _DialogoValesState extends State<_DialogoVales> {
  late Future<List<dynamic>> vales;

  @override
  void initState() {
    super.initState();
    vales = carregar();
  }

  Future<List<dynamic>> carregar() async {
    final resposta = await apiService.get('/api/salarios/vales');
    if (resposta.statusCode != 200) throw Exception('Não foi possível carregar os vales.');
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  void recarregar() {
    widget.aoAtualizar();
    setState(() => vales = carregar());
  }

  Future<void> formulario([Map<String, dynamic>? vale]) async {
    final funcionarios = await apiService.get('/api/funcionarios');
    if (funcionarios.statusCode != 200 || !mounted) return;
    final lista = jsonDecode(funcionarios.body) as List<dynamic>;
    int funcionario = (vale?['funcionario'] ?? {})['id'] ?? lista.first['id'];
    String tipo = vale?['tipo'] ?? 'ADIANTAMENTO';
    final valor = TextEditingController(text: (vale?['valor'] ?? '').toString());
    final observacao = TextEditingController(text: vale?['observacao'] ?? '');
    final salvar = await showDialog<bool>(
      context: context,
      builder: (contexto) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(vale == null ? 'Novo vale' : 'Editar vale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: funcionario,
                items: lista.map<DropdownMenuItem<int>>((item) => DropdownMenuItem(
                  value: item['id'],
                  child: Text((item['usuario'] ?? {})['nome'] ?? ''),
                )).toList(),
                onChanged: vale == null ? (value) => setDialogState(() => funcionario = value!) : null,
                decoration: const InputDecoration(labelText: 'Colaborador'),
              ),
              DropdownButtonFormField<String>(
                value: tipo,
                items: const [
                  DropdownMenuItem(value: 'ADIANTAMENTO', child: Text('Adiantamento')),
                  DropdownMenuItem(value: 'DINHEIRO_CLIENTE', child: Text('Dinheiro recebido de cliente')),
                ],
                onChanged: (value) => setDialogState(() => tipo = value!),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              TextField(
                controller: valor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '),
              ),
              TextField(controller: observacao, decoration: const InputDecoration(labelText: 'Observação')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (salvar != true) return;
    final dados = {
      'funcionarioId': funcionario,
      'tipo': tipo,
      'valor': double.tryParse(valor.text.replaceAll(',', '.')) ?? 0,
      'observacao': observacao.text.trim(),
    };
    final resposta = vale == null
        ? await apiService.post('/api/salarios/vales', body: dados)
        : await apiService.put('/api/salarios/vales/${vale['id']}', body: dados);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) recarregar();
  }

  Future<void> excluir(Map<String, dynamic> vale) async {
    final resposta = await apiService.delete('/api/salarios/vales/${vale['id']}');
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final celular = MediaQuery.of(context).size.width < 600;
    return AlertDialog(
      insetPadding: EdgeInsets.all(celular ? 18 : 24),
      title: const Text('Vales dos colaboradores'),
      content: SizedBox(
        width: celular ? double.maxFinite : 650,
        height: celular ? 390 : 420,
        child: FutureBuilder<List<dynamic>>(
          future: vales,
          builder: (_, estado) {
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());
            if (estado.hasError) return Center(child: Text('${estado.error}'));
            return ListView.separated(
              itemCount: estado.data!.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, indice) {
                final vale = estado.data![indice] as Map<String, dynamic>;
                final funcionario = vale['funcionario'] ?? {};
                final usuario = funcionario['usuario'] ?? {};
                final valor = formatarMoeda((vale['valor'] as num?) ?? 0);
                final subtitulo = celular
                    ? '${vale['tipo']} • ${vale['dataLancamento']}\n$valor'
                    : '${vale['tipo']} • ${vale['dataLancamento']}\n${vale['observacao'] ?? ''}';
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: celular ? 2 : 16),
                  onTap: () => formulario(vale),
                  leading: CircleAvatar(
                    backgroundColor: [Colors.blue, Colors.green, Colors.orange, Colors.deepPurple]
                        [(funcionario['id'] as int? ?? 0) % 4]
                        .withValues(alpha: .15),
                    child: const Icon(Icons.person_outline),
                  ),
                  title: Text(usuario['nome'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(subtitulo, maxLines: 2, overflow: TextOverflow.ellipsis),
                  isThreeLine: true,
                  trailing: celular
                      ? PopupMenuButton<String>(
                          tooltip: 'Opções do vale',
                          onSelected: (opcao) {
                            if (opcao == 'editar') formulario(vale);
                            if (opcao == 'excluir') excluir(vale);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'editar', child: Text('Editar vale')),
                            PopupMenuItem(value: 'excluir', child: Text('Excluir vale')),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(valor),
                            IconButton(onPressed: () => formulario(vale), icon: const Icon(Icons.edit_outlined)),
                            IconButton(onPressed: () => excluir(vale), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                          ],
                        ),
                );
              },
            );
          },
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        OutlinedButton.icon(onPressed: () => formulario(), icon: const Icon(Icons.add), label: const Text('Novo vale')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ],
    );
  }
}

class _DialogoReembolsos extends StatefulWidget {
  const _DialogoReembolsos({required this.funcionario, required this.gestor, required this.referencia, required this.aoAtualizar});
  final Map<String, dynamic> funcionario;
  final bool gestor;
  final String referencia;
  final VoidCallback aoAtualizar;

  @override
  State<_DialogoReembolsos> createState() => _DialogoReembolsosState();
}

class _DialogoReembolsosState extends State<_DialogoReembolsos> {
  late Future<List<dynamic>> _reembolsos;
  late Future<List<dynamic>> _vales;

  @override
  void initState() {
    super.initState();
    _reembolsos = _carregar();
    _vales = _carregarVales();
  }

  Future<List<dynamic>> _carregar() async {
    final resposta = await apiService.get('/api/salarios/${widget.funcionario['id']}/reembolsos?referencia=${widget.referencia}');
    if (resposta.statusCode != 200) throw Exception('Não foi possível carregar os reembolsos.');
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  Future<List<dynamic>> _carregarVales() async {
    final resposta = await apiService.get('/api/salarios/vales?funcionarioId=${widget.funcionario['id']}&referencia=${widget.referencia}');
    if (resposta.statusCode != 200) throw Exception('Não foi possível carregar os vales.');
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  Future<void> _pagar(Map<String, dynamic> reembolso) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar reembolso?'),
        content: Text('Confirmar o pagamento de ${formatarMoeda((reembolso['valor'] as num?) ?? 0)} ao colaborador?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar pagamento')),
        ],
      ),
    );
    if (confirmar != true) return;
    final resposta = await apiService.put('/api/salarios/reembolsos/${reembolso['id']}/pagar');
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      widget.aoAtualizar();
      setState(() {
        _reembolsos = _carregar();
        _vales = _carregarVales();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.funcionario['usuario'] ?? {};
    return AlertDialog(
      title: Text('Detalhes — ${usuario['nome'] ?? ''}'),
      content: SizedBox(
        width: 650,
        height: 430,
        child: FutureBuilder<List<dynamic>>(
          future: _reembolsos,
          builder: (_, estado) {
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());
            if (estado.hasError) return Center(child: Text('${estado.error}'));
            return FutureBuilder<List<dynamic>>(
              future: _vales,
              builder: (_, estadoVales) {
                if (!estadoVales.hasData) return const Center(child: CircularProgressIndicator());
                if (estadoVales.hasError) return Center(child: Text('${estadoVales.error}'));
                final reembolsos = estado.data!;
                final vales = estadoVales.data!;
                return ListView(
                  children: [
                    const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Reembolsos', style: TextStyle(fontWeight: FontWeight.bold))),
                    if (reembolsos.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Nenhum reembolso lançado neste mês.')),
                    ...reembolsos.map((item) {
                      final reembolso = item as Map<String, dynamic>;
                      final pendente = reembolso['status'] == 'PENDENTE';
                      return ListTile(
                        leading: Icon(pendente ? Icons.pending_actions : Icons.check_circle, color: pendente ? Colors.orange : Colors.green),
                        title: Text(reembolso['descricao'] ?? ''),
                        subtitle: Text('${reembolso['dataLancamento']} • ${reembolso['status']}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(formatarMoeda((reembolso['valor'] as num?) ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (widget.gestor && pendente) IconButton(tooltip: 'Confirmar reembolso', onPressed: () => _pagar(reembolso), icon: const Icon(Icons.check_circle_outline, color: Colors.green)),
                        ]),
                      );
                    }),
                    const Divider(height: 28),
                    const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Vales lançados', style: TextStyle(fontWeight: FontWeight.bold))),
                    if (vales.isEmpty) const Text('Nenhum vale lançado neste mês.'),
                    ...vales.map((item) {
                      final vale = item as Map<String, dynamic>;
                      final tipo = vale['tipo'] == 'DINHEIRO_CLIENTE' ? 'Dinheiro recebido de cliente' : 'Adiantamento';
                      return ListTile(
                        leading: const Icon(Icons.payments_outlined, color: Colors.orange),
                        title: Text(tipo),
                        subtitle: Text('${vale['dataLancamento']} • ${vale['observacao'] ?? ''}'),
                        trailing: Text('- ${formatarMoeda((vale['valor'] as num?) ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    );
  }
}
