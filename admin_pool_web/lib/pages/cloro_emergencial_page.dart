part of '../main.dart';

class _CloroEmergencialPage extends StatefulWidget {
  const _CloroEmergencialPage({required this.gestor});
  final bool gestor;
  @override
  State<_CloroEmergencialPage> createState() => _CloroEmergencialPageState();
}

class _CloroEmergencialPageState extends State<_CloroEmergencialPage> {
  late Future<List<dynamic>> _listas;
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() { super.initState(); _listas = _carregar(); }

  String get _referencia => '${_mes.year}-${_mes.month.toString().padLeft(2, '0')}';
  String get _tituloMes {
    const meses = ['janeiro','fevereiro','março','abril','maio','junho','julho','agosto','setembro','outubro','novembro','dezembro'];
    return '${meses[_mes.month - 1]} de ${_mes.year}';
  }
  Future<List<dynamic>> _carregar() async {
    final r = await apiService.get('/api/cloro-emergencial?referencia=$_referencia');
    if (r.statusCode != 200) throw Exception('Não foi possível carregar o cloro emergencial.');
    return jsonDecode(r.body) as List<dynamic>;
  }
  void _recarregar() => setState(() => _listas = _carregar());
  double _totalKg(Map<String, dynamic> lista) => ((lista['usos'] as List<dynamic>? ?? const [])
      .fold<num>(0, (soma, uso) => soma + ((uso['quantidadeKg'] as num?) ?? 0))).toDouble();
  String _numero(double valor) => valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toStringAsFixed(2).replaceAll('.', ',');
  String _status(Map<String, dynamic> lista) => switch (lista['status']) {
    'COBRADA' => 'Cobrado', 'AGUARDANDO_REPOSICAO' => 'Aguardando reposição', 'REPOSTA' => 'Reposto', _ => 'Em aberto',
  };

