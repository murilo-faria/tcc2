package br.com.adminpool.service;

import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.Funcionario;
import br.com.adminpool.model.Piscina;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.FuncionarioRepository;
import br.com.adminpool.repository.PiscinaRepository;
import jakarta.transaction.Transactional;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.YearMonth;

/** Importação única e idempotente da carteira do Murilo. */
@Component
public class ImportadorClientesMurilo implements CommandLineRunner {

    private record Cadastro(String nome, String mensalidade, int vencimento) {}

    private static final Cadastro[] CADASTROS = {
            new Cadastro("Eduardo", "170.00", 10), new Cadastro("Angela", "160.00", 10),
            new Cadastro("Valdir", "160.00", 10), new Cadastro("Gustavo", "250.00", 10),
            new Cadastro("Raiane", "150.00", 10), new Cadastro("Carlivan", "230.00", 10),
            new Cadastro("Marluce", "250.00", 10), new Cadastro("Rogélio", "250.00", 10),
            new Cadastro("Allyne", "210.00", 10), new Cadastro("Evandro", "260.00", 15),
            new Cadastro("Danilo", "230.00", 15), new Cadastro("Alice", "450.00", 15),
            new Cadastro("Marcelo", "260.00", 15), new Cadastro("Santhiago", "260.00", 25),
            new Cadastro("Taciana", "260.00", 10), new Cadastro("Daniella", "240.00", 10),
            new Cadastro("Felipe Boa Esperança", "270.00", 10), new Cadastro("Alan", "250.00", 10),
            new Cadastro("Fabiana", "240.00", 10), new Cadastro("Frederico", "240.00", 10),
            new Cadastro("Joaquim Ribas", "360.00", 10), new Cadastro("Carol", "250.00", 20),
            new Cadastro("Gislaine", "270.00", 20), new Cadastro("Josemar", "260.00", 20),
            new Cadastro("Sid", "260.00", 30), new Cadastro("Junior", "240.00", 10),
            new Cadastro("Rubia", "460.00", 20), new Cadastro("Marcio", "300.00", 10),
            new Cadastro("Thiago", "280.00", 20), new Cadastro("Allison", "310.00", 30),
            new Cadastro("Lucimar", "260.00", 10), new Cadastro("Tia Sirlene", "160.00", 10)
    };

    private final ClienteRepository clientes;
    private final PiscinaRepository piscinas;
    private final FuncionarioRepository funcionarios;
    private final CobrancaService cobrancas;

    public ImportadorClientesMurilo(ClienteRepository clientes, PiscinaRepository piscinas,
                                    FuncionarioRepository funcionarios, CobrancaService cobrancas) {
        this.clientes = clientes;
        this.piscinas = piscinas;
        this.funcionarios = funcionarios;
        this.cobrancas = cobrancas;
    }

    @Override
    @Transactional
    public void run(String... args) {
        Funcionario murilo = funcionarios.findByUsuarioLoginIgnoreCase("funcionario1").orElse(null);
        if (murilo == null) return;

        YearMonth mesAtual = YearMonth.now();
        for (Cadastro cadastro : CADASTROS) {
            boolean jaExiste = clientes.findAll().stream()
                    .anyMatch(cliente -> cliente.getNome().trim().equalsIgnoreCase(cadastro.nome()));
            if (jaExiste) continue;

            Cliente cliente = new Cliente();
            cliente.setNome(cadastro.nome());
            cliente.setValorMensalidade(new BigDecimal(cadastro.mensalidade()));
            cliente.setDiaVencimento(cadastro.vencimento());
            cliente.setPrimeiroVencimento(mesAtual.atDay(Math.min(cadastro.vencimento(), mesAtual.lengthOfMonth())));
            cliente.setAtivo(true);
            Cliente salvo = clientes.save(cliente);

            Piscina piscina = new Piscina();
            piscina.setCliente(salvo);
            piscina.setNome("Piscina " + cadastro.nome());
            piscina.setResponsavel(murilo);
            piscinas.save(piscina);
        }
        cobrancas.gerarMesAtual();
    }
}
