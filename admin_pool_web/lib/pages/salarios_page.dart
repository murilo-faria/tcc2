part of '../main.dart';

class _SalariosPageNova extends StatefulWidget {
  const _SalariosPageNova({required this.gestor});
  final bool gestor;

  @override
  State<_SalariosPageNova> createState() => _SalariosPageNovaState();
}

class _SalariosPageNovaState extends State<_SalariosPageNova> {
  late Future<List<dynamic>> _salarios;

  @override
  void initState() {
    super.initState();
    _salarios = _carregar();
  }

  Future<List<dynamic>> _carregar() async {
    final resposta = await apiService.get('/api/salarios');
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
        aoAtualizar: () => setState(() => _salarios = _carregar()),
      ),
    );
  }

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
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(child: Text(usuario['nome'] ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                const Icon(Icons.chevron_right),
              ]),
              const Divider(),
              Text('Comissão: ${formatarMoeda(salario)}'),
              Text('Reembolsos pendentes: ${formatarMoeda(reembolsos)}'),
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

class _DialogoReembolsos extends StatefulWidget {
  const _DialogoReembolsos({required this.funcionario, required this.gestor, required this.aoAtualizar});
  final Map<String, dynamic> funcionario;
  final bool gestor;
  final VoidCallback aoAtualizar;

  @override
  State<_DialogoReembolsos> createState() => _DialogoReembolsosState();
}

class _DialogoReembolsosState extends State<_DialogoReembolsos> {
  late Future<List<dynamic>> _reembolsos;

  @override
  void initState() {
    super.initState();
    _reembolsos = _carregar();
  }

  Future<List<dynamic>> _carregar() async {
    final resposta = await apiService.get('/api/salarios/${widget.funcionario['id']}/reembolsos');
    if (resposta.statusCode != 200) throw Exception('Não foi possível carregar os reembolsos.');
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
      setState(() => _reembolsos = _carregar());
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.funcionario['usuario'] ?? {};
    return AlertDialog(
      title: Text('Reembolsos — ${usuario['nome'] ?? ''}'),
      content: SizedBox(
        width: 650,
        height: 430,
        child: FutureBuilder<List<dynamic>>(
          future: _reembolsos,
          builder: (_, estado) {
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());
            if (estado.hasError) return Center(child: Text('${estado.error}'));
            if (estado.data!.isEmpty) return const Center(child: Text('Nenhum reembolso lançado neste mês.'));
            return ListView.separated(
              itemCount: estado.data!.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, indice) {
                final reembolso = estado.data![indice] as Map<String, dynamic>;
                final pendente = reembolso['status'] == 'PENDENTE';
                return ListTile(
                  leading: Icon(pendente ? Icons.pending_actions : Icons.check_circle, color: pendente ? Colors.orange : Colors.green),
                  title: Text(reembolso['descricao'] ?? ''),
                  subtitle: Text('${reembolso['dataLancamento']} • ${reembolso['status']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatarMoeda((reembolso['valor'] as num?) ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (widget.gestor && pendente) IconButton(tooltip: 'Confirmar reembolso', onPressed: () => _pagar(reembolso), icon: const Icon(Icons.check_circle_outline, color: Colors.green)),
                    ],
                  ),
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
