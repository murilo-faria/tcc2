package br.com.adminpool.controller;

import br.com.adminpool.dto.NovoClienteRequest;
import br.com.adminpool.dto.AlterarStatusClienteRequest;
import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.Piscina;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.FuncionarioRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.repository.RoteiroAtendimentoRepository;
import br.com.adminpool.model.RoteiroAtendimento;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/clientes")

public class ClienteController {

    private final ClienteRepository clientes;
    private final PiscinaRepository piscinas;
    private final FuncionarioRepository funcionarios;
    private final RoteiroAtendimentoRepository roteiro;

    public ClienteController(ClienteRepository clientes, PiscinaRepository piscinas, FuncionarioRepository funcionarios, RoteiroAtendimentoRepository roteiro) {
        this.clientes = clientes;
        this.piscinas = piscinas;
        this.funcionarios = funcionarios;
        this.roteiro = roteiro;
    }

    @GetMapping
    public List<Cliente> listar(Authentication auth) {
        boolean gestor=auth.getAuthorities().stream().anyMatch(a->a.getAuthority().equals("ROLE_GESTOR"));
        return gestor ? clientes.findAll() : clientes.findResponsaveisPorLogin(auth.getName());
    }

    @PostMapping
    @Transactional
    public ResponseEntity<Cliente> criar(@RequestBody NovoClienteRequest requisicao, Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem cadastrar clientes.");
        }
        validar(requisicao);

        Cliente cliente = new Cliente();
        cliente.setNome(requisicao.nome().trim());
        cliente.setCpfCnpj(requisicao.cpfCnpj());
        cliente.setTelefone(requisicao.telefone());
        cliente.setEndereco(requisicao.endereco());
        cliente.setValorMensalidade(BigDecimal.ZERO);
        cliente.setDiaVencimento(requisicao.diaVencimento());
        cliente.setPrimeiroVencimento(requisicao.primeiroVencimento());
        cliente.setAtivo(true);
        Cliente clienteSalvo = clientes.save(cliente);

        Piscina piscina = new Piscina();
        piscina.setCliente(clienteSalvo);
        piscina.setNome(requisicao.piscinaNome().trim());
        piscina.setTipo(requisicao.piscinaTipo());
        piscina.setVolumeLitros(requisicao.piscinaVolumeLitros());
        piscina.setEndereco(requisicao.piscinaEndereco());
        piscina.setDiaAtendimento(requisicao.diaAtendimento());
        piscina.setValorMensalidade(requisicao.piscinaValorMensalidade() == null
                ? requisicao.valorMensalidade() : requisicao.piscinaValorMensalidade());
        if (requisicao.responsavelId() != null) {
            piscina.setResponsavel(funcionarios.findById(requisicao.responsavelId()).orElseThrow());
        }
        piscinas.save(piscina);
        if (requisicao.diaAtendimento() != null && !requisicao.diaAtendimento().isBlank()) {
            RoteiroAtendimento atendimento = new RoteiroAtendimento();
            atendimento.setCliente(clienteSalvo);
            atendimento.setDiaAtendimento(requisicao.diaAtendimento());
            roteiro.save(atendimento);
        }

        return ResponseEntity.status(HttpStatus.CREATED).body(clienteSalvo);
    }

    @PutMapping("/{id}")
    public Cliente atualizar(@PathVariable Long id, @RequestBody Cliente cliente) {
        cliente.setId(id);
        return clientes.save(cliente);
    }

    @PutMapping("/{id}/ativo")
    public Cliente alterarAtivo(@PathVariable Long id,
                                @RequestBody AlterarStatusClienteRequest requisicao,
                                Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem inativar clientes.");
        }
        Cliente cliente = clientes.findById(id).orElseThrow();
        cliente.setAtivo(requisicao.ativo());
        if (requisicao.ativo()) {
            // A volta do cliente inicia um novo ciclo, sem gerar mensalidade no mesmo dia.
            cliente.setPrimeiroVencimento(LocalDate.now().plusDays(30));
        }
        return clientes.save(cliente);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        clientes.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    private void validar(NovoClienteRequest requisicao) {
        if (requisicao.nome() == null || requisicao.nome().isBlank()) {
            throw new IllegalArgumentException("Informe o nome do cliente.");
        }
        if (requisicao.piscinaNome() == null || requisicao.piscinaNome().isBlank()) {
            throw new IllegalArgumentException("Informe a piscina do cliente.");
        }
        BigDecimal valorPiscina = requisicao.piscinaValorMensalidade() == null
                ? requisicao.valorMensalidade() : requisicao.piscinaValorMensalidade();
        if (valorPiscina == null || valorPiscina.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Informe o valor da piscina.");
        }
        if (requisicao.diaVencimento() == null || requisicao.diaVencimento() < 1 || requisicao.diaVencimento() > 31) {
            throw new IllegalArgumentException("O dia de vencimento deve estar entre 1 e 31.");
        }
        if (requisicao.primeiroVencimento() == null || requisicao.primeiroVencimento().isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("O primeiro vencimento deve ser hoje ou uma data futura.");
        }
    }

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }
}
