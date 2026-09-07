package br.com.adminpool.controller;

import br.com.adminpool.dto.NovaOrdemServicoRequest;
import br.com.adminpool.model.OrdemServico;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.OrdemServicoRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.service.LancamentoCobrancaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/ordens-servico")
@CrossOrigin(originPatterns = "http://localhost:*")
public class OrdemServicoController {

    private final OrdemServicoRepository ordens;
    private final ClienteRepository clientes;
    private final PiscinaRepository piscinas;
    private final LancamentoCobrancaService lancamentos;

    public OrdemServicoController(
            OrdemServicoRepository ordens,
            ClienteRepository clientes,
            PiscinaRepository piscinas,
            LancamentoCobrancaService lancamentos) {
        this.ordens = ordens;
        this.clientes = clientes;
        this.piscinas = piscinas;
        this.lancamentos = lancamentos;
    }

    @GetMapping
    public List<OrdemServico> listarTodas() {
        return ordens.findAllByOrderByDataServicoDesc();
    }

    @GetMapping("/cliente/{clienteId}")
    public List<OrdemServico> listarPorCliente(@PathVariable Long clienteId) {
        return ordens.findByClienteIdOrderByDataServicoDesc(clienteId);
    }

    @GetMapping("/abertas")
    public List<OrdemServico> listarAbertas() {
        return ordens.findByStatusOrderByDataServicoDesc("ABERTA");
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<Void> alterarStatus(@PathVariable Long id, @RequestParam String status) {
        OrdemServico ordem = ordens.findById(id).orElseThrow();
        ordem.setStatus(status);
        ordens.save(ordem);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        ordens.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping
    public ResponseEntity<OrdemServico> criar(@RequestBody NovaOrdemServicoRequest requisicao) {
        OrdemServico ordem = new OrdemServico();
        ordem.setCliente(clientes.findById(requisicao.clienteId()).orElseThrow());

        if (requisicao.piscinaId() != null) {
            ordem.setPiscina(piscinas.findById(requisicao.piscinaId()).orElseThrow());
        }

        ordem.setDescricao(requisicao.descricao());
        ordem.setDataServico(
                requisicao.dataServico() == null ? LocalDate.now() : requisicao.dataServico());
        ordem.setValorAdicional(
                requisicao.valorAdicional() == null ? BigDecimal.ZERO : requisicao.valorAdicional());

        OrdemServico ordemSalva = ordens.save(ordem);
        if (ordemSalva.getValorAdicional().signum() > 0) {
            lancamentos.adicionarServico(requisicao.clienteId(), ordemSalva.getValorAdicional());
        }

        return ResponseEntity.status(HttpStatus.CREATED).body(ordemSalva);
    }
}
