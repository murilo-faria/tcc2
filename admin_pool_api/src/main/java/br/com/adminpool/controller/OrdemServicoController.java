package br.com.adminpool.controller;

import br.com.adminpool.dto.ConcluirOrdemServicoRequest;
import br.com.adminpool.dto.NovaOrdemServicoRequest;
import br.com.adminpool.dto.EditarOrdemServicoRequest;
import br.com.adminpool.dto.LinhaRelatorioPdf;
import br.com.adminpool.model.OrdemServico;
import br.com.adminpool.repository.OrdemServicoRepository;
import br.com.adminpool.service.OrdemServicoService;
import br.com.adminpool.service.RelatorioPdfService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.time.LocalDate;

@RestController
@RequestMapping("/api/ordens-servico")
public class OrdemServicoController {

    private final OrdemServicoRepository ordens;
    private final OrdemServicoService servico;
    private final RelatorioPdfService relatorios;

    public OrdemServicoController(OrdemServicoRepository ordens, OrdemServicoService servico, RelatorioPdfService relatorios) {
        this.ordens = ordens;
        this.servico = servico;
        this.relatorios = relatorios;
    }

    @GetMapping
    public List<OrdemServico> listarTodas(Authentication auth) {
        return gestor(auth) ? ordens.findAllByOrderByDataServicoDesc()
                : ordens.findVisiveisPorColaborador(auth.getName());
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

    @GetMapping(value = "/relatorio.pdf", produces = "application/pdf")
    public ResponseEntity<byte[]> relatorio(@RequestParam(required = false) Long clienteId,
                                             @RequestParam(required = false) String mes,
                                             @RequestParam(required = false) LocalDate inicio,
                                             @RequestParam(required = false) LocalDate fim) {
        var linhas = ordens.findAllByOrderByDataServicoDesc().stream()
                .filter(o -> clienteId == null || o.getCliente().getId().equals(clienteId))
                .filter(o -> mes == null || mes.isBlank() || o.getDataServico().toString().startsWith(mes))
                .filter(o -> inicio == null || !o.getDataServico().isBefore(inicio))
                .filter(o -> fim == null || !o.getDataServico().isAfter(fim))
                .map(o -> new LinhaRelatorioPdf(o.getCliente().getNome(), o.getDescricao(), o.getDataServico().toString(), o.getValorCobrado())).toList();
        return ResponseEntity.ok().header("Content-Disposition", "attachment; filename=relatorio-os.pdf")
                .body(relatorios.gerar("Relatório de ordens de serviço", "Filtros aplicados na tela", linhas));
    }

    @PostMapping
    public ResponseEntity<OrdemServico> criar(@RequestBody NovaOrdemServicoRequest requisicao,
                                              Authentication auth) {
        return ResponseEntity.status(HttpStatus.CREATED).body(servico.criar(requisicao, auth));
    }

    @PutMapping("/{id}")
    public OrdemServico editar(@PathVariable Long id,
                               @RequestBody EditarOrdemServicoRequest requisicao,
                               Authentication auth) {
        if (!gestor(auth)) servico.validarEdicaoPorColaborador(id, auth.getName());
        return servico.editar(id, requisicao);
    }

    @GetMapping(value = "/{id}/pdf", produces = "application/pdf")
    public ResponseEntity<byte[]> osPdf(@PathVariable Long id, Authentication auth) {
        if (!gestor(auth)) servico.validarVisualizacaoPorColaborador(id, auth.getName());
        OrdemServico ordem = ordens.findById(id).orElseThrow();
        var linhas = List.of(new LinhaRelatorioPdf(
                ordem.getCliente().getNome(), ordem.getDescricao(),
                ordem.getDataServico().toString(), ordem.getValorCobrado()));
        return ResponseEntity.ok().header("Content-Disposition", "attachment; filename=os-" + id + ".pdf")
                .body(relatorios.gerar("Ordem de serviço #" + id, "Status: " + ordem.getStatus(), linhas));
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
    public ResponseEntity<Void> cancelar(@PathVariable Long id, Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem cancelar uma OS.");
        }
        servico.cancelar(id);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id, Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem excluir uma OS.");
        }
        servico.excluir(id);
        return ResponseEntity.noContent().build();
    }

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }
}
