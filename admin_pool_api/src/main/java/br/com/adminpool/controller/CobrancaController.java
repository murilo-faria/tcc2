package br.com.adminpool.controller;

import br.com.adminpool.dto.BaixaCobrancaRequest;
import br.com.adminpool.dto.BaixaItensRequest;
import br.com.adminpool.dto.ResumoCobrancaCliente;
import br.com.adminpool.dto.FluxoCaixaEntrada;
import br.com.adminpool.dto.LinhaRelatorioPdf;
import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.model.ItemCobranca;
import br.com.adminpool.service.CobrancaService;
import br.com.adminpool.service.RelatorioPdfService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.math.BigDecimal;
import java.time.YearMonth;

@RestController
@RequestMapping("/api/cobrancas")
public class CobrancaController {

    private final CobrancaService cobrancaService;
    private final RelatorioPdfService relatorios;

    public CobrancaController(CobrancaService cobrancaService, RelatorioPdfService relatorios) {
        this.cobrancaService = cobrancaService;
        this.relatorios = relatorios;
    }

    @GetMapping
    public List<CobrancaMensal> listar(@RequestParam(required = false) String referencia) {
        return referencia == null || referencia.isBlank()
                ? cobrancaService.listarMesAtual()
                : cobrancaService.listarPorReferencia(referencia);
    }

    @GetMapping("/meses")
    public List<String> listarMeses() {
        cobrancaService.listarMesAtual();
        return cobrancaService.listarReferencias();
    }

    @GetMapping("/clientes")
    public List<ResumoCobrancaCliente> listarClientes() {
        return cobrancaService.listarResumoClientes();
    }

    @GetMapping(value = "/relatorio.pdf", produces = "application/pdf")
    public ResponseEntity<byte[]> relatorio(@RequestParam(required = false) Long clienteId,
                                             @RequestParam(required = false) String referencia,
                                             @RequestParam(required = false) Integer diaVencimento,
                                             @RequestParam(required = false) java.time.LocalDate inicio,
                                             @RequestParam(required = false) java.time.LocalDate fim) {
        var linhas = cobrancaService.listarReferencias().stream()
                .flatMap(ref -> cobrancaService.listarPorReferencia(ref).stream())
                .filter(c -> clienteId == null || c.getCliente().getId().equals(clienteId))
                .filter(c -> referencia == null || referencia.isBlank() || c.getReferencia().equals(referencia))
                .filter(c -> diaVencimento == null || c.getVencimento().getDayOfMonth() == diaVencimento)
                .filter(c -> inicio == null || !c.getVencimento().isBefore(inicio))
                .filter(c -> fim == null || !c.getVencimento().isAfter(fim))
                .map(c -> new LinhaRelatorioPdf(c.getCliente().getNome(), "Cobrança " + c.getReferencia(), c.getVencimento().toString(), c.getTotal())).toList();
        return ResponseEntity.ok().header("Content-Disposition", "attachment; filename=relatorio-cobrancas.pdf")
                .body(relatorios.gerar("Relatório de cobranças", "Filtros aplicados na tela", linhas));
    }

    @GetMapping("/fluxo-caixa")
    public BigDecimal fluxoCaixa() {
        return cobrancaService.fluxoCaixaMesAtual();
    }

    @GetMapping("/fluxo-caixa/entradas")
    public List<FluxoCaixaEntrada> entradasFluxoCaixa(@RequestParam(required = false) String referencia) {
        return cobrancaService.listarFluxoCaixa(referencia == null || referencia.isBlank()
                ? YearMonth.now() : YearMonth.parse(referencia));
    }

    @GetMapping("/fluxo-caixa/meses")
    public List<String> mesesFluxoCaixa() {
        return cobrancaService.referenciasFluxoCaixa();
    }

    @GetMapping("/clientes/{clienteId}/itens")
    public List<ItemCobranca> listarItens(@PathVariable Long clienteId) {
        return cobrancaService.listarItensCliente(clienteId);
    }

    @GetMapping("/itens/{itemId}")
    public ItemCobranca detalharItem(@PathVariable Long itemId) {
        return cobrancaService.detalharItem(itemId);
    }

    @PostMapping("/gerar-mes-atual")
    public List<CobrancaMensal> gerarMesAtual() {
        return cobrancaService.gerarMesAtual();
    }

    @PutMapping("/itens/{itemId}/baixar")
    public ResponseEntity<Void> baixarItem(@PathVariable Long itemId,
                                           @RequestBody(required = false) BaixaCobrancaRequest requisicao) {
        cobrancaService.baixarItem(itemId, requisicao == null ? null : requisicao.valor(),
                requisicao == null ? null : requisicao.formaPagamento());
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/itens/baixar")
    public ResponseEntity<Void> baixarItens(@RequestBody BaixaItensRequest requisicao) {
        cobrancaService.baixarItens(requisicao.itemIds(), requisicao.formaPagamento());
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/clientes/{clienteId}/baixar-total")
    public ResponseEntity<Void> baixarTotal(@PathVariable Long clienteId,
                                            @RequestBody(required = false) BaixaCobrancaRequest requisicao) {
        cobrancaService.baixarTotalCliente(clienteId, requisicao == null ? null : requisicao.formaPagamento());
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/clientes/{clienteId}/baixar-parcial")
    public ResponseEntity<Void> baixarParcial(@PathVariable Long clienteId,
                                              @RequestBody BaixaCobrancaRequest requisicao) {
        cobrancaService.baixarParcialCliente(clienteId, requisicao.valor(), requisicao.formaPagamento());
        return ResponseEntity.noContent().build();
    }
}
