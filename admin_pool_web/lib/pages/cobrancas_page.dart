part of '../main.dart';

class _CobrancasPageNova extends StatefulWidget {
  const _CobrancasPageNova();

  @override
  State<_CobrancasPageNova> createState() => _CobrancasPageNovaState();
}

class _CobrancasPageNovaState extends State<_CobrancasPageNova> {
  late Future<List<String>> _meses;
  late Future<List<dynamic>> _cobrancas;
  String? _referencia;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _meses = _carregarMeses();
    _cobrancas = _carregarCobrancas();
  }

  Future<List<String>> _carregarMeses() async {
    final resposta = await apiService.get('/api/cobrancas/meses');
    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível carregar os meses.');
    }
    return (jsonDecode(resposta.body) as List<dynamic>).cast<String>();
  }

  Future<List<dynamic>> _carregarCobrancas() async {
    final sufixo = _referencia == null ? '' : '?referencia=$_referencia';
    final resposta = await apiService.get('/api/cobrancas$sufixo');
    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível carregar cobranças.');
    }
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  String _tituloMes(String referencia) {
    final partes = referencia.split('-');
    const nomes = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    return '${nomes[int.parse(partes[1]) - 1]} de ${partes[0]}';
  }

  Future<void> _alterarPagamento(Map<String, dynamic> cobranca) async {
    final pago = cobranca['status'] == 'PAGO';
    final resposta = await apiService.put(
      pago
          ? '/api/cobrancas/${cobranca['id']}/reabrir'
          : '/api/cobrancas/${cobranca['id']}/baixar?valor=${cobranca['total']}',
    );
    if (!mounted) return;
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      setState(() => _cobrancas = _carregarCobrancas());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar o pagamento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cobranças', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Mensalidades e valores de produtos e serviços.'),
          const SizedBox(height: 20),
          FutureBuilder<List<String>>(
            future: _meses,
            builder: (context, estado) {
              if (!estado.hasData) return const LinearProgressIndicator();
              final meses = estado.data!;
              return Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      value: _referencia,
                      decoration: const InputDecoration(
                        labelText: 'Mês de referência',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Mês atual e atrasos'),
                        ),
                        ...meses.map((mes) => DropdownMenuItem(
                          value: mes,
                          child: Text(_tituloMes(mes)),
                        )),
                      ],
                      onChanged: (mes) {
                        setState(() {
                          _referencia = mes;
                          _cobrancas = _carregarCobrancas();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _referencia = null;
                        _meses = _carregarMeses();
                        _cobrancas = _carregarCobrancas();
                      });
                    },
                    icon: const Icon(Icons.today_outlined),
                    label: const Text('Voltar ao mês atual'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Pesquisar cliente',
              border: OutlineInputBorder(),
            ),
            onChanged: (valor) => setState(() => _busca = valor.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _cobrancas,
              builder: (context, estado) {
                if (estado.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (estado.hasError) return Center(child: Text('${estado.error}'));
                final itens = estado.data!.where((item) {
                  final nome = ((item['cliente'] ?? {})['nome'] ?? '').toString().toLowerCase();
                  return nome.contains(_busca);
                }).toList();
                if (itens.isEmpty) {
                  return const Center(child: Text('Nenhuma cobrança neste mês.'));
                }
                return Card(
                  child: ListView.separated(
                    itemCount: itens.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, indice) {
                      final cobranca = itens[indice] as Map<String, dynamic>;
                      final pago = cobranca['status'] == 'PAGO';
                      return ListTile(
                        leading: Icon(pago ? Icons.check_circle : Icons.pending_actions, color: pago ? Colors.green : Colors.orange),
                        title: Text((cobranca['cliente'] ?? {})['nome'] ?? ''),
                        subtitle: Text('Vencimento: ${cobranca['vencimento']} • ${cobranca['status']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatarMoeda(cobranca['total'] as num)),
                            Switch(value: pago, onChanged: (_) => _alterarPagamento(cobranca)),
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
