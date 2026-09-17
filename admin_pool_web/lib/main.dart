import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'core/atualizadores.dart';
import 'core/formatadores.dart';
import 'models/perfil.dart';
import 'services/api_service.dart';
import 'widgets/dialogo_pedido_multiplo.dart';

part 'pages/login_page.dart';
part 'pages/gestao_pages.dart';
part 'pages/funcionarios_page.dart';
part 'pages/cobrancas_page.dart';
part 'pages/pedidos_page.dart';
part 'pages/ordens_servico_page.dart';
part 'pages/salarios_page.dart';

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
        dialogTheme: const DialogThemeData(
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAFF),
      ),
      home: const LoginPage(),
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
      widget.perfil == Perfil.gestor ? 'Gestor' : 'Colaborador';
  List<_MenuItem> get menu => widget.perfil == Perfil.gestor
      ? const [
          _MenuItem('Visão geral', Icons.dashboard_outlined),
          _MenuItem('Colaboradores', Icons.groups_outlined),
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
          _MenuItem('Clientes', Icons.people_outline),
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
            onPressed: () {
              apiService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
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
      body: SafeArea(
        child: Row(
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

class _CabecalhoResponsivo extends StatelessWidget {
  const _CabecalhoResponsivo({
    required this.titulo,
    required this.subtitulo,
    this.acao,
  });
  final String titulo;
  final String subtitulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final estreito = MediaQuery.of(context).size.width < 600;
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(subtitulo),
      ],
    );
    if (estreito) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          textos,
          if (acao != null) const SizedBox(height: 14),
          if (acao != null)
            Align(alignment: Alignment.centerLeft, child: acao!),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: textos),
        if (acao != null) acao!,
      ],
    );
  }
}

