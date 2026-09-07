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
  final usuarioController = TextEditingController();
  final senhaController = TextEditingController();

  void entrar() {
    final usuario = usuarioController.text.trim();
    final senha = senhaController.text;
    final credenciaisValidas =
        (perfil == Perfil.gestor &&
            usuario == 'gestorMurilo' &&
            senha == '1234') ||
        (perfil == Perfil.funcionario &&
            usuario == 'funcionario1' &&
            senha == '1234');

    if (!credenciaisValidas) {
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
                      decoration: const InputDecoration(
                        labelText: 'Usuário',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
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
                          onPressed: () {
                            setState(() => ocultarSenha = !ocultarSenha);
                          },
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
                      onSelectionChanged: (itens) {
                        setState(() => perfil = itens.first);
                      },
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
