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
  Color _cor(Map<String,dynamic> f) { const cores=[Colors.blue,Colors.green,Colors.orange,Colors.deepPurple,Colors.teal]; return cores[(f['id'] as int? ?? 0)%cores.length]; }
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

class _DialogoVales extends StatefulWidget { const _DialogoVales({required this.aoAtualizar}); final VoidCallback aoAtualizar; @override State<_DialogoVales> createState()=>_DialogoValesState(); }
class _DialogoValesState extends State<_DialogoVales> { late Future<List<dynamic>> vales; @override void initState(){super.initState();vales=carregar();} Future<List<dynamic>> carregar()async{final r=await apiService.get('/api/salarios/vales');if(r.statusCode!=200)throw Exception('Não foi possível carregar os vales.');return jsonDecode(r.body);} void recarregar(){widget.aoAtualizar();setState(()=>vales=carregar());}
Future<void> formulario([Map<String,dynamic>? vale]) async { final funcionarios=await apiService.get('/api/funcionarios');if(funcionarios.statusCode!=200||!mounted)return;final lista=jsonDecode(funcionarios.body) as List<dynamic>;int funcionario=(vale?['funcionario']??{})['id']??lista.first['id'];String tipo=vale?['tipo']??'ADIANTAMENTO';final valor=TextEditingController(text:(vale?['valor']??'').toString());final obs=TextEditingController(text:vale?['observacao']??'');final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(_,setL)=>AlertDialog(title:Text(vale==null?'Novo vale':'Editar vale'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<int>(value:funcionario,items:lista.map<DropdownMenuItem<int>>((f)=>DropdownMenuItem(value:f['id'],child:Text((f['usuario']??{})['nome']??''))).toList(),onChanged:vale==null?(v)=>setL(()=>funcionario=v!):null,decoration:const InputDecoration(labelText:'Colaborador')),DropdownButtonFormField<String>(value:tipo,items:const[DropdownMenuItem(value:'ADIANTAMENTO',child:Text('Adiantamento')),DropdownMenuItem(value:'DINHEIRO_CLIENTE',child:Text('Dinheiro recebido de cliente'))],onChanged:(v)=>setL(()=>tipo=v!),decoration:const InputDecoration(labelText:'Tipo')),TextField(controller:valor,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Valor',prefixText:'R\$ ')),TextField(controller:obs,decoration:const InputDecoration(labelText:'Observação'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Salvar'))])));if(ok!=true)return;final body={'funcionarioId':funcionario,'tipo':tipo,'valor':double.tryParse(valor.text.replaceAll(',','.'))??0,'observacao':obs.text.trim()};final r=vale==null?await apiService.post('/api/salarios/vales',body:body):await apiService.put('/api/salarios/vales/${vale['id']}',body:body);if(r.statusCode>=200&&r.statusCode<300)recarregar();}
Future<void> excluir(Map<String,dynamic> vale)async{final r=await apiService.delete('/api/salarios/vales/${vale['id']}');if(r.statusCode>=200&&r.statusCode<300)recarregar();}
@override Widget build(BuildContext c)=>AlertDialog(title:const Text('Vales dos colaboradores'),content:SizedBox(width:650,height:420,child:FutureBuilder<List<dynamic>>(future:vales,builder:(_,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('${s.error}'));return ListView.separated(itemCount:s.data!.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(_,i){final v=s.data![i] as Map<String,dynamic>;final f=v['funcionario']??{},u=f['usuario']??{};return ListTile(onTap:()=>formulario(v),leading:CircleAvatar(backgroundColor:[Colors.blue,Colors.green,Colors.orange,Colors.deepPurple][(f['id'] as int? ?? 0)%4].withValues(alpha:.15),child:const Icon(Icons.person_outline)),title:Text(u['nome']??''),subtitle:Text('${v['tipo']} • ${v['dataLancamento']}\n${v['observacao']??''}'),isThreeLine:true,trailing:Row(mainAxisSize:MainAxisSize.min,children:[Text(formatarMoeda((v['valor'] as num?)??0)),IconButton(onPressed:()=>formulario(v),icon:const Icon(Icons.edit_outlined)),IconButton(onPressed:()=>excluir(v),icon:const Icon(Icons.delete_outline,color:Colors.red))]));});})),actions:[OutlinedButton.icon(onPressed:()=>formulario(),icon:const Icon(Icons.add),label:const Text('Novo vale')),TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Fechar'))]); }

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
