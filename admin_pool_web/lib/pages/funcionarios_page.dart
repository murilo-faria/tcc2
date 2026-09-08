part of '../main.dart';

class _FuncionariosPageNova extends StatefulWidget {
  const _FuncionariosPageNova();
  @override State<_FuncionariosPageNova> createState() => _FuncionariosPageNovaState();
}

class _FuncionariosPageNovaState extends State<_FuncionariosPageNova> {
  late Future<List<dynamic>> _dados;
  String _busca = '';
  @override void initState() { super.initState(); _dados = _carregar(); }
  Future<List<dynamic>> _carregar() async {
    final r = await apiService.get('/api/funcionarios');
    if (r.statusCode != 200) throw Exception('Não foi possível carregar funcionários.');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<void> _formulario([Map<String, dynamic>? item]) async {
    final usuario = item?['usuario'] ?? {};
    final nome = TextEditingController(text: usuario['nome'] ?? '');
    final login = TextEditingController(text: usuario['login'] ?? '');
    final senha = TextEditingController();
    final telefone = TextEditingController(text: item?['telefone'] ?? '');
    final percentual = TextEditingController(text: '${item?['percentualMensalidade'] ?? 75}');
    final salvar = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(item == null ? 'Novo colaborador' : 'Alterar colaborador'),
      content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome *')),
        if (item == null) TextField(controller: login, decoration: const InputDecoration(labelText: 'Usuário de acesso *')),
        TextField(controller: senha, obscureText: true, decoration: InputDecoration(labelText: item == null ? 'Senha *' : 'Nova senha (opcional)')),
        TextField(controller: telefone, decoration: const InputDecoration(labelText: 'Telefone')),
        TextField(controller: percentual, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Percentual sobre recebimentos')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar'))],
    ));
    if (salvar != true) return;
    final body = {'nome': nome.text.trim(), 'telefone': telefone.text.trim(), 'percentualMensalidade': double.tryParse(percentual.text.replaceAll(',', '.')) ?? 75};
    final r = item == null
        ? await apiService.post('/api/funcionarios', body: {...body, 'login': login.text.trim(), 'senha': senha.text})
        : await apiService.put('/api/funcionarios/${item['id']}', body: {...body, 'novaSenha': senha.text});
    if (!mounted) return;
    if (r.statusCode >= 200 && r.statusCode < 300) setState(() => _dados = _carregar());
    else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível salvar (${r.statusCode}).')));
  }

  Future<void> _excluir(Map<String, dynamic> item) async {
    final usuario = item['usuario'] ?? {};
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Excluir colaborador?'), content: Text('As piscinas de ${usuario['nome']} ficarão sem responsável.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir'))]));
    if (ok != true) return;
    final r = await apiService.delete('/api/funcionarios/${item['id']}');
    if (!mounted) return;
    if (r.statusCode >= 200 && r.statusCode < 300) setState(() => _dados = _carregar());
    else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível excluir (${r.statusCode}).')));
  }

  @override Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CabecalhoResponsivo(titulo: 'Colaboradores', subtitulo: 'Cadastre os acessos e defina as piscinas de responsabilidade.', acao: FilledButton.icon(onPressed: () => _formulario(), icon: const Icon(Icons.add), label: const Text('Novo colaborador'))),
      const SizedBox(height: 18),
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Pesquisar colaborador ou usuário', border: OutlineInputBorder()), onChanged: (v) => setState(() => _busca = v.toLowerCase())),
      const SizedBox(height: 12),
      Expanded(child: FutureBuilder<List<dynamic>>(future: _dados, builder: (context, estado) {
        if (estado.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (estado.hasError) return Center(child: Text('${estado.error}'));
        final lista = estado.data!.where((f) { final u = f['usuario'] ?? {}; return '${u['nome']} ${u['login']}'.toLowerCase().contains(_busca); }).toList();
        if (lista.isEmpty) return const Center(child: Text('Nenhum colaborador encontrado.'));
        return Card(child: ListView.separated(itemCount: lista.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, i) { final f = lista[i] as Map<String, dynamic>; final u = f['usuario'] ?? {}; return ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(u['nome'] ?? ''), subtitle: Text('Usuário: ${u['login'] ?? ''} • ${f['telefone'] ?? 'sem telefone'}'), trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [Text('${f['percentualMensalidade'] ?? 75}%'), IconButton(tooltip: 'Alterar', icon: const Icon(Icons.edit_outlined), onPressed: () => _formulario(f)), IconButton(tooltip: 'Excluir', icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _excluir(f))])); }));
      }))
    ]));
  }
}
