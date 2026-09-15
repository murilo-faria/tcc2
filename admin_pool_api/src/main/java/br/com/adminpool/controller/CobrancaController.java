package br.com.adminpool.controller;

import br.com.adminpool.dto.BaixaCobrancaRequest;
import br.com.adminpool.dto.BaixaItensRequest;
import br.com.adminpool.dto.ResumoCobrancaCliente;
import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.model.ItemCobranca;
import br.com.adminpool.service.CobrancaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cobrancas")
public class CobrancaController {

    private final CobrancaService cobrancaService;

    public CobrancaController(CobrancaService cobrancaService) {
        this.cobrancaService = cobrancaService;
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
