# Admin Pool — API Spring Boot

Esta pasta contém a API responsável pelas regras do sistema e pela comunicação com o PostgreSQL.

## Camadas

```text
Flutter
   ↓ requisição HTTP
Controller   → recebe a requisição e devolve a resposta
DTO          → define os dados de entrada
Service      → executa as regras de negócio
Repository   → acessa o banco por meio do JPA
Model        → representa as tabelas do PostgreSQL
```

## Pacotes principais

```text
br.com.adminpool/
├── controller/  # Rotas REST: clientes, cobranças, produtos, pedidos, piscinas e OS
├── dto/         # Dados recebidos nos cadastros e pedidos
├── model/       # Entidades persistidas no PostgreSQL
├── repository/  # Interfaces do Spring Data JPA
└── service/     # Fechamento mensal e lançamentos nas cobranças
```

## Executar

```powershell
cd "C:\Users\MURILO\Desktop\TADS\TCc 2\admin_pool_api"
mvn spring-boot:run
```

A API ficará disponível em `http://localhost:8081`.

## Exemplo completo: criação de uma ordem de serviço

1. O Flutter envia um `POST /api/ordens-servico`.
2. `OrdemServicoController` recebe um `NovaOrdemServicoRequest`.
3. Os repositórios localizam o cliente e a piscina.
4. A ordem é gravada no banco.
5. Se existir valor adicional, `LancamentoCobrancaService` soma o valor à cobrança do mês.

## Banco de dados

As configurações de conexão ficam em `src/main/resources/application.properties`. O PostgreSQL precisa estar ativo antes de iniciar a API.