class _FiltrosRelatorio extends StatelessWidget {
  const _FiltrosRelatorio({
    required this.clientes,
    required this.meses,
    required this.clienteSelecionado,
    required this.mesSelecionado,
    required this.dataInicial,
    required this.dataFinal,
    required this.aoMudarCliente,
    required this.aoMudarMes,
    required this.aoEscolherData,
    required this.aoLimpar,
  });
  final List<String> clientes;
  final List<String> meses;
  final String? clienteSelecionado;
  final String? mesSelecionado;
  final DateTime? dataInicial;
  final DateTime? dataFinal;
  final ValueChanged<String?> aoMudarCliente;
  final ValueChanged<String?> aoMudarMes;
  final ValueChanged<bool> aoEscolherData;
  final VoidCallback aoLimpar;
  String _data(DateTime? valor, String vazio) => valor == null
      ? vazio
      : '${valor.day.toString().padLeft(2, '0')}/${valor.month.toString().padLeft(2, '0')}/${valor.year}';
  @override
  Widget build(BuildContext context) {
    final celular = MediaQuery.of(context).size.width < 600;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: celular ? 160 : 220,
          child: DropdownButtonFormField<String>(
            value: clienteSelecionado,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Cliente',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Todos os clientes'),
              ),
              ...clientes.map(
                (nome) => DropdownMenuItem(
                  value: nome,
                  child: Text(nome, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: aoMudarCliente,
          ),
        ),
        SizedBox(
          width: celular ? 140 : 180,
          child: DropdownButtonFormField<String>(
            value: mesSelecionado,
            decoration: const InputDecoration(
              labelText: 'Mês',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Todos os meses'),
              ),
              ...meses.map(
                (mes) => DropdownMenuItem(value: mes, child: Text(mes)),
              ),
            ],
            onChanged: aoMudarMes,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => aoEscolherData(true),
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(_data(dataInicial, 'Data inicial')),
        ),
        OutlinedButton.icon(
          onPressed: () => aoEscolherData(false),
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(_data(dataFinal, 'Data final')),
        ),
        TextButton.icon(
          onPressed: aoLimpar,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Limpar filtros'),
        ),
      ],
    );
  }
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
    if (titulo == 'Clientes') {
      return _ListaClientes(gestor: perfil == Perfil.gestor);
    }
    if (titulo == 'Produtos')
      return _ProdutosGerenciamentoPage(gestor: perfil == Perfil.gestor);
    if (titulo == 'Colaboradores') return const _FuncionariosPageNova();
    if (titulo == 'Piscinas')
      return _PiscinasPage(gestor: perfil == Perfil.gestor);
    if (titulo == 'Cobranças') return const _CobrancasPageNova();
    if (titulo == 'Salários' || titulo == 'Meu salário')
      return _SalariosPageNova(gestor: perfil == Perfil.gestor);
    if (titulo == 'Pedidos')
      return _PedidosPageNova(gestor: perfil == Perfil.gestor);
    if (titulo == 'Ordens de serviço')
      return _OrdensServicoPageNova(gestor: perfil == Perfil.gestor);
    return Padding(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width < 600 ? 16 : 28,
      ),
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
    final r = await apiService.get('/api/produtos');
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
    });
    final rota = '/api/produtos${produto == null ? '' : '/${produto['id']}'}';
    final r = produto == null
        ? await apiService.post(rota, body: corpo)
        : await apiService.put(rota, body: corpo);
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
      final r = await apiService.delete('/api/produtos/$id');
      if (r.statusCode >= 200 && r.statusCode < 300)
        setState(() => produtos = carregar());
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CabecalhoResponsivo(
          titulo: 'Produtos',
          subtitulo: widget.gestor
              ? 'Nome e preços de compra e venda.'
              : 'Produtos disponíveis para os clientes.',
          acao: widget.gestor
              ? FilledButton.icon(
                  onPressed: () => formulario(),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo produto'),
                )
              : null,
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
                    final celular = MediaQuery.of(context).size.width < 600;
                    final mangueira = (p['nome'] as String)
                        .toLowerCase()
                        .contains('mangueira');
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.inventory_2_outlined),
                      ),
                      titleAlignment: ListTileTitleAlignment.bottom,
                      title: Text(
                        p['nome'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: Text(
                        '${mangueira ? 'Venda por metro' : 'Venda: ${formatarMoeda(p['precoVenda'] as num)}'}${widget.gestor ? ' • Compra: ${formatarMoeda(p['precoCompra'] as num)}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!celular)
                            Text(
                              formatarMoeda(p['precoVenda'] as num),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
    final r = await apiService.get('/api/produtos');
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
                            : 'Produto vendido por encomenda',
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
    final r = await apiService.get(rota);
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar os dados.');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<List<dynamic>> carregar() => getLista('/api/pedidos-produto');
  Future<void> novoPedido() async {
    final clientes = await getLista('/api/clientes');
    final produtos = await getLista('/api/produtos');
    final piscinas = await getLista('/api/piscinas');
    if (clientes.isEmpty || produtos.isEmpty || !mounted) return;
    final pedido = await mostrarDialogPedidoMultiplo(
      context: context,
      produtos: produtos,
      clientes: clientes,
      piscinas: piscinas,
      titulo: 'Novo pedido de produtos',
    );
    if (pedido != null) {
      final r = await apiService.post(
        '/api/pedidos-produto/lote',
        body: pedido,
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
    final r = await apiService.put(
      '/api/pedidos-produto/${p['id']}/status?status=$novo',
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      setState(() => p['status'] = anterior);
    } else {
      atualizacaoOperacional.value++;
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CabecalhoResponsivo(
          titulo: 'Pedidos de produtos',
          subtitulo: 'Pedidos lançados nas cobranças mensais dos clientes.',
          acao: FilledButton.icon(
            onPressed: novoPedido,
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
                        '${p['produto']['nome']} • Quantidade: ${p['quantidade']} • ${p['dataPedido']}\n'
                        'Endereço: ${(p['piscina']?['endereco'] ?? p['cliente']?['endereco'] ?? 'A informar')}',
                      ),
                      isThreeLine: true,
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
    final r = await apiService.get('/api/ordens-servico');
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar as ordens.');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<List<dynamic>> buscar(String caminho) async {
    final r = await apiService.get(caminho);
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<void> novaOrdem() async {
    final clientes = await buscar('/api/clientes');
    if (clientes.isEmpty || !mounted) return;
    int clienteId = clientes.first['id'] as int;
    List<dynamic> piscinas = await buscar('/api/piscinas/cliente/$clienteId');
    int? piscinaId = piscinas.length == 1 ? piscinas.first['id'] as int : null;
    final descricao = TextEditingController();
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
                        piscinaId = ps.length == 1
                            ? ps.first['id'] as int
                            : null;
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
                  if (piscinaId != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Endereço: ${(piscinas.firstWhere((p) => p['id'] == piscinaId)['endereco'] ?? 'A informar')}',
                        ),
                      ),
                    ),
                  TextField(
                    controller: descricao,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Detalhes do serviço',
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
      final r = await apiService.post(
        '/api/ordens-servico',
        body: {
          'clienteId': clienteId,
          'piscinaId': piscinaId,
          'descricao': descricao.text.trim(),
          'dataServico': DateTime.now().toIso8601String().substring(0, 10),
        },
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
    final r = await apiService.put(
      '/api/ordens-servico/${ordem['id']}/status?status=$novo',
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      setState(() => ordem['status'] = anterior);
    } else {
      atualizacaoOperacional.value++;
    }
  }

  Future<void> excluir(int id) async {
    await apiService.delete('/api/ordens-servico/$id');
    atualizacaoOperacional.value++;
    setState(() => ordens = carregar());
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CabecalhoResponsivo(
          titulo: 'Ordens de serviço',
          subtitulo: 'Acompanhe e registre os serviços dos clientes.',
          acao: FilledButton.icon(
            onPressed: novaOrdem,
            icon: const Icon(Icons.add),
            label: const Text('Nova OS'),
          ),
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
                        '${o['descricao']}\n${piscina == null ? 'Sem piscina' : piscina['nome']} • ${o['dataServico']}\nEndereço: ${(piscina?['endereco'] ?? cliente['endereco'] ?? 'A informar')}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
  const _ListaClientes({required this.gestor});
  final bool gestor;
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
    if (!widget.gestor) {
      final respostaPiscinas = await apiService.get('/api/piscinas');
      if (respostaPiscinas.statusCode != 200) return const [];
      final piscinas = jsonDecode(respostaPiscinas.body) as List<dynamic>;
      final clientes = <int, dynamic>{};
      for (final piscina in piscinas) {
        final cliente = piscina['cliente'];
        if (cliente != null) {
          final clienteComResponsavel = Map<String, dynamic>.from(cliente as Map);
          clienteComResponsavel['_responsavel'] = piscina['responsavel'];
          clientes[cliente['id'] as int] = clienteComResponsavel;
        }
      }
      return clientes.values.toList();
    }
    final resposta = await apiService.get('/api/clientes');
    if (resposta.statusCode != 200)
      throw Exception('Não foi possível carregar os clientes.');
    final respostaPiscinas = await apiService.get('/api/piscinas');
    if (respostaPiscinas.statusCode != 200) return const [];
    final responsavelPorCliente = <int, dynamic>{};
    for (final piscina in jsonDecode(respostaPiscinas.body) as List<dynamic>) {
      final cliente = piscina['cliente'];
      final responsavel = piscina['responsavel'];
      if (cliente != null && responsavel != null) {
        responsavelPorCliente.putIfAbsent(cliente['id'] as int, () => responsavel);
      }
    }
    return (jsonDecode(resposta.body) as List<dynamic>).map((item) {
      final cliente = Map<String, dynamic>.from(item as Map);
      cliente['_responsavel'] = responsavelPorCliente[cliente['id'] as int];
      return cliente;
    }).toList();
  }

  Color _corResponsavel(dynamic responsavel) {
    const cores = [Colors.blue, Colors.green, Colors.orange, Colors.deepPurple, Colors.teal];
    final id = responsavel is Map ? responsavel['id'] as int? : null;
    return id == null ? Colors.blue : cores[id % cores.length];
  }

  Future<void> excluir(int id) async {
    await apiService.delete('/api/clientes/$id');
    atualizacaoClientes.value++;
    setState(() => clientes = carregar());
  }

  Future<void> cadastrar() async {
    final nome = TextEditingController();
    final telefone = TextEditingController();
    final endereco = TextEditingController();
    final valor = TextEditingController();
    final vencimento = TextEditingController(text: '10');
    final piscinaNome = TextEditingController(text: 'Piscina principal');
    final piscinaTipo = TextEditingController();
    final piscinaVolume = TextEditingController();
    final piscinaEndereco = TextEditingController();
    final respostaFuncionarios = await apiService.get('/api/funcionarios');
    final funcionarios = respostaFuncionarios.statusCode == 200
        ? jsonDecode(respostaFuncionarios.body) as List<dynamic>
        : <dynamic>[];
    if (!mounted) return;
    String inicioCobranca = 'PROXIMO_MES';
    DateTime? dataPersonalizada;
    int? responsavelId;
    String? diaAtendimento;

    DateTime vencimentoCalculado() {
      if (inicioCobranca == 'PERSONALIZADO' && dataPersonalizada != null) {
        return dataPersonalizada!;
      }
      final hoje = DateTime.now();
      final mesBase = inicioCobranca == 'MES_ATUAL'
          ? DateTime(hoje.year, hoje.month)
          : DateTime(hoje.year, hoje.month + 1);
      final dia = int.tryParse(vencimento.text) ?? 10;
      final ultimoDia = DateTime(mesBase.year, mesBase.month + 1, 0).day;
      return DateTime(
        mesBase.year,
        mesBase.month,
        dia > ultimoDia ? ultimoDia : dia,
      );
    }

    String dataApi(DateTime data) =>
        '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo cliente'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dados do cliente',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                    decoration: const InputDecoration(
                      labelText: 'Endereço do cliente',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Piscina',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: piscinaNome,
                    decoration: const InputDecoration(
                      labelText: 'Nome ou identificação da piscina *',
                    ),
                  ),
                  TextField(
                    controller: piscinaEndereco,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Endereço da piscina',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: piscinaTipo,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: piscinaVolume,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Volume em litros',
                          ),
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<int?>(
                    initialValue: responsavelId,
                    decoration: const InputDecoration(
                      labelText: 'Colaborador responsável',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Definir depois'),
                      ),
                      ...funcionarios.map(
                        (f) => DropdownMenuItem<int?>(
                          value: f['id'] as int,
                          child: Text((f['usuario'] ?? {})['nome'] ?? ''),
                        ),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => responsavelId = v),
                  ),
                  DropdownButtonFormField<String?>(
                    initialValue: diaAtendimento,
                    decoration: const InputDecoration(
                      labelText: 'Dia de atendimento',
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Definir depois'),
                      ),
                      DropdownMenuItem(
                        value: 'Segunda',
                        child: Text('Segunda'),
                      ),
                      DropdownMenuItem(value: 'Terça', child: Text('Terça')),
                      DropdownMenuItem(value: 'Quarta', child: Text('Quarta')),
                      DropdownMenuItem(value: 'Quinta', child: Text('Quinta')),
                      DropdownMenuItem(value: 'Sexta', child: Text('Sexta')),
                      DropdownMenuItem(value: 'Sábado', child: Text('Sábado')),
                    ],
                    onChanged: (v) => setDialogState(() => diaAtendimento = v),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Cobrança',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: valor,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Mensalidade *',
                            prefixText: 'R\$ ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: vencimento,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Vence todo dia *',
                            helperText: '1 a 31',
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: inicioCobranca,
                    decoration: const InputDecoration(
                      labelText: 'Começar a cobrar *',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'MES_ATUAL',
                        child: Text('Neste mês'),
                      ),
                      DropdownMenuItem(
                        value: 'PROXIMO_MES',
                        child: Text('No próximo mês'),
                      ),
                      DropdownMenuItem(
                        value: 'PERSONALIZADO',
                        child: Text('Escolher uma data'),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => inicioCobranca = v!),
                  ),
                  if (inicioCobranca == 'PERSONALIZADO')
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: Text(
                        dataPersonalizada == null
                            ? 'Escolher primeiro vencimento'
                            : dataApi(dataPersonalizada!),
                      ),
                      onTap: () async {
                        final escolhida = await showDatePicker(
                          context: context,
                          initialDate:
                              dataPersonalizada ??
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 1095),
                          ),
                        );
                        if (escolhida != null)
                          setDialogState(() => dataPersonalizada = escolhida);
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Primeiro vencimento: ${dataApi(vencimentoCalculado())}',
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
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar cliente'),
            ),
          ],
        ),
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
        dia > 31 ||
        piscinaNome.text.trim().isEmpty ||
        (inicioCobranca == 'PERSONALIZADO' && dataPersonalizada == null) ||
        vencimentoCalculado().isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha cliente, piscina, mensalidade e primeiro vencimento corretamente.',
          ),
        ),
      );
      return;
    }

    try {
      final resposta = await apiService.post(
        '/api/clientes',
        body: {
          'nome': nome.text.trim(),
          'telefone': telefone.text.trim(),
          'endereco': endereco.text.trim(),
          'valorMensalidade': mensalidade,
          'diaVencimento': dia,
          'primeiroVencimento': dataApi(vencimentoCalculado()),
          'piscinaNome': piscinaNome.text.trim(),
          'piscinaTipo': piscinaTipo.text.trim(),
          'piscinaVolumeLitros': int.tryParse(piscinaVolume.text),
          'piscinaEndereco': piscinaEndereco.text.trim().isEmpty
              ? endereco.text.trim()
              : piscinaEndereco.text.trim(),
          'responsavelId': responsavelId,
          'diaAtendimento': diaAtendimento,
        },
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
      await apiService.put('/api/clientes/${cliente['id']}', body: cliente);
      atualizacaoClientes.value++;
      setState(() => clientes = carregar());
    }
  }

  Future<List<dynamic>> _buscar(String caminho) async {
    final r = await apiService.get(caminho);
    if (r.statusCode != 200)
      throw Exception('Não foi possível carregar os dados.');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<void> abrirPiscinas(Map<String, dynamic> cliente) async {
    final nome = TextEditingController();
    final endereco = TextEditingController();
    final tipo = TextEditingController();
    final volume = TextEditingController();
    final valor = TextEditingController();
    final existentes = await _buscar('/api/piscinas/cliente/${cliente['id']}');
    final funcionarios = widget.gestor ? await _buscar('/api/funcionarios') : <dynamic>[];
    if (!mounted) return;
    int? responsavel = funcionarios.isEmpty ? null : funcionarios.first['id'] as int;
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
                if (widget.gestor) ...[
                  const Divider(),
                  TextField(
                    controller: nome,
                    decoration: const InputDecoration(
                      labelText: 'Nome da piscina',
                    ),
                  ),
                  TextField(
                    controller: endereco,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Endereço da piscina',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo da piscina'),
                    items: const [
                      DropdownMenuItem(value: 'Fibra', child: Text('Fibra')),
                      DropdownMenuItem(value: 'Alvenaria', child: Text('Alvenaria')),
                    ],
                    onChanged: (valorSelecionado) => tipo.text = valorSelecionado ?? '',
                  ),
                  TextField(
                    controller: volume,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Volume em litros',
                    ),
                  ),
                  TextField(
                    controller: valor,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor mensal da piscina',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  DropdownButtonFormField<int?>(
                    initialValue: responsavel,
                    decoration: const InputDecoration(
                      labelText: 'Colaborador responsável',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Definir depois'),
                      ),
                      ...funcionarios.map<DropdownMenuItem<int?>>(
                        (funcionario) => DropdownMenuItem<int?>(
                          value: funcionario['id'] as int,
                          child: Text((funcionario['usuario'] ?? {})['nome'] ?? ''),
                        ),
                      ),
                    ],
                    onChanged: (valorSelecionado) => responsavel = valorSelecionado,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fechar'),
          ),
          if (widget.gestor)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cadastrar piscina'),
            ),
        ],
      ),
    );
    if (widget.gestor && salvar == true && nome.text.trim().isNotEmpty) {
      await apiService.post(
        '/api/piscinas',
        body: {
          'clienteId': cliente['id'],
          'nome': nome.text.trim(),
          'tipo': tipo.text.trim(),
          'volumeLitros': int.tryParse(volume.text) ?? 0,
          'endereco': endereco.text.trim(),
          'valorMensalidade': double.tryParse(valor.text.replaceAll(',', '.')) ?? 0,
          'responsavelId': responsavel,
          'observacoes': '',
        },
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
    int? piscinaId = piscinas.length == 1 ? piscinas.first['id'] as int : null;
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
                if (piscinaId != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Endereço: ${(piscinas.firstWhere((p) => p['id'] == piscinaId)['endereco'] ?? cliente['endereco'] ?? 'A informar')}',
                      ),
                    ),
                  ),
                TextField(
                  controller: descricao,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'O que deve ser feito',
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
      await apiService.post(
        '/api/ordens-servico',
        body: {
          'clienteId': cliente['id'],
          'piscinaId': piscinaId,
          'descricao': descricao.text.trim(),
          'dataServico': DateTime.now().toIso8601String().substring(0, 10),
        },
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
    final piscinas = await _buscar('/api/piscinas/cliente/${cliente['id']}');
    if (produtos.isEmpty || !mounted) return;
    final pedido = await mostrarDialogPedidoMultiplo(
      context: context,
      produtos: produtos,
      clientes: [cliente],
      piscinas: piscinas,
      clienteFixo: cliente['id'] as int,
      titulo: 'Novo pedido — ${cliente['nome']}',
    );
    if (pedido != null) {
      final r = await apiService.post(
        '/api/pedidos-produto/lote',
        body: pedido,
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
    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CabecalhoResponsivo(
          titulo: 'Clientes',
          subtitulo: 'Clientes cadastrados no banco Admin_Poll.',
          acao: widget.gestor
              ? FilledButton.icon(
                  onPressed: cadastrar,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Novo cliente'),
                )
              : null,
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
                    final celular = MediaQuery.of(context).size.width < 600;
                    final valor = (cliente['valorMensalidade'] ?? 0)
                        .toString()
                        .replaceAll('.', ',');
                    final dia = cliente['diaVencimento'] == null
                        ? 'Vencimento não informado'
                        : 'Vence dia ${cliente['diaVencimento']}';
                    final selecionado = clienteSelecionado == cliente['id'];
                    final corResponsavel = _corResponsavel(cliente['_responsavel']);
                    return Column(
                      children: [
                        ListTile(
                          onTap: () => setState(
                            () => clienteSelecionado = selecionado
                                ? null
                                : cliente['id'] as int,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: corResponsavel.withValues(alpha: .15),
                            foregroundColor: corResponsavel,
                            child: const Icon(Icons.person),
                          ),
                          title: Text(cliente['nome'] ?? ''),
                          subtitle: Text(
                            [
                              if (widget.gestor) dia,
                              if ((cliente['telefone'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                cliente['telefone'],
                              if ((cliente['endereco'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                cliente['endereco'],
                              if (widget.gestor && celular)
                                'Mensalidade: R\$ $valor',
                              'Clique para abrir os serviços',
                            ].join(' • '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.gestor && !celular)
                                Text(
                                  'R\$ $valor',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (widget.gestor)
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => editar(cliente),
                                ),
                              if (widget.gestor)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      excluir(cliente['id'] as int),
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
                            child: celular
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      FilledButton.tonalIcon(
                                        onPressed: () => abrirPiscinas(cliente),
                                        icon: const Icon(Icons.pool_outlined),
                                        label: const Text('Piscinas'),
                                      ),
                                      const SizedBox(height: 8),
                                      FilledButton.tonalIcon(
                                        onPressed: () =>
                                            abrirOrdemServico(cliente),
                                        icon: const Icon(Icons.build_outlined),
                                        label: const Text('Ordem de serviço'),
                                      ),
                                      const SizedBox(height: 8),
                                      FilledButton.tonalIcon(
                                        onPressed: () => abrirPedido(cliente),
                                        icon: const Icon(
                                          Icons.shopping_cart_outlined,
                                        ),
                                        label: const Text('Produtos'),
                                      ),
                                    ],
                                  )
                                : Row(
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
                                          onPressed: () =>
                                              abrirOrdemServico(cliente),
                                          icon: const Icon(
                                            Icons.build_outlined,
                                          ),
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
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width < 600 ? 16 : 28,
      ),
      children: [
        Text(
          'Olá, ${gestor ? 'Gestor' : (apiService.nomeUsuario ?? 'Colaborador')}!',
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
                  const _NotificacaoOperacionalCard(
                    tipo: _TipoNotificacao.produto,
                  ),
                  const _NotificacaoOperacionalCard(
                    tipo: _TipoNotificacao.ordemServico,
                  ),
                  const _FaturamentoCard(),
                  const _FluxoCaixaCard(),
                  const _ResultadoProdutosCard(),
                ]
              : const [_ResumoFuncionario()],
        ),
        const SizedBox(height: 32),
        Text(
          gestor ? 'Cobranças do mês' : 'Próximos serviços',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        gestor ? const _CobrancasDoMes() : const _ProximosServicosFuncionario(),
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
    final r = await apiService.get('/api/cobrancas');
    if (r.statusCode != 200) throw Exception('API indisponível');
    return jsonDecode(r.body) as List<dynamic>;
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
                  Icon(
                    status == 'PAGO' ? Icons.check_circle : Icons.chevron_right,
                    color: cor,
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
    future: apiService.get('/api/cobrancas'),
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
    final r = await apiService.get(rota);
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
    final r = await apiService.get(endpoint);
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
