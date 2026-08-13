import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final ValueNotifier<int> atualizacaoFinanceira = ValueNotifier<int>(0);
final ValueNotifier<int> atualizacaoOperacional = ValueNotifier<int>(0);
final ValueNotifier<int> atualizacaoClientes = ValueNotifier<int>(0);

String formatarMoeda(num valor) {
  final partes = valor.toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $inteiro,${partes[1]}';
}

String get referenciaAtual {
  final agora = DateTime.now();
  return '${agora.year}-${agora.month.toString().padLeft(2, '0')}';
}

Future<Map<String, dynamic>?> mostrarDialogPedidoMultiplo({
  required BuildContext context,
  required List<dynamic> produtos,
  required List<dynamic> clientes,
  int? clienteFixo,
  required String titulo,
}) async {
  int clienteId = clienteFixo ?? clientes.first['id'] as int;
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
                            (c) => DropdownMenuItem(
                              value: c['id'] as int,
                              child: Text(c['nome']),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => clienteId = v!),
                    ),
                  const SizedBox(height: 8),
                  ...List.generate(itens.length, (i) {
                    final item = itens[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: item['produtoId'],
                              decoration: InputDecoration(
                                labelText: 'Produto ${i + 1}',
                              ),
                              items: produtos
                                  .map<DropdownMenuItem<int>>(
                                    (p) => DropdownMenuItem(
                                      value: p['id'] as int,
                                      child: Text(
                                        '${p['nome']} — ${formatarMoeda(p['precoVenda'] as num)}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setLocal(() => item['produtoId'] = v!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 115,
                            child: TextFormField(
                              key: ValueKey('qtd-$i-${item['produtoId']}'),
                              initialValue: '${item['quantidade']}',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantidade',
                              ),
                              onChanged: (v) => setLocal(
                                () => item['quantidade'] = int.tryParse(v) ?? 1,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: itens.length == 1
                                ? null
                                : () => setLocal(() => itens.removeAt(i)),
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
              onPressed: () => Navigator.pop(context, {
                'clienteId': clienteId,
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

void main() => runApp(const AdminPoolApp());

class AdminPoolApp extends StatelessWidget {
  const AdminPoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Pool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          primary: const Color(0xFF1565C0),
          secondary: const Color(0xFF90CAF9),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAFF),
      ),
      home: const LoginPage(),
    );
  }
}

enum Perfil { gestor, funcionario }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Perfil perfil = Perfil.gestor;
  bool ocultarSenha = true;
  final usuarioController = TextEditingController();
  final senhaController = TextEditingController();

  void entrar() {
    final usuario = usuarioController.text.trim();
    final senha = senhaController.text;
    final valido =
        (perfil == Perfil.gestor &&
            usuario == 'gestorMurilo' &&
            senha == '1234') ||
        (perfil == Perfil.funcionario &&
            usuario == 'funcionario1' &&
            senha == '1234');
    if (!valido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário, senha ou perfil inválido.')),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(perfil: perfil)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.pool_rounded,
                      size: 64,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Admin Pool',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gestão inteligente de piscinas',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: usuarioController,
                      decoration: InputDecoration(
                        labelText: 'Usuário',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: senhaController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => entrar(),
                      obscureText: ocultarSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarSenha
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => ocultarSenha = !ocultarSenha),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<Perfil>(
                      segments: const [
                        ButtonSegment(
                          value: Perfil.gestor,
                          label: Text('Gestor'),
                          icon: Icon(Icons.admin_panel_settings_outlined),
                        ),
                        ButtonSegment(
                          value: Perfil.funcionario,
                          label: Text('Funcionário'),
                          icon: Icon(Icons.engineering_outlined),
                        ),
                      ],
                      selected: {perfil},
                      onSelectionChanged: (itens) =>
                          setState(() => perfil = itens.first),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: entrar,
                      icon: const Icon(Icons.login),
                      label: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Protótipo inicial: use qualquer e-mail e senha.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.perfil});
  final Perfil perfil;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pagina = 0;
  String get nomePerfil =>
      widget.perfil == Perfil.gestor ? 'Gestor' : 'Funcionário';
  List<_MenuItem> get menu => widget.perfil == Perfil.gestor
      ? const [
          _MenuItem('Visão geral', Icons.dashboard_outlined),
          _MenuItem('Funcionários', Icons.groups_outlined),
          _MenuItem('Clientes', Icons.people_outline),
          _MenuItem('Piscinas', Icons.pool_outlined),
          _MenuItem('Produtos', Icons.inventory_2_outlined),
          _MenuItem('Pedidos', Icons.shopping_cart_outlined),
          _MenuItem('Ordens de serviço', Icons.build_outlined),
          _MenuItem('Cobranças', Icons.receipt_long_outlined),
          _MenuItem('Salários', Icons.payments_outlined),
        ]
      : const [
          _MenuItem('Visão geral', Icons.dashboard_outlined),
          _MenuItem('Meus clientes', Icons.people_outline),
          _MenuItem('Piscinas', Icons.pool_outlined),
          _MenuItem('Produtos', Icons.inventory_2_outlined),
          _MenuItem('Pedidos', Icons.shopping_cart_outlined),
          _MenuItem('Ordens de serviço', Icons.build_outlined),
          _MenuItem('Meu salário', Icons.payments_outlined),
        ];

  @override
  Widget build(BuildContext context) {
    final compacta = MediaQuery.of(context).size.width < 850;
    final conteudo = _PageContent(
      titulo: menu[pagina].titulo,
      perfil: widget.perfil,
      inicio: pagina == 0,
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.pool_rounded),
            const SizedBox(width: 10),
            const Text('Admin Pool'),
          ],
        ),
        actions: [
          if (!compacta) Chip(label: Text(nomePerfil)),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: compacta
          ? Drawer(
              child: _Menu(
                menu: menu,
                pagina: pagina,
                aoSelecionar: (valor) {
                  setState(() => pagina = valor);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!compacta)
            SizedBox(
              width: 248,
              child: Material(
                color: Colors.white,
                child: _Menu(
                  menu: menu,
                  pagina: pagina,
                  aoSelecionar: (valor) => setState(() => pagina = valor),
                ),
              ),
            ),
          Expanded(child: conteudo),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.menu,
    required this.pagina,
    required this.aoSelecionar,
  });
  final List<_MenuItem> menu;
  final int pagina;
  final ValueChanged<int> aoSelecionar;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 16),
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Text(
          'MENU',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ),
      ...List.generate(
        menu.length,
        (i) => ListTile(
          selected: pagina == i,
          selectedTileColor: const Color(0xFFE3F2FD),
          leading: Icon(menu[i].icone),
          title: Text(menu[i].titulo),
          onTap: () => aoSelecionar(i),
        ),
      ),
    ],
  );
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.titulo,
    required this.perfil,
    required this.inicio,
  });
  final String titulo;
  final Perfil perfil;
  final bool inicio;
  @override
  Widget build(BuildContext context) {
    if (inicio) return _Dashboard(perfil: perfil);
    if (titulo == 'Clientes' || titulo == 'Meus clientes') {
      return const _ListaClientes();
    }
    if (titulo == 'Produtos')
      return _ProdutosGerenciamentoPage(gestor: perfil == Perfil.gestor);
    if (titulo == 'Pedidos') return const _PedidosPage();
    if (titulo == 'Ordens de serviço') return const _OrdensServicoPage();
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Módulo de $titulo do Admin Pool.'),
          const SizedBox(height: 28),
          Expanded(
            child: _TabelaModulo(
              titulo: titulo,
              gestor: perfil == Perfil.gestor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProdutosGerenciamentoPage extends StatefulWidget {
  const _ProdutosGerenciamentoPage({required this.gestor});
  final bool gestor;
  @override
  State<_ProdutosGerenciamentoPage> createState() =>
      _ProdutosGerenciamentoPageState();
}

class _ProdutosGerenciamentoPageState
    extends State<_ProdutosGerenciamentoPage> {
  late Future<List<dynamic>> produtos;
  String filtro = '';
  @override
  void initState() {
    super.initState();
    produtos = carregar();
  }

  Future<List<dynamic>> carregar() async {
    final r = await http.get(Uri.parse('http://localhost:8081/api/produtos'));
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar os produtos.');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<void> formulario([Map<String, dynamic>? produto]) async {
    final nome = TextEditingController(text: produto?['nome'] ?? '');
    final compra = TextEditingController(
      text: produto?['precoCompra']?.toString() ?? '',
    );
    final venda = TextEditingController(
      text: produto?['precoVenda']?.toString() ?? '',
    );
    final estoque = TextEditingController(
      text: produto?['estoque']?.toString() ?? '0',
    );
    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(produto == null ? 'Novo produto' : 'Editar produto'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: compra,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Preço de compra'),
              ),
              TextField(
                controller: venda,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Preço de venda'),
              ),
              TextField(
                controller: estoque,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Estoque'),
              ),
            ],
          ),
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
    );
    if (salvar != true || nome.text.trim().isEmpty) return;
    final corpo = jsonEncode({
      'nome': nome.text.trim(),
      'precoCompra': double.tryParse(compra.text.replaceAll(',', '.')) ?? 0,
      'precoVenda': double.tryParse(venda.text.replaceAll(',', '.')) ?? 0,
      'estoque': int.tryParse(estoque.text) ?? 0,
    });
    final uri = Uri.parse(
      'http://localhost:8081/api/produtos${produto == null ? '' : '/${produto['id']}'}',
    );
    final r = produto == null
        ? await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: corpo,
          )
        : await http.put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: corpo,
          );
    if (r.statusCode >= 200 && r.statusCode < 300)
      setState(() => produtos = carregar());
  }

  Future<void> excluir(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: const Text('O produto será removido do cadastro.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      final r = await http.delete(
        Uri.parse('http://localhost:8081/api/produtos/$id'),
      );
      if (r.statusCode >= 200 && r.statusCode < 300)
        setState(() => produtos = carregar());
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
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
                    'Produtos',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.gestor
                        ? 'Controle de preços e estoque.'
                        : 'Produtos disponíveis para os clientes.',
                  ),
                ],
              ),
            ),
            if (widget.gestor)
              FilledButton.icon(
                onPressed: () => formulario(),
                icon: const Icon(Icons.add),
                label: const Text('Novo produto'),
              ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Pesquisar produto',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => filtro = v.toLowerCase()),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: produtos,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (s.hasError) return Center(child: Text('${s.error}'));
              final dados = s.data!
                  .where(
                    (p) => (p['nome'] as String).toLowerCase().contains(filtro),
                  )
                  .toList();
              if (dados.isEmpty)
                return const Center(child: Text('Nenhum produto cadastrado.'));
              return Card(
                child: ListView.separated(
                  itemCount: dados.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = dados[i] as Map<String, dynamic>;
                    final mangueira = (p['nome'] as String)
                        .toLowerCase()
                        .contains('mangueira');
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.inventory_2_outlined),
                      ),
                      title: Text(p['nome']),
                      subtitle: Text(
                        '${mangueira ? 'Venda por metro' : 'Estoque: ${p['estoque']}'}${widget.gestor ? ' • Compra: ${formatarMoeda(p['precoCompra'] as num)}' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatarMoeda(p['precoVenda'] as num),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (widget.gestor)
                            IconButton(
                              onPressed: () => formulario(p),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          if (widget.gestor)
                            IconButton(
                              onPressed: () => excluir(p['id'] as int),
                              icon: const Icon(
                                Icons.delete_outline,
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

class _ListaProdutos extends StatefulWidget {
  const _ListaProdutos();
  @override
  State<_ListaProdutos> createState() => _ListaProdutosState();
}

class _ListaProdutosState extends State<_ListaProdutos> {
  late Future<List<dynamic>> produtos;
  @override
  void initState() {
    super.initState();
    produtos = carregar();
  }

  Future<List<dynamic>> carregar() async {
    final r = await http.get(Uri.parse('http://localhost:8081/api/produtos'));
    if (r.statusCode != 200) throw Exception('API indisponível');
    return jsonDecode(r.body) as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produtos',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Preço de venda para os clientes.'),
        const SizedBox(height: 18),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: produtos,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (s.hasError) return Text('${s.error}');
              return Card(
                child: ListView.separated(
                  itemCount: s.data!.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = s.data![i] as Map<String, dynamic>;
                    final venda = (p['precoVenda'] as num)
                        .toDouble()
                        .toStringAsFixed(2)
                        .replaceAll('.', ',');
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.inventory_2_outlined),
                      ),
                      title: Text(p['nome']),
                      subtitle: Text(
                        p['nome'].toString().contains('Mangueira')
                            ? 'Informe os metros ao fazer o pedido.'
                            : 'Estoque: ${p['estoque']}',
                      ),
                      trailing: Text(
                        'R\$ $venda',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

class _PedidosPage extends StatefulWidget {
  const _PedidosPage();
  @override
  State<_PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<_PedidosPage> {
  late Future<List<dynamic>> pedidos;
  String filtro = '';
  @override
  void initState() {
    super.initState();
    pedidos = carregar();
  }

  Future<List<dynamic>> getLista(String rota) async {
    final r = await http.get(Uri.parse('http://localhost:8081$rota'));
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar os dados.');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<List<dynamic>> carregar() => getLista('/api/pedidos-produto');
  Future<void> novoPedido() async {
    final clientes = await getLista('/api/clientes');
    final produtos = await getLista('/api/produtos');
    if (clientes.isEmpty || produtos.isEmpty || !mounted) return;
    final pedido = await mostrarDialogPedidoMultiplo(
      context: context,
      produtos: produtos,
      clientes: clientes,
      titulo: 'Novo pedido de produtos',
    );
    if (pedido != null) {
      final r = await http.post(
        Uri.parse('http://localhost:8081/api/pedidos-produto/lote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(pedido),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        atualizacaoOperacional.value++;
        atualizacaoFinanceira.value++;
        setState(() => pedidos = carregar());
      }
    }
  }

  Future<void> alternar(Map<String, dynamic> p) async {
    final anterior = p['status'];
    final novo = anterior == 'SOLICITADO' ? 'ENTREGUE' : 'SOLICITADO';
    setState(() => p['status'] = novo);
    final r = await http.put(
      Uri.parse(
        'http://localhost:8081/api/pedidos-produto/${p['id']}/status?status=$novo',
      ),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      setState(() => p['status'] = anterior);
    } else {
      atualizacaoOperacional.value++;
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
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
                    'Pedidos de produtos',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Pedidos lançados nas cobranças mensais dos clientes.',
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: novoPedido,
              icon: const Icon(Icons.add),
              label: const Text('Novo pedido'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Pesquisar cliente ou produto',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => filtro = v.toLowerCase()),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: pedidos,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (s.hasError) return Center(child: Text('${s.error}'));
              final dados = s.data!
                  .where(
                    (p) =>
                        (p['cliente']['nome'] as String).toLowerCase().contains(
                          filtro,
                        ) ||
                        (p['produto']['nome'] as String).toLowerCase().contains(
                          filtro,
                        ),
                  )
                  .toList();
              if (dados.isEmpty)
                return const Center(child: Text('Nenhum pedido cadastrado.'));
              return Card(
                child: ListView.separated(
                  itemCount: dados.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = dados[i] as Map<String, dynamic>;
                    final aberto = p['status'] == 'SOLICITADO';
                    final total =
                        (p['valorUnitario'] as num) * (p['quantidade'] as num);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (aberto ? Colors.orange : Colors.green)
                            .withValues(alpha: .16),
                        foregroundColor: aberto ? Colors.orange : Colors.green,
                        child: Icon(
                          aberto ? Icons.inventory_2_outlined : Icons.check,
                        ),
                      ),
                      title: Text(p['cliente']['nome']),
                      subtitle: Text(
                        '${p['produto']['nome']} • Quantidade: ${p['quantidade']} • ${p['dataPedido']}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatarMoeda(total),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Switch(
                            value: !aberto,
                            activeThumbColor: Colors.green,
                            onChanged: (_) => alternar(p),
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

class _OrdensServicoPage extends StatefulWidget {
  const _OrdensServicoPage();
  @override
  State<_OrdensServicoPage> createState() => _OrdensServicoPageState();
}

class _OrdensServicoPageState extends State<_OrdensServicoPage> {
  late Future<List<dynamic>> ordens;
  String filtro = '';
  @override
  void initState() {
    super.initState();
    ordens = carregar();
  }

  Future<List<dynamic>> carregar() async {
    final r = await http.get(
      Uri.parse('http://localhost:8081/api/ordens-servico'),
    );
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar as ordens.');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<List<dynamic>> buscar(String caminho) async {
    final r = await http.get(Uri.parse('http://localhost:8081$caminho'));
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<void> novaOrdem() async {
    final clientes = await buscar('/api/clientes');
    if (clientes.isEmpty || !mounted) return;
    int clienteId = clientes.first['id'] as int;
    List<dynamic> piscinas = await buscar('/api/piscinas/cliente/$clienteId');
    int? piscinaId = piscinas.isEmpty ? null : piscinas.first['id'] as int;
    final descricao = TextEditingController();
    final valor = TextEditingController(text: '0');
    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Nova ordem de serviço'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: clienteId,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    items: clientes
                        .map<DropdownMenuItem<int>>(
                          (c) => DropdownMenuItem(
                            value: c['id'] as int,
                            child: Text(c['nome']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      final ps = await buscar('/api/piscinas/cliente/$v');
                      setLocal(() {
                        clienteId = v!;
                        piscinas = ps;
                        piscinaId = ps.isEmpty ? null : ps.first['id'] as int;
                      });
                    },
                  ),
                  DropdownButtonFormField<int>(
                    key: ValueKey(clienteId),
                    initialValue: piscinaId,
                    decoration: const InputDecoration(
                      labelText: 'Piscina (opcional)',
                    ),
                    items: piscinas
                        .map<DropdownMenuItem<int>>(
                          (p) => DropdownMenuItem(
                            value: p['id'] as int,
                            child: Text(p['nome']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => piscinaId = v),
                  ),
                  TextField(
                    controller: descricao,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Detalhes do serviço',
                    ),
                  ),
                  TextField(
                    controller: valor,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor adicional',
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
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Criar OS'),
            ),
          ],
        ),
      ),
    );
    if (salvar == true && descricao.text.trim().isNotEmpty) {
      final r = await http.post(
        Uri.parse('http://localhost:8081/api/ordens-servico'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clienteId': clienteId,
          'piscinaId': piscinaId,
          'descricao': descricao.text.trim(),
          'dataServico': DateTime.now().toIso8601String().substring(0, 10),
          'valorAdicional':
              double.tryParse(valor.text.replaceAll(',', '.')) ?? 0,
        }),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        atualizacaoOperacional.value++;
        atualizacaoFinanceira.value++;
        setState(() => ordens = carregar());
      }
    }
  }

  Future<void> alternar(Map<String, dynamic> ordem) async {
    final anterior = ordem['status'];
    final novo = anterior == 'ABERTA' ? 'CONCLUIDA' : 'ABERTA';
    setState(() => ordem['status'] = novo);
    final r = await http.put(
      Uri.parse(
        'http://localhost:8081/api/ordens-servico/${ordem['id']}/status?status=$novo',
      ),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      setState(() => ordem['status'] = anterior);
    } else {
      atualizacaoOperacional.value++;
    }
  }

  Future<void> excluir(int id) async {
    await http.delete(
      Uri.parse('http://localhost:8081/api/ordens-servico/$id'),
    );
    atualizacaoOperacional.value++;
    setState(() => ordens = carregar());
  }

  @override
  Widget build(BuildContext context) => Padding(
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
                    'Ordens de serviço',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Acompanhe e registre os serviços dos clientes.'),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: novaOrdem,
              icon: const Icon(Icons.add),
              label: const Text('Nova OS'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Pesquisar cliente ou serviço',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => filtro = v.toLowerCase()),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: ordens,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (s.hasError) return Center(child: Text('${s.error}'));
              final dados = s.data!.where((o) {
                final cliente = (o['cliente']['nome'] as String).toLowerCase();
                final descricao = (o['descricao'] as String).toLowerCase();
                return cliente.contains(filtro) || descricao.contains(filtro);
              }).toList();
              if (dados.isEmpty)
                return const Center(child: Text('Nenhuma ordem de serviço.'));
              return Card(
                child: ListView.separated(
                  itemCount: dados.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final o = dados[i] as Map<String, dynamic>;
                    final aberta = o['status'] == 'ABERTA';
                    final cliente = o['cliente'] as Map<String, dynamic>;
                    final piscina = o['piscina'] as Map<String, dynamic>?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (aberta ? Colors.orange : Colors.green)
                            .withValues(alpha: .16),
                        foregroundColor: aberta ? Colors.orange : Colors.green,
                        child: Icon(
                          aberta ? Icons.build_outlined : Icons.check,
                        ),
                      ),
                      title: Text(cliente['nome']),
                      subtitle: Text(
                        '${o['descricao']}\n${piscina == null ? 'Sem piscina' : piscina['nome']} • ${o['dataServico']}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(formatarMoeda(o['valorAdicional'] as num)),
                          const SizedBox(width: 10),
                          Switch(
                            value: !aberta,
                            activeThumbColor: Colors.green,
                            onChanged: (_) => alternar(o),
                          ),
                          IconButton(
                            onPressed: () => excluir(o['id'] as int),
                            icon: const Icon(
                              Icons.delete_outline,
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

class _ListaClientes extends StatefulWidget {
  const _ListaClientes();
  @override
  State<_ListaClientes> createState() => _ListaClientesState();
}

class _ListaClientesState extends State<_ListaClientes> {
  late Future<List<dynamic>> clientes;
  String filtro = '';
  int? clienteSelecionado;
  @override
  void initState() {
    super.initState();
    clientes = carregar();
  }

  Future<List<dynamic>> carregar() async {
    final resposta = await http.get(
      Uri.parse('http://localhost:8081/api/clientes'),
    );
    if (resposta.statusCode != 200)
      throw Exception('Não foi possível carregar os clientes.');
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  Future<void> excluir(int id) async {
    await http.delete(Uri.parse('http://localhost:8081/api/clientes/$id'));
    atualizacaoClientes.value++;
    setState(() => clientes = carregar());
  }

  Future<void> cadastrar() async {
    final nome = TextEditingController();
    final telefone = TextEditingController();
    final endereco = TextEditingController();
    final valor = TextEditingController();
    final vencimento = TextEditingController(text: '10');

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo cliente'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nome,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                ),
                TextField(
                  controller: telefone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                TextField(
                  controller: endereco,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Endereço'),
                ),
                TextField(
                  controller: valor,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor da mensalidade *',
                    prefixText: 'R\$ ',
                  ),
                ),
                TextField(
                  controller: vencimento,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dia de vencimento *',
                    helperText: 'Informe um dia entre 1 e 31',
                  ),
                  onSubmitted: (_) => Navigator.pop(context, true),
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
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar cliente'),
          ),
        ],
      ),
    );

    if (salvar != true || !mounted) return;

    final mensalidade = double.tryParse(valor.text.replaceAll(',', '.'));
    final dia = int.tryParse(vencimento.text);
    if (nome.text.trim().isEmpty ||
        mensalidade == null ||
        mensalidade < 0 ||
        dia == null ||
        dia < 1 ||
        dia > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha nome, mensalidade e vencimento corretamente.',
          ),
        ),
      );
      return;
    }

    try {
      final resposta = await http.post(
        Uri.parse('http://localhost:8081/api/clientes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nome.text.trim(),
          'telefone': telefone.text.trim(),
          'endereco': endereco.text.trim(),
          'valorMensalidade': mensalidade,
          'diaVencimento': dia,
          'ativo': true,
        }),
      );
      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw Exception('Erro ${resposta.statusCode}');
      }
      if (!mounted) return;
      atualizacaoClientes.value++;
      atualizacaoFinanceira.value++;
      setState(() => clientes = carregar());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${nome.text.trim()} foi cadastrado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível cadastrar o cliente. Verifique a API.',
          ),
        ),
      );
    }
  }

  Future<void> editar(Map<String, dynamic> cliente) async {
    final nome = TextEditingController(text: cliente['nome']);
    final telefone = TextEditingController(text: cliente['telefone'] ?? '');
    final endereco = TextEditingController(text: cliente['endereco'] ?? '');
    final valor = TextEditingController(
      text: cliente['valorMensalidade'].toString(),
    );
    final vencimento = TextEditingController(
      text: cliente['diaVencimento'].toString(),
    );
    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: telefone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              TextField(
                controller: endereco,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Endereço'),
              ),
              TextField(
                controller: valor,
                decoration: const InputDecoration(labelText: 'Mensalidade'),
              ),
              TextField(
                controller: vencimento,
                decoration: const InputDecoration(
                  labelText: 'Dia de vencimento',
                ),
              ),
            ],
          ),
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
    );
    if (salvar == true) {
      cliente['nome'] = nome.text;
      cliente['telefone'] = telefone.text.trim();
      cliente['endereco'] = endereco.text.trim();
      cliente['valorMensalidade'] = double.parse(
        valor.text.replaceAll(',', '.'),
      );
      cliente['diaVencimento'] = int.parse(vencimento.text);
      await http.put(
        Uri.parse('http://localhost:8081/api/clientes/${cliente['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cliente),
      );
      atualizacaoClientes.value++;
      setState(() => clientes = carregar());
    }
  }

  Future<List<dynamic>> _buscar(String caminho) async {
    final r = await http.get(Uri.parse('http://localhost:8081$caminho'));
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar os dados.');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<void> abrirPiscinas(Map<String, dynamic> cliente) async {
    final nome = TextEditingController();
    final tipo = TextEditingController();
    final volume = TextEditingController();
    final existentes = await _buscar('/api/piscinas/cliente/${cliente['id']}');
    if (!mounted) return;
    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Piscinas — ${cliente['nome']}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existentes.isEmpty)
                  const ListTile(title: Text('Nenhuma piscina cadastrada.')),
                ...existentes.map(
                  (p) => ListTile(
                    leading: const Icon(Icons.pool),
                    title: Text(p['nome']),
                    subtitle: Text(
                      '${p['tipo'] ?? ''} • ${p['volumeLitros'] ?? 0} litros',
                    ),
                  ),
                ),
                const Divider(),
                TextField(
                  controller: nome,
                  decoration: const InputDecoration(
                    labelText: 'Nome da piscina',
                  ),
                ),
                TextField(
                  controller: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                TextField(
                  controller: volume,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Volume em litros',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cadastrar piscina'),
          ),
        ],
      ),
    );
    if (salvar == true && nome.text.trim().isNotEmpty) {
      await http.post(
        Uri.parse('http://localhost:8081/api/piscinas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clienteId': cliente['id'],
          'nome': nome.text.trim(),
          'tipo': tipo.text.trim(),
          'volumeLitros': int.tryParse(volume.text) ?? 0,
          'observacoes': '',
        }),
      );
      atualizacaoOperacional.value++;
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Piscina cadastrada.')));
    }
  }

  Future<void> abrirOrdemServico(Map<String, dynamic> cliente) async {
    final piscinas = await _buscar('/api/piscinas/cliente/${cliente['id']}');
    final descricao = TextEditingController();
    final valor = TextEditingController(text: '0');
    int? piscinaId = piscinas.isEmpty ? null : piscinas.first['id'] as int;
    if (!mounted) return;
    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Nova ordem de serviço — ${cliente['nome']}'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: piscinaId,
                  decoration: const InputDecoration(labelText: 'Piscina'),
                  items: piscinas
                      .map<DropdownMenuItem<int>>(
                        (p) => DropdownMenuItem(
                          value: p['id'] as int,
                          child: Text(p['nome']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => piscinaId = v),
                ),
                TextField(
                  controller: descricao,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'O que deve ser feito',
                  ),
                ),
                TextField(
                  controller: valor,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor adicional',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Criar OS'),
            ),
          ],
        ),
      ),
    );
    if (salvar == true && descricao.text.trim().isNotEmpty) {
      await http.post(
        Uri.parse('http://localhost:8081/api/ordens-servico'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clienteId': cliente['id'],
          'piscinaId': piscinaId,
          'descricao': descricao.text.trim(),
          'dataServico': DateTime.now().toIso8601String().substring(0, 10),
          'valorAdicional':
              double.tryParse(valor.text.replaceAll(',', '.')) ?? 0,
        }),
      );
      atualizacaoOperacional.value++;
      atualizacaoFinanceira.value++;
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ordem de serviço criada.')),
        );
    }
  }

  Future<void> abrirPedido(Map<String, dynamic> cliente) async {
    final produtos = await _buscar('/api/produtos');
    if (produtos.isEmpty || !mounted) return;
    final pedido = await mostrarDialogPedidoMultiplo(
      context: context,
      produtos: produtos,
      clientes: [cliente],
      clienteFixo: cliente['id'] as int,
      titulo: 'Novo pedido — ${cliente['nome']}',
    );
    if (pedido != null) {
      final r = await http.post(
        Uri.parse('http://localhost:8081/api/pedidos-produto/lote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(pedido),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        atualizacaoOperacional.value++;
        atualizacaoFinanceira.value++;
      }
      if (mounted && r.statusCode >= 200 && r.statusCode < 300)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido com todos os produtos salvo na cobrança.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clientes',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Clientes cadastrados no banco Admin_Poll.'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: cadastrar,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Novo cliente'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Pesquisar cliente',
            border: OutlineInputBorder(),
          ),
          onChanged: (texto) => setState(() => filtro = texto.toLowerCase()),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: clientes,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(
                  child: Text(
                    'Inicie a API Java para exibir a lista.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              final dados = snapshot.data!
                  .where(
                    (c) =>
                        (c['nome'] as String).toLowerCase().contains(filtro) ||
                        (c['telefone'] ?? '').toString().toLowerCase().contains(
                          filtro,
                        ),
                  )
                  .toList();
              if (dados.isEmpty)
                return const Center(child: Text('Nenhum cliente cadastrado.'));
              return Card(
                child: ListView.separated(
                  itemCount: dados.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final cliente = dados[i] as Map<String, dynamic>;
                    final valor = (cliente['valorMensalidade'] ?? 0)
                        .toString()
                        .replaceAll('.', ',');
                    final dia = cliente['diaVencimento'] == null
                        ? 'Vencimento não informado'
                        : 'Vence dia ${cliente['diaVencimento']}';
                    final selecionado = clienteSelecionado == cliente['id'];
                    return Column(
                      children: [
                        ListTile(
                          onTap: () => setState(
                            () => clienteSelecionado = selecionado
                                ? null
                                : cliente['id'] as int,
                          ),
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(cliente['nome'] ?? ''),
                          subtitle: Text(
                            [
                              dia,
                              if ((cliente['telefone'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                cliente['telefone'],
                              if ((cliente['endereco'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                cliente['endereco'],
                              'Clique para abrir os serviços',
                            ].join(' • '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'R\$ $valor',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => editar(cliente),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => excluir(cliente['id'] as int),
                              ),
                              Icon(
                                selecionado
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                            ],
                          ),
                        ),
                        if (selecionado)
                          Container(
                            color: const Color(0xFFE3F2FD),
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => abrirPiscinas(cliente),
                                    icon: const Icon(Icons.pool_outlined),
                                    label: const Text('Piscinas'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => abrirOrdemServico(cliente),
                                    icon: const Icon(Icons.build_outlined),
                                    label: const Text('Ordem de serviço'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => abrirPedido(cliente),
                                    icon: const Icon(
                                      Icons.shopping_cart_outlined,
                                    ),
                                    label: const Text('Produtos'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.perfil});
  final Perfil perfil;
  @override
  Widget build(BuildContext context) {
    final gestor = perfil == Perfil.gestor;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          'Olá, ${gestor ? 'Gestor' : 'João'}!',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text('Acompanhe o resumo deste mês.'),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: gestor
              ? [
                  const _ContagemResumoCard(tipo: _TipoContagem.clientes),
                  const _ContagemResumoCard(tipo: _TipoContagem.cobrancas),
                  const _FaturamentoCard(),
                  const _FluxoCaixaCard(),
                  const _NotificacaoOperacionalCard(
                    tipo: _TipoNotificacao.produto,
                  ),
                  const _NotificacaoOperacionalCard(
                    tipo: _TipoNotificacao.ordemServico,
                  ),
                ]
              : [
                  _Indicador(
                    'Meus clientes',
                    '10',
                    Icons.people_outline,
                    Color(0xFF1565C0),
                  ),
                  _Indicador(
                    'Serviços hoje',
                    '3',
                    Icons.build_outlined,
                    Color(0xFFF4A261),
                  ),
                  _Indicador(
                    'Pedidos em aberto',
                    '2',
                    Icons.shopping_cart_outlined,
                    Color(0xFFE76F51),
                  ),
                  _Indicador(
                    'Salário previsto',
                    'R\$ 1.875,00',
                    Icons.payments_outlined,
                    Color(0xFF1976D2),
                  ),
                ],
        ),
        const SizedBox(height: 32),
        Text(
          gestor ? 'Cobranças do mês' : 'Próximos serviços',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        gestor
            ? const _CobrancasDoMes()
            : Card(
                child: Column(
                  children: gestor
                      ? const [
                          ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title: Text('Condomínio Jardim'),
                            subtitle: Text('Referência: Julho/2026'),
                            trailing: Text(
                              'R\$ 480,00\nPendente',
                              textAlign: TextAlign.end,
                            ),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title: Text('Residência Oliveira'),
                            subtitle: Text('Referência: Julho/2026'),
                            trailing: Text(
                              'R\$ 250,00\nPago',
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ]
                      : const [
                          ListTile(
                            leading: CircleAvatar(child: Icon(Icons.pool)),
                            title: Text('Condomínio Jardim — Piscina adulto'),
                            subtitle: Text(
                              'Hoje, 08:00 • Manutenção preventiva',
                            ),
                            trailing: Icon(Icons.chevron_right),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: CircleAvatar(child: Icon(Icons.pool)),
                            title: Text(
                              'Residência Oliveira — Piscina principal',
                            ),
                            subtitle: Text('Hoje, 14:00 • Limpeza e análise'),
                            trailing: Icon(Icons.chevron_right),
                          ),
                        ],
                ),
              ),
      ],
    );
  }
}

class _CobrancasDoMes extends StatefulWidget {
  const _CobrancasDoMes();
  @override
  State<_CobrancasDoMes> createState() => _CobrancasDoMesState();
}

class _CobrancasDoMesState extends State<_CobrancasDoMes> {
  late Future<List<dynamic>> cobrancas;
  @override
  void initState() {
    super.initState();
    cobrancas = carregar();
  }

  Future<List<dynamic>> carregar() async {
    final r = await http.get(Uri.parse('http://localhost:8081/api/cobrancas'));
    if (r.statusCode != 200) throw Exception('API indisponível');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<void> pagar(Map<String, dynamic> c) async {
    final pago = c['status'] == 'PAGO';
    final statusAnterior = c['status'] as String;
    final vencimento = DateTime.parse(c['vencimento'] as String);
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final novoStatus = pago
        ? (vencimento.isBefore(hojeSemHora) ? 'VENCIDO' : 'PENDENTE')
        : 'PAGO';

    // Atualização otimista: o botão e a posição mudam imediatamente.
    setState(() => c['status'] = novoStatus);

    final url = pago
        ? 'http://localhost:8081/api/cobrancas/${c['id']}/reabrir'
        : 'http://localhost:8081/api/cobrancas/${c['id']}/baixar?valor=${c['total']}';
    try {
      final resposta = await http.put(Uri.parse(url));
      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw Exception('Falha ao atualizar pagamento.');
      }
      atualizacaoFinanceira.value++;
    } catch (erro) {
      if (!mounted) return;
      setState(() => c['status'] = statusAnterior);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $erro')));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: cobrancas,
    builder: (context, s) {
      if (s.connectionState != ConnectionState.done)
        return const Center(child: CircularProgressIndicator());
      if (s.hasError) return Text('${s.error}');
      final lista = [...s.data!];
      const ordem = {'VENCIDO': 0, 'PENDENTE': 1, 'PAGO': 2};
      lista.sort((a, b) {
        final porStatus = (ordem[a['status']] ?? 9).compareTo(
          ordem[b['status']] ?? 9,
        );
        if (porStatus != 0) return porStatus;
        final porData = (a['vencimento'] as String).compareTo(
          b['vencimento'] as String,
        );
        if (porData != 0) return porData;
        return (a['cliente']['nome'] as String).compareTo(
          b['cliente']['nome'] as String,
        );
      });
      return Card(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final c = lista[i] as Map<String, dynamic>;
            final status = c['status'] as String;
            final cor = status == 'PAGO'
                ? Colors.green
                : status == 'VENCIDO'
                ? Colors.red
                : Colors.amber;
            final cliente = c['cliente'] as Map<String, dynamic>;
            final valor = formatarMoeda(c['total'] as num);
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: cor.withValues(alpha: .16),
                foregroundColor: cor,
                child: const Icon(Icons.person),
              ),
              title: Text(cliente['nome']),
              subtitle: Text('Vencimento: ${c['vencimento']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(valor),
                  const SizedBox(width: 12),
                  Switch(
                    value: status == 'PAGO',
                    activeColor: Colors.green,
                    onChanged: (_) => pagar(c),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _FaturamentoCard extends StatelessWidget {
  const _FaturamentoCard();
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: atualizacaoFinanceira,
    builder: (_, __, ___) => _TotalFinanceiroCard(
      titulo: 'Faturamento previsto',
      incluir: (c) =>
          c['referencia'] == referenciaAtual && c['status'] != 'PAGO',
      icone: Icons.payments_outlined,
      cor: const Color(0xFF1976D2),
    ),
  );
}

class _FluxoCaixaCard extends StatelessWidget {
  const _FluxoCaixaCard();
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: atualizacaoFinanceira,
    builder: (_, __, ___) => _TotalFinanceiroCard(
      titulo: 'Fluxo de caixa',
      incluir: (c) =>
          c['referencia'] == referenciaAtual && c['status'] == 'PAGO',
      icone: Icons.account_balance_wallet_outlined,
      cor: const Color(0xFF2E7D32),
    ),
  );
}

class _TotalFinanceiroCard extends StatelessWidget {
  const _TotalFinanceiroCard({
    required this.titulo,
    required this.incluir,
    required this.icone,
    required this.cor,
  });
  final String titulo;
  final bool Function(Map<String, dynamic>) incluir;
  final IconData icone;
  final Color cor;
  @override
  Widget build(BuildContext context) => FutureBuilder<http.Response>(
    future: http.get(Uri.parse('http://localhost:8081/api/cobrancas')),
    builder: (context, snapshot) {
      var total = 0.0;
      if (snapshot.hasData && snapshot.data!.statusCode == 200) {
        final lista = jsonDecode(snapshot.data!.body) as List<dynamic>;
        total = lista
            .cast<Map<String, dynamic>>()
            .where(incluir)
            .fold<double>(
              0,
              (soma, c) => soma + (c['total'] as num).toDouble(),
            );
      }
      return _Indicador(
        titulo,
        snapshot.connectionState == ConnectionState.waiting
            ? 'Calculando...'
            : formatarMoeda(total),
        icone,
        cor,
      );
    },
  );
}

enum _TipoContagem { clientes, cobrancas }

class _ContagemResumoCard extends StatelessWidget {
  const _ContagemResumoCard({required this.tipo});
  final _TipoContagem tipo;
  Future<int> carregar() async {
    final rota = tipo == _TipoContagem.clientes
        ? '/api/clientes'
        : '/api/cobrancas';
    final r = await http.get(Uri.parse('http://localhost:8081$rota'));
    if (r.statusCode != 200) return 0;
    final lista = jsonDecode(r.body) as List<dynamic>;
    if (tipo == _TipoContagem.clientes) {
      return lista.where((c) => c['ativo'] != false).length;
    }
    return lista
        .where(
          (c) => c['referencia'] == referenciaAtual && c['status'] != 'PAGO',
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final atualizacao = tipo == _TipoContagem.clientes
        ? atualizacaoClientes
        : atualizacaoFinanceira;
    return ValueListenableBuilder<int>(
      valueListenable: atualizacao,
      builder: (_, __, ___) => FutureBuilder<int>(
        future: carregar(),
        builder: (context, s) => _Indicador(
          tipo == _TipoContagem.clientes
              ? 'Clientes ativos'
              : 'Cobranças pendentes',
          s.connectionState == ConnectionState.waiting
              ? '...'
              : '${s.data ?? 0}',
          tipo == _TipoContagem.clientes
              ? Icons.people_outline
              : Icons.warning_amber_rounded,
          tipo == _TipoContagem.clientes
              ? const Color(0xFF1565C0)
              : const Color(0xFFE76F51),
        ),
      ),
    );
  }
}

enum _TipoNotificacao { produto, ordemServico }

class _NotificacaoOperacionalCard extends StatelessWidget {
  const _NotificacaoOperacionalCard({required this.tipo});
  final _TipoNotificacao tipo;

  String get titulo => tipo == _TipoNotificacao.produto
      ? 'Pedidos de produtos'
      : 'Ordens de serviço';
  String get endpoint => tipo == _TipoNotificacao.produto
      ? '/api/pedidos-produto/abertos'
      : '/api/ordens-servico/abertas';
  IconData get icone => tipo == _TipoNotificacao.produto
      ? Icons.inventory_2_outlined
      : Icons.build_outlined;
  Color get cor => tipo == _TipoNotificacao.produto
      ? const Color(0xFF7B1FA2)
      : const Color(0xFFF57C00);

  Future<List<dynamic>> carregar() async {
    final r = await http.get(Uri.parse('http://localhost:8081$endpoint'));
    if (r.statusCode != 200) return [];
    return jsonDecode(r.body) as List<dynamic>;
  }

  void mostrar(BuildContext context, List<dynamic> itens) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 580,
          height: 420,
          child: itens.isEmpty
              ? const Center(child: Text('Nenhuma pendência.'))
              : ListView.separated(
                  itemCount: itens.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) {
                    final item = itens[i] as Map<String, dynamic>;
                    final cliente =
                        (item['cliente'] as Map<String, dynamic>)['nome'];
                    final detalhe = tipo == _TipoNotificacao.produto
                        ? '${(item['produto'] as Map<String, dynamic>)['nome']} • Quantidade: ${item['quantidade']}'
                        : item['descricao'].toString();
                    return ListTile(
                      leading: Icon(icone, color: cor),
                      title: Text(cliente),
                      subtitle: Text(detalhe),
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
    valueListenable: atualizacaoOperacional,
    builder: (_, __, ___) => FutureBuilder<List<dynamic>>(
      future: carregar(),
      builder: (context, snapshot) {
        final itens = snapshot.data ?? const <dynamic>[];
        final quantidade = itens.length;
        return SizedBox(
          width: 230,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => mostrar(context, itens),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          backgroundColor: cor.withValues(alpha: .14),
                          foregroundColor: cor,
                          child: Icon(icone),
                        ),
                        if (quantidade > 0)
                          Positioned(
                            right: -8,
                            top: -10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$quantidade',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$quantidade ${quantidade == 1 ? 'pendência' : 'pendências'}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
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

class _Indicador extends StatelessWidget {
  const _Indicador(this.titulo, this.valor, this.icone, this.cor);
  final String titulo, valor;
  final IconData icone;
  final Color cor;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 230,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cor.withValues(alpha: .14),
              foregroundColor: cor,
              child: Icon(icone),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    valor,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TabelaModulo extends StatelessWidget {
  const _TabelaModulo({required this.titulo, required this.gestor});
  final String titulo;
  final bool gestor;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Registros de $titulo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (gestor)
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Novo'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(
              'Este módulo está pronto para receber a integração com a API Java.',
            ),
            subtitle: Text(
              'Os dados reais serão carregados do Spring Boot e PostgreSQL.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _MenuItem {
  const _MenuItem(this.titulo, this.icone);
  final String titulo;
  final IconData icone;
}
