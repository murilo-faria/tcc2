part of '../main.dart';

/// Tela responsável pela autenticação e escolha do perfil de acesso.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Perfil perfil = Perfil.gestor;
  bool ocultarSenha = true;
  bool entrando = false;
  final usuarioController = TextEditingController();
  final senhaController = TextEditingController();

  Future<void> entrar() async {
    if (entrando) return;
    final usuario = usuarioController.text.trim();
    final senha = senhaController.text;
    TextInput.finishAutofillContext(shouldSave: true);
    setState(() => entrando = true);
    try {
      final recebido = await apiService.login(usuario, senha);
      final perfilValidado = recebido == 'gestor'
          ? Perfil.gestor
          : Perfil.funcionario;
      if (perfilValidado != perfil) {
        apiService.logout();
        throw Exception('Selecione o perfil correspondente ao usuário.');
      }
      if (!mounted) return;
      senhaController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(perfil: perfilValidado)),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            erro.toString().startsWith('Exception:')
                ? erro.toString().replaceFirst('Exception: ', '')
                : 'Não foi possível conectar. Verifique sua conexão e tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => entrando = false);
    }
  }

  @override
  void dispose() {
    usuarioController.dispose();
    senhaController.dispose();
    super.dispose();
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
                    AutofillGroup(
                      child: Column(
                        children: [
                          TextField(
                            controller: usuarioController,
                            autofillHints: const [AutofillHints.username],
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Usuário',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: senhaController,
                            autofillHints: const [AutofillHints.password],
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
                                onPressed: () {
                                  setState(() => ocultarSenha = !ocultarSenha);
                                },
                              ),
                            ),
                          ),
                        ],
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
                      onSelectionChanged: (itens) {
                        setState(() => perfil = itens.first);
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: entrando ? null : entrar,
                      icon: const Icon(Icons.login),
                      label: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Entrar'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Recuperar senha'),
                          content: const Text(
                            'Peça ao gestor para redefinir sua senha no cadastro de funcionários. Por segurança, a senha não é enviada por e-mail nem exibida no sistema.',
                          ),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))],
                        ),
                      ),
                      child: const Text('Esqueci minha senha'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Use o usuário correspondente ao perfil escolhido.',
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
