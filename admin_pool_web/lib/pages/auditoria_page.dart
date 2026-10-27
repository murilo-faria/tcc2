part of '../main.dart';

class _AuditoriaPage extends StatefulWidget {
  const _AuditoriaPage();

  @override
  State<_AuditoriaPage> createState() => _AuditoriaPageState();
}

class _AuditoriaPageState extends State<_AuditoriaPage> {
  late Future<List<dynamic>> _registros;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _registros = _carregar();
  }

  Future<List<dynamic>> _carregar() async {
    final resposta = await apiService.get('/api/auditoria');
    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível carregar o histórico de auditoria.');
    }
    return jsonDecode(resposta.body) as List<dynamic>;
  }

  void _atualizar() => setState(() => _registros = _carregar());

  String _dataHora(String? valor) {
    final data = DateTime.tryParse(valor ?? '');
    if (data == null) return valor ?? '';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  String _acao(String valor) => switch (valor) {
        'POST' => 'Criou',
        'PUT' || 'PATCH' => 'Alterou',
        'DELETE' => 'Excluiu',
        _ => valor,
      };

  @override
  Widget build(BuildContext context) {
    final celular = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: EdgeInsets.all(celular ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CabecalhoResponsivo(
            titulo: 'Auditoria',
            subtitulo: 'Histórico das alterações realizadas no sistema.',
            acao: OutlinedButton.icon(
              onPressed: _atualizar,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Pesquisar usuário, módulo ou ação',
              border: OutlineInputBorder(),
            ),
            onChanged: (valor) => setState(() => _busca = valor.trim().toLowerCase()),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _registros,
              builder: (context, resultado) {
                if (resultado.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (resultado.hasError) {
                  return Center(child: Text('${resultado.error}'));
                }
                final registros = resultado.data!.where((registro) {
                  final texto = '${registro['usuarioLogin']} ${registro['modulo']} ${registro['acao']} ${registro['recurso']}'.toLowerCase();
                  return texto.contains(_busca);
                }).toList();
                if (registros.isEmpty) {
                  return const Center(child: Text('Nenhuma alteração encontrada.'));
                }
                return ListView.separated(
                  itemCount: registros.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, indice) {
                    final registro = registros[indice] as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: switch (registro['acao']) {
                          'DELETE' => Colors.red.shade50,
                          'POST' => Colors.green.shade50,
                          _ => Colors.blue.shade50,
                        },
                        child: Icon(
                          switch (registro['acao']) {
                            'DELETE' => Icons.delete_outline,
                            'POST' => Icons.add_circle_outline,
                            _ => Icons.edit_outlined,
                          },
                          color: switch (registro['acao']) {
                            'DELETE' => Colors.red,
                            'POST' => Colors.green,
                            _ => Colors.blue,
                          },
                        ),
                      ),
                      title: Text('${_acao('${registro['acao']}')} em ${registro['modulo']}'),
                      subtitle: Text('${registro['usuarioLogin']} • ${_dataHora(registro['dataHora']?.toString())}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('${_acao('${registro['acao']}')} em ${registro['modulo']}'),
                          content: SingleChildScrollView(
                            child: SelectableText(
                              'Usuário: ${registro['usuarioLogin']}\n'
                              'Data: ${_dataHora(registro['dataHora']?.toString())}\n'
                              'Recurso: ${registro['recurso']}\n\n'
                              'Dados informados:\n${registro['dadosInformados'] ?? 'Não informado'}',
                            ),
                          ),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
