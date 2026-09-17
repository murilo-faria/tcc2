part of '../main.dart';

class _ResumoFuncionario extends StatelessWidget {
  const _ResumoFuncionario();
  Future<List<dynamic>> _lista(String rota) async {
    final r = await apiService.get(rota);
    return r.statusCode == 200 ? jsonDecode(r.body) as List<dynamic> : const [];
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<List<dynamic>>>(
    future: Future.wait([
      _lista('/api/clientes'),
      _lista('/api/ordens-servico'),
      _lista('/api/pedidos-produto'),
      _lista('/api/salarios'),
    ]),
    builder: (_, s) {
      final d = s.data ?? const [[], [], [], []];
      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      final servicos = d[1].where((x) => x['dataServico'] == hoje).length;
      final pedidos = d[2].where((x) => x['status'] == 'SOLICITADO').length;
      final salario = d[3].isEmpty
          ? 0
          : ((d[3].first['totalPagar'] ?? d[3].first['salario']) as num);
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _Indicador(
            'Meus clientes',
            '${d[0].length}',
            Icons.people_outline,
            const Color(0xFF1565C0),
          ),
          _Indicador(
            'Serviços hoje',
            '$servicos',
            Icons.build_outlined,
            const Color(0xFFF4A261),
          ),
          _Indicador(
            'Pedidos em aberto',
            '$pedidos',
            Icons.shopping_cart_outlined,
            const Color(0xFFE76F51),
          ),
          _Indicador(
            'Salário + reembolsos',
            formatarMoeda(salario),
            Icons.payments_outlined,
            const Color(0xFF1976D2),
          ),
        ],
      );
    },
  );
}

class _ProximosServicosFuncionario extends StatelessWidget {
  const _ProximosServicosFuncionario();
  @override
  Widget build(BuildContext context) => FutureBuilder<http.Response>(
    future: apiService.get('/api/ordens-servico'),
    builder: (_, s) {
      if (!s.hasData)
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      if (s.data!.statusCode != 200)
        return const Card(
          child: ListTile(title: Text('Nenhum serviço disponível.')),
        );
      final itens = jsonDecode(s.data!.body) as List<dynamic>;
      if (itens.isEmpty)
        return const Card(
          child: ListTile(
            leading: Icon(Icons.pool_outlined),
            title: Text('Nenhum serviço nas piscinas vinculadas.'),
          ),
        );
      return Card(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itens.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final o = itens[i] as Map<String, dynamic>;
            final p = o['piscina'] ?? {};
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.pool)),
              title: Text(
                '${(o['cliente'] ?? {})['nome'] ?? ''} — ${p['nome'] ?? 'Piscina'}',
              ),
              subtitle: Text('${o['dataServico']} • ${o['descricao']}'),
            );
          },
        ),
      );
    },
  );
}

class _FuncionariosPage extends StatefulWidget {
  const _FuncionariosPage();
  @override
  State<_FuncionariosPage> createState() => _FuncionariosPageState();
}

class _FuncionariosPageState extends State<_FuncionariosPage> {
  late Future<List<dynamic>> dados;
  @override
  void initState() {
    super.initState();
    dados = carregar();
  }

  Future<List<dynamic>> carregar() async {
    final r = await apiService.get('/api/funcionarios');
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar funcionários.');
    return jsonDecode(r.body);
  }

  Future<void> novo() async {
    final nome = TextEditingController(),
        login = TextEditingController(),
        senha = TextEditingController(),
        telefone = TextEditingController(),
        percentual = TextEditingController(text: '75');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo colaborador'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Nome *'),
              ),
              TextField(
                controller: login,
                decoration: const InputDecoration(
                  labelText: 'Usuário de acesso *',
                ),
              ),
              TextField(
                controller: senha,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha *'),
              ),
              TextField(
                controller: telefone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              TextField(
                controller: percentual,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Percentual sobre recebimentos',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await apiService.post(
      '/api/funcionarios',
      body: {
        'nome': nome.text.trim(),
        'login': login.text.trim(),
        'senha': senha.text,
        'telefone': telefone.text.trim(),
        'percentualMensalidade':
            double.tryParse(percentual.text.replaceAll(',', '.')) ?? 75,
      },
    );
    if (!mounted) return;
    if (r.statusCode >= 200 && r.statusCode < 300) {
      setState(() => dados = carregar());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Colaborador cadastrado. Agora vincule as piscinas a ele.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível cadastrar (${r.statusCode}).'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext c) => _PaginaLista(
    titulo: 'Colaboradores',
    subtitulo:
        'Cadastre os acessos e depois defina as piscinas de responsabilidade.',
    acao: 'Novo colaborador',
    onAcao: novo,
    futuro: dados,
    item: (f) {
      final u = f['usuario'] ?? {};
      return ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(u['nome'] ?? ''),
        subtitle: Text(
          'Usuário: ${u['login'] ?? ''} • ${f['telefone'] ?? 'sem telefone'}',
        ),
        trailing: Text('${f['percentualMensalidade'] ?? 75}%'),
      );
    },
  );
}