  Future<void> _novaLista() async {
    final r = await apiService.get('/api/clientes');
    if (r.statusCode != 200 || !mounted) return;
    final clientes = jsonDecode(r.body) as List<dynamic>;
    clientes.sort((a, b) => '${a['nome']}'.toLowerCase().compareTo('${b['nome']}'.toLowerCase()));
    if (clientes.isEmpty) return;
    int clienteId = clientes.first['id'] as int;
    final confirmar = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (_, setLocal) => AlertDialog(
      title: const Text('Cloro emergencial'),
      content: DropdownButtonFormField<int>(
        value: clienteId, decoration: const InputDecoration(labelText: 'Cliente *'),
        items: clientes.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'] as int, child: Text('${c['nome']}'))).toList(),
        onChanged: (v) => setLocal(() => clienteId = v!),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Abrir lista'))],
    )));
    if (confirmar != true) return;
    final criar = await apiService.post('/api/cloro-emergencial', body: {'clienteId': clienteId});
    if (criar.statusCode >= 200 && criar.statusCode < 300) { _recarregar(); if (mounted) await _detalhar(jsonDecode(criar.body) as Map<String, dynamic>); }
  }

  Future<void> _adicionarUso(Map<String, dynamic> lista) async {
    final quantidade = TextEditingController(); final descricao = TextEditingController();
    final salvar = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Adicionar uso de cloro'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: quantidade, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantidade (kg) *', suffixText: 'kg')),
        TextField(controller: descricao, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição')),
        const Padding(padding: EdgeInsets.only(top: 12), child: Text('A data será registrada como hoje.')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Adicionar'))],
    ));
    if (salvar != true) return;
    final r = await apiService.post('/api/cloro-emergencial/${lista['id']}/usos', body: {'quantidadeKg': double.tryParse(quantidade.text.replaceAll(',', '.')) ?? 0, 'descricao': descricao.text.trim()});
    if (r.statusCode >= 200 && r.statusCode < 300) { _recarregar(); if (mounted) { Navigator.pop(context); await _detalhar(jsonDecode(r.body) as Map<String, dynamic>); } }
  }

  Future<void> _finalizar(Map<String, dynamic> lista) async {
    String destino = 'COBRANCA'; final valor = TextEditingController();
    final confirmar = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (_, setLocal) => AlertDialog(
      title: const Text('Finalizar cloro emergencial'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        RadioListTile(value: 'COBRANCA', groupValue: destino, onChanged: (v) => setLocal(() => destino = v!), title: const Text('Gerar cobrança'), subtitle: const Text('Informe o valor total para o cliente.')),
        if (destino == 'COBRANCA') TextField(controller: valor, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor a cobrar', prefixText: 'R\$ ')),
        RadioListTile(value: 'REPOSICAO', groupValue: destino, onChanged: (v) => setLocal(() => destino = v!), title: const Text('Reposição de cloro'), subtitle: const Text('Não gera cobrança; fica aguardando o cliente repor o cloro.')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finalizar'))],
    )));
    if (confirmar != true) return;
    final r = await apiService.put('/api/cloro-emergencial/${lista['id']}/finalizar', body: {'destino': destino, 'valorCobrado': double.tryParse(valor.text.replaceAll(',', '.')) ?? 0});
    if (r.statusCode >= 200 && r.statusCode < 300) { _recarregar(); if (mounted) Navigator.pop(context); }
  }

  Future<void> _confirmarReposicao(Map<String, dynamic> lista) async {
    final r = await apiService.put('/api/cloro-emergencial/${lista['id']}/confirmar-reposicao');
    if (r.statusCode >= 200 && r.statusCode < 300) { _recarregar(); if (mounted) Navigator.pop(context); }
  }

  Future<void> _detalhar(Map<String, dynamic> lista) async {
    final usos = (lista['usos'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    await showDialog<void>(context: context, builder: (_) => AlertDialog(
      title: Text('Cloro — ${(lista['cliente'] ?? {})['nome'] ?? ''}'),
      content: SizedBox(width: 560, height: 360, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_numero(_totalKg(lista))} kg usados • ${_status(lista)}', style: const TextStyle(fontWeight: FontWeight.bold)), const Divider(),
        Expanded(child: usos.isEmpty ? const Center(child: Text('Nenhum uso registrado.')) : ListView.separated(itemCount: usos.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, i) { final uso = usos[i]; return ListTile(contentPadding: EdgeInsets.zero, title: Text('${_numero(((uso['quantidadeKg'] as num?) ?? 0).toDouble())} kg'), subtitle: Text('${uso['dataUso']} • ${uso['descricao'] ?? ''}')); })),
      ])),
      actions: [
        if (lista['status'] == 'ABERTA') TextButton.icon(onPressed: () => _adicionarUso(lista), icon: const Icon(Icons.add), label: const Text('Adicionar uso')),
        if (widget.gestor && lista['status'] == 'ABERTA' && usos.isNotEmpty) FilledButton(onPressed: () => _finalizar(lista), child: const Text('Finalizar')),
        if (widget.gestor && lista['status'] == 'AGUARDANDO_REPOSICAO') FilledButton(onPressed: () => _confirmarReposicao(lista), child: const Text('Confirmar reposição')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CabecalhoResponsivo(titulo: 'Cloro emergencial', subtitulo: 'Controle o cloro usado fora da manutenção normal.', acao: FilledButton.icon(onPressed: _novaLista, icon: const Icon(Icons.add), label: const Text('Novo cloro emergencial'))),
      const SizedBox(height: 12), Row(children: [IconButton(onPressed: () { setState(() { _mes = DateTime(_mes.year, _mes.month - 1); _listas = _carregar(); }); }, icon: const Icon(Icons.chevron_left)), Text(_tituloMes, style: Theme.of(context).textTheme.titleMedium), IconButton(onPressed: () { setState(() { _mes = DateTime(_mes.year, _mes.month + 1); _listas = _carregar(); }); }, icon: const Icon(Icons.chevron_right))]),
      const SizedBox(height: 12), Expanded(child: FutureBuilder<List<dynamic>>(future: _listas, builder: (_, s) { if (s.hasError) return Center(child: Text('${s.error}')); if (!s.hasData) return const Center(child: CircularProgressIndicator()); final listas = s.data!; if (listas.isEmpty) return const Center(child: Text('Nenhum cloro emergencial neste mês.')); return ListView.separated(itemCount: listas.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, i) { final lista = listas[i] as Map<String, dynamic>; final usos = (lista['usos'] as List<dynamic>? ?? const []).length; return ListTile(leading: const Icon(Icons.science_outlined), title: Text('${(lista['cliente'] ?? {})['nome'] ?? ''}'), subtitle: Text('$usos registro(s) • ${_status(lista)}'), trailing: Text('${_numero(_totalKg(lista))} kg', style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () => _detalhar(lista)); }); }))
    ]),
  );
}
