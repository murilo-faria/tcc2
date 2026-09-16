package br.com.adminpool.controller;

import br.com.adminpool.dto.ConcluirOrdemServicoRequest;
import br.com.adminpool.dto.NovaOrdemServicoRequest;
import br.com.adminpool.model.OrdemServico;
import br.com.adminpool.repository.OrdemServicoRepository;
import br.com.adminpool.service.OrdemServicoService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/ordens-servico")
public class OrdemServicoController {

    private final OrdemServicoRepository ordens;
    private final OrdemServicoService servico;

    public OrdemServicoController(OrdemServicoRepository ordens, OrdemServicoService servico) {
        this.ordens = ordens;
        this.servico = servico;
    }

    @GetMapping
    public List<OrdemServico> listarTodas(Authentication auth) {
        return gestor(auth) ? ordens.findAllByOrderByDataServicoDesc()
                : ordens.findByPiscinaResponsavelUsuarioLoginIgnoreCaseOrderByDataServicoDesc(auth.getName());
    }

    @GetMapping("/{id}")
    public OrdemServico detalhar(@PathVariable Long id) {
        return ordens.findById(id).orElseThrow();
    }

    @GetMapping("/cliente/{clienteId}")
    public List<OrdemServico> listarPorCliente(@PathVariable Long clienteId) {
        return ordens.findByClienteIdOrderByDataServicoDesc(clienteId);
    }

    @GetMapping("/abertas")
    public List<OrdemServico> listarAbertas() {
        return ordens.findByStatusOrderByDataServicoDesc("ABERTA");
    }

    @PostMapping
    public ResponseEntity<OrdemServico> criar(@RequestBody NovaOrdemServicoRequest requisicao,
                                              Authentication auth) {
        return ResponseEntity.status(HttpStatus.CREATED).body(servico.criar(requisicao, auth));
    }

    @PutMapping("/{id}")
    public OrdemServico editar(@PathVariable Long id, @RequestBody NovaOrdemServicoRequest requisicao,
                               Authentication auth) {
        if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem editar uma OS.");
        return servico.editar(id, requisicao);
    }

    @PutMapping("/{id}/concluir")
    public OrdemServico concluir(@PathVariable Long id,
                                  @RequestBody ConcluirOrdemServicoRequest requisicao,
                                  Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem concluir uma OS.");
        }
        return servico.concluir(id, requisicao);
    }

    @PutMapping("/{id}/cancelar")
    public ResponseEntity<Void> cancelar(@PathVariable Long id) {
        servico.cancelar(id);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        OrdemServico ordem = ordens.findById(id).orElseThrow();
        if (ordem.isFinanceiroLancado()) {
            throw new IllegalStateException("Uma OS concluída não pode ser excluída.");
        }
        ordens.delete(ordem);
        return ResponseEntity.noContent().build();
    }

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }
}
