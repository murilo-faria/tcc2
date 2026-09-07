# Admin Pool — Flutter Web

Esta pasta contém a interface visual do sistema. O Flutter exibe as telas e envia as operações para a API Java.

## Organização da pasta `lib`

```text
lib/
├── main.dart                         # Inicializa o aplicativo e reúne as telas principais
├── core/
│   ├── api_config.dart               # Endereço da API Java
│   ├── atualizadores.dart            # Atualização dos dados exibidos
│   └── formatadores.dart              # Formatação de moeda e mês
├── models/
│   └── perfil.dart                   # Perfis Gestor e Funcionário
├── pages/
│   └── login_page.dart               # Tela de autenticação
├── services/
│   └── api_service.dart              # Métodos GET, POST, PUT e DELETE
└── widgets/
    └── dialogo_pedido_multiplo.dart  # Formulário reutilizável de pedidos
```

## Fluxo de uma operação

Exemplo: cadastro de cliente.

1. O usuário preenche o formulário no Flutter.
2. A tela chama `apiService.post('/api/clientes', ...)`.
3. O `ApiService` envia os dados para o Spring Boot.
4. A API grava o cliente no PostgreSQL.
5. O Flutter recarrega a lista e mostra o novo cliente.

## Executar

Primeiro inicie a API Java. Depois, em outro terminal:

```powershell
cd "C:\Users\MURILO\Desktop\TADS\TCc 2\admin_pool_web"
flutter run -d chrome --web-port 8080
```

Abra `http://localhost:8080`.

## Acessos de demonstração

- Gestor: `gestorMurilo` / `1234`
- Funcionário: `funcionario1` / `1234`

> As credenciais ainda são locais no protótipo. Em uma versão de produção, o login deve ser validado pela API e a senha deve ser armazenada de forma segura.
