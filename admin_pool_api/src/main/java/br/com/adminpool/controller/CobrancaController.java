package br.com.adminpool.controller;

import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.service.CobrancaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/cobrancas")
@CrossOrigin(originPatterns = "http://localhost:*")
public class CobrancaController {
    private final CobrancaService service;
    public CobrancaController(CobrancaService service) { this.service = service; }

    @GetMapping public List<CobrancaMensal> listar() { return service.listarPorVencimento(); }
    @PostMapping("/gerar-mes-atual") public List<CobrancaMensal> gerar() { return service.gerarMesAtual(); }

    @PutMapping("/{id}/baixar")
    public ResponseEntity<Void> baixar(@PathVariable Long id, @RequestParam BigDecimal valor) {
        service.baixa(id, valor);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/reabrir")
    public ResponseEntity<Void> reabrir(@PathVariable Long id) {
        service.reabrir(id);
        return ResponseEntity.noContent().build();
    }
}
