package br.com.adminpool.controller;

import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.service.CobrancaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/cobrancas")

public class CobrancaController {

    private final CobrancaService cobrancaService;

    public CobrancaController(CobrancaService cobrancaService) {
        this.cobrancaService = cobrancaService;
    }

    @GetMapping
    public List<CobrancaMensal> listar() {
        return cobrancaService.listarMesAtual();
    }

    @PostMapping("/gerar-mes-atual")
    public List<CobrancaMensal> gerarMesAtual() {
        return cobrancaService.gerarMesAtual();
    }

    @PutMapping("/{id}/baixar")
    public ResponseEntity<Void> baixar(
            @PathVariable Long id,
            @RequestParam BigDecimal valor) {
        cobrancaService.darBaixa(id, valor);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/reabrir")
    public ResponseEntity<Void> reabrir(@PathVariable Long id) {
        cobrancaService.reabrir(id);
        return ResponseEntity.noContent().build();
    }
}