class _PiscinasPage extends StatefulWidget {
  const _PiscinasPage({required this.gestor});
  final bool gestor;
  @override
  State<_PiscinasPage> createState() => _PiscinasPageState();
}

class _PiscinasPageState extends State<_PiscinasPage> {
  late Future<List<dynamic>> dados;
  @override
  void initState() {
    super.initState();
    dados = carregar();
  }

  Future<List<dynamic>> carregar() async {
    final r = await apiService.get('/api/piscinas');
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar piscinas.');
    return jsonDecode(r.body);
  }

  Future<void> novo() async {
    final clientes = await _lista('/api/clientes');
    final funcs = await _lista('/api/funcionarios');
    if (clientes.isEmpty || !mounted) return;
    int cliente = clientes.first['id'];
    int? responsavel = funcs.isEmpty ? null : funcs.first['id'];
    final nome = TextEditingController(),
        endereco = TextEditingController(),
        tipo = TextEditingController(), valor = TextEditingController(), volume = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setL) => AlertDialog(
          title: const Text('Nova piscina'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: cliente,
                    decoration: const InputDecoration(labelText: 'Cliente *'),
                    items: clientes
                        .map<DropdownMenuItem<int>>(
                          (x) => DropdownMenuItem(
                            value: x['id'],
                            child: Text(x['nome']),
                          ),
                        )
                        .toList(),
                    onChanged: (x) => setL(() => cliente = x!),
                  ),
                  TextField(
                    controller: nome,
                    decoration: const InputDecoration(
                      labelText: 'Nome ou identificação *',
                    ),
                  ),
                  TextField(
                    controller: endereco,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Endereço da piscina *',
                    ),
                  ),
                  TextField(
                    controller: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                  ),
                  TextField(controller: volume, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Volume em litros')),
                  TextField(controller: valor, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor mensal da piscina', prefixText: 'R\$ ')),
                  DropdownButtonFormField<int>(
                    initialValue: responsavel,
                    decoration: const InputDecoration(
                      labelText: 'Colaborador responsável',
                    ),
                    items: funcs
                        .map<DropdownMenuItem<int>>(
                          (x) => DropdownMenuItem(
                            value: x['id'],
                            child: Text((x['usuario'] ?? {})['nome'] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (x) => setL(() => responsavel = x),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final r = await apiService.post(
      '/api/piscinas',
      body: {
        'clienteId': cliente,
        'nome': nome.text.trim(),
        'endereco': endereco.text.trim(),
        'tipo': tipo.text.trim(),
        'volumeLitros': int.tryParse(volume.text) ?? 0,
        'responsavelId': responsavel,
        'observacoes': '',
        'valorMensalidade': double.tryParse(valor.text.replaceAll(',', '.')) ?? 0,
      },
    );
    if (!mounted) return;
    if (r.statusCode >= 200 && r.statusCode < 300) {
      setState(() => dados = carregar());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Piscina cadastrada.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar (${r.statusCode}).')),
      );
    }
  }

  Future<List<dynamic>> _lista(String url) async {
    final r = await apiService.get(url);
    return r.statusCode == 200 ? jsonDecode(r.body) : [];
  }

  Future<void> excluir(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir piscina?'),
        content: Text('Excluir ${p['nome']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final r = await apiService.delete('/api/piscinas/${p['id']}');
      if (r.statusCode >= 200 && r.statusCode < 300)
        setState(() => dados = carregar());
    }
  }

  Future<void> editar(Map<String, dynamic> p) async {
    final funcs = await _lista('/api/funcionarios');
    final nome = TextEditingController(text: p['nome'] ?? ''),
        endereco = TextEditingController(text: p['endereco'] ?? ''),
        tipo = TextEditingController(text: p['tipo'] ?? ''),
        valor = TextEditingController(text: (p['valorMensalidade'] ?? 0).toString()),
        volume = TextEditingController(text: (p['volumeLitros'] ?? 0).toString());
    int? responsavel = (p['responsavel'] ?? {})['id'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (_, setLocal) => AlertDialog(
        title: const Text('Editar piscina'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: endereco,
                decoration: const InputDecoration(labelText: 'Endereço'),
              ),
              TextField(
                controller: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              TextField(controller: volume, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Volume em litros')),
              TextField(controller: valor, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor mensal da piscina', prefixText: 'R\$ ')),
              DropdownButtonFormField<int?>(initialValue: responsavel, decoration: const InputDecoration(labelText: 'Colaborador responsável'), items: [const DropdownMenuItem<int?>(value: null, child: Text('Definir depois')), ...funcs.map<DropdownMenuItem<int?>>((f) => DropdownMenuItem<int?>(value: f['id'], child: Text((f['usuario'] ?? {})['nome'] ?? '')))], onChanged: (v) => setLocal(() => responsavel = v)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      )),
    );
    if (ok == true) {
      final r = await apiService.put(
        '/api/piscinas/${p['id']}',
        body: {
          'clienteId': (p['cliente'] ?? {})['id'],
          'responsavelId': responsavel,
          'nome': nome.text.trim(),
          'endereco': endereco.text.trim(),
          'tipo': tipo.text.trim(),
          'volumeLitros': int.tryParse(volume.text) ?? 0,
          'observacoes': p['observacoes'] ?? '',
          'valorMensalidade': double.tryParse(valor.text.replaceAll(',', '.')) ?? 0,
        },
      );
      if (r.statusCode >= 200 && r.statusCode < 300)
        setState(() => dados = carregar());
    }
  }

  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Piscinas',
                    style: Theme.of(c).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.gestor
                        ? 'Cada piscina tem endereço, cliente e responsável.'
                        : 'Somente suas piscinas de responsabilidade.',
                  ),
                ],
              ),
            ),
            if (widget.gestor)
              FilledButton.icon(
                onPressed: novo,
                icon: const Icon(Icons.add),
                label: const Text('Nova piscina'),
              ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Pesquisar piscina, cliente ou endereço',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: dados,
            builder: (_, s) {
              if (s.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (s.hasError) return Center(child: Text('${s.error}'));
              if (s.data!.isEmpty)
                return const Center(child: Text('Nenhuma piscina cadastrada.'));
              return Card(
                child: ListView.separated(
                  itemCount: s.data!.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = s.data![i] as Map<String, dynamic>;
                    final cl = p['cliente'] ?? {},
                        resp = p['responsavel'] ?? {},
                        u = resp['usuario'] ?? {};
                    final celular = MediaQuery.of(context).size.width < 600;
                    if (celular) {
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.pool)),
                        title: Text(
                          p['nome'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${cl['nome'] ?? ''}\n${p['endereco'] ?? 'Endereço não informado'}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: widget.gestor
                            ? PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (acao) {
                                  if (acao == 'editar') editar(p);
                                  if (acao == 'excluir') excluir(p);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'excluir',
                                    child: Text('Excluir'),
                                  ),
                                ],
                              )
                            : null,
                      );
                    }
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.pool)),
                      title: Text(p['nome'] ?? ''),
                      subtitle: Text(
                        '${cl['nome'] ?? ''} • ${p['endereco'] ?? 'endereço não informado'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(u['nome'] ?? 'Sem responsável'),
                          if (widget.gestor)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => editar(p),
                            ),
                          if (widget.gestor)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => excluir(p),
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

class _CobrancasPage extends StatefulWidget {
  const _CobrancasPage();
  @override
  State<_CobrancasPage> createState() => _CobrancasPageState();
}

class _CobrancasPageState extends State<_CobrancasPage> {
  late Future<List<dynamic>> dados;
  @override
  void initState() {
    super.initState();
    dados = carregar();
  }

  Future<List<dynamic>> carregar() async {
    final r = await apiService.get('/api/cobrancas');
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar cobranças.');
    return jsonDecode(r.body);
  }

  Future<void> pagar(Map<String, dynamic> x) async {
    final pago = x['status'] == 'PAGO';
    final r = await apiService.put(
      pago
          ? '/api/cobrancas/${x['id']}/reabrir'
          : '/api/cobrancas/${x['id']}/baixar?valor=${x['total']}',
    );
    if (r.statusCode >= 200 && r.statusCode < 300)
      setState(() => dados = carregar());
  }

  @override
  Widget build(BuildContext c) => _PaginaLista(
    titulo: 'Cobranças',
    subtitulo: 'Mensalidades e valores de produtos e serviços.',
    futuro: dados,
    item: (x) {
      final pago = x['status'] == 'PAGO';
      return ListTile(
        leading: Icon(
          pago ? Icons.check_circle : Icons.pending_actions,
          color: pago ? Colors.green : Colors.orange,
        ),
        title: Text((x['cliente'] ?? {})['nome'] ?? ''),
        subtitle: Text('Vencimento: ${x['vencimento']} • ${x['status']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatarMoeda(x['total'] as num)),
            Switch(value: pago, onChanged: (_) => pagar(x)),
          ],
        ),
      );
    },
  );
}

class _SalariosPage extends StatefulWidget {
  const _SalariosPage({required this.gestor});
  final bool gestor;
  @override
  State<_SalariosPage> createState() => _SalariosPageState();
}

class _SalariosPageState extends State<_SalariosPage> {
  late Future<List<dynamic>> dados;
  @override
  void initState() {
    super.initState();
    dados = carregar();
  }

  Future<List<dynamic>> carregar() async {
    final r = await apiService.get('/api/salarios');
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar salários.');
    return jsonDecode(r.body);
  }

  @override
  Widget build(BuildContext c) {
    if (widget.gestor)
      return _PaginaLista(
        titulo: 'Salários',
        subtitulo:
            'Cálculo sobre as mensalidades dos clientes das piscinas vinculadas.',
        futuro: dados,
        item: (x) {
          final f = x['funcionario'] ?? {}, u = f['usuario'] ?? {};
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.payments)),
            title: Text(u['nome'] ?? ''),
            subtitle: Text(
              '${x['piscinas']} piscina(s) • ${x['clientes']} cliente(s)',
            ),
            trailing: Text(
              formatarMoeda(x['salario'] as num),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      );
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meu salário',
            style: Theme.of(
              c,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text('Resumo das piscinas sob sua responsabilidade.'),
          const SizedBox(height: 24),
          FutureBuilder<List<dynamic>>(
            future: dados,
            builder: (_, s) {
              if (!s.hasData)
                return const Center(child: CircularProgressIndicator());
              final x = s.data!.isEmpty ? null : s.data!.first;
              if (x == null) return const Text('Nenhum vínculo encontrado.');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _Indicador(
                        'Total de clientes',
                        '${x['clientes']}',
                        Icons.people_outline,
                        const Color(0xFF1565C0),
                      ),
                      _Indicador(
                        'Salário total',
                        formatarMoeda(x['salario'] as num),
                        Icons.payments_outlined,
                        const Color(0xFF1976D2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Roteiro semanal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const _RoteiroSemanal(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoteiroSemanal extends StatefulWidget {
  const _RoteiroSemanal();
  @override
  State<_RoteiroSemanal> createState() => _RoteiroSemanalState();
}

class _RoteiroSemanalState extends State<_RoteiroSemanal> {
  late Future<List<List<dynamic>>> _dados;

  @override
  void initState() {
    super.initState();
    _dados = _carregar();
  }

  Future<List<List<dynamic>>> _carregar() async {
    final respostas = await Future.wait([apiService.get('/api/roteiro'), apiService.get('/api/clientes')]);
    if (respostas.any((r) => r.statusCode != 200)) throw Exception('Não foi possível carregar o roteiro.');
    return respostas.map((r) => jsonDecode(r.body) as List<dynamic>).toList();
  }

  Future<void> _salvarRota(String rota, String metodo, Map<String, dynamic>? corpo) async {
    final resposta = metodo == 'POST' ? await apiService.post(rota, body: corpo) : metodo == 'PUT' ? await apiService.put(rota, body: corpo) : await apiService.delete(rota);
    if (!mounted) return;
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível atualizar a rota.')));
      return;
    }
    setState(() => _dados = _carregar());
  }

  Future<void> _adicionarCliente(String dia, List<dynamic> clientes) async {
    final busca = TextEditingController();
    final escolhido = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (contexto) => StatefulBuilder(
        builder: (_, atualizar) => AlertDialog(
          title: Text('Adicionar cliente — $dia'),
          content: SizedBox(
            width: 420,
            height: 420,
            child: Column(children: [
              TextField(controller: busca, autofocus: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Pesquisar cliente'), onChanged: (_) => atualizar(() {})),
              const SizedBox(height: 8),
              Expanded(child: ListView(children: clientes.where((c) => '${c['nome']}'.toLowerCase().contains(busca.text.toLowerCase())).map((c) => ListTile(title: Text('${c['nome']}'), trailing: const Icon(Icons.add_circle_outline), onTap: () => Navigator.pop(contexto, c as Map<String, dynamic>))).toList())),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(contexto), child: const Text('Cancelar'))],
        ),
        ),
    );
    busca.dispose();
    if (escolhido != null) await _salvarRota('/api/roteiro', 'POST', {'clienteId': escolhido['id'], 'diaAtendimento': dia});
  }

  @override
  Widget build(BuildContext c) => FutureBuilder<List<List<dynamic>>>(
    future: _dados,
    builder: (_, s) {
      if (s.hasError) return const Text('Não foi possível carregar o roteiro.');
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final rotas = s.data![0];
      final clientes = s.data![1];
      const dias = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ...dias.map((dia) {
          final visitas = rotas.where((r) => r['diaAtendimento'] == dia).cast<Map<String, dynamic>>().toList();
          return SizedBox(
            width: 220,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dia.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ...visitas.map((visita) {
                      return Row(children: [
                        Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${visita['clienteNome']}'))),
                        PopupMenuButton<String>(
                          tooltip: 'Mudar dia',
                          icon: const Icon(Icons.edit_calendar_outlined, size: 19),
                          onSelected: (novoDia) => _salvarRota('/api/roteiro/${visita['id']}', novoDia == '_REMOVER_' ? 'DELETE' : 'PUT', novoDia == '_REMOVER_' ? null : {'clienteId': visita['clienteId'], 'diaAtendimento': novoDia}),
                          itemBuilder: (_) => [
                            ...dias.map((d) => PopupMenuItem(value: d, child: Text(d))),
                            const PopupMenuDivider(),
                            const PopupMenuItem(value: '_REMOVER_', child: Text('Remover da rota', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ]);
                    }),
                    TextButton.icon(
                      onPressed: () => _adicionarCliente(dia, clientes),
                      icon: const Icon(Icons.add_circle_outline, size: 19),
                      label: const Text('Adicionar cliente'),
                    ),
                    const Divider(),
                    Text(
                      '${visitas.length} cliente(s)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          );
          }).toList(),
          Builder(builder: (_) {
            final vinculados = rotas.map((r) => '${r['clienteId']}').toSet();
            final listaClientes = clientes.cast<Map<String, dynamic>>().toList()
              ..sort((a, b) => '${a['nome']}'.compareTo('${b['nome']}'));
            final clientesSemRota = listaClientes.where((cliente) => !vinculados.contains('${cliente['id']}')).toList();
            return SizedBox(width: 280, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CLIENTES SEM ROTA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                const Divider(),
                if (clientesSemRota.isEmpty) const Text('Todos os clientes estão na agenda.') else ...clientesSemRota.map((cliente) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${cliente['nome']}'))),
                const Divider(), Text('${clientesSemRota.length} cliente(s) sem rota', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]))));
          }),
        ],
      );
    },
  );
}

class _PaginaLista extends StatelessWidget {
  const _PaginaLista({
    required this.titulo,
    required this.subtitulo,
    required this.futuro,
    required this.item,
    this.acao,
    this.onAcao,
  });
  final String titulo, subtitulo;
  final Future<List<dynamic>> futuro;
  final Widget Function(Map<String, dynamic>) item;
  final String? acao;
  final VoidCallback? onAcao;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(c).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitulo),
                ],
              ),
            ),
            if (acao != null)
              FilledButton.icon(
                onPressed: onAcao,
                icon: const Icon(Icons.add),
                label: Text(acao!),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: futuro,
            builder: (_, s) {
              if (s.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (s.hasError) return Center(child: Text('${s.error}'));
              if (s.data!.isEmpty)
                return const Center(child: Text('Nenhum registro encontrado.'));
              return Card(
                child: ListView.separated(
                  itemCount: s.data!.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      item(s.data![i] as Map<String, dynamic>),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
