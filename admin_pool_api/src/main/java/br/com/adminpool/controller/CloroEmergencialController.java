package br.com.adminpool.controller;

import br.com.adminpool.dto.*;
import br.com.adminpool.model.CloroEmergencial;
import br.com.adminpool.service.CloroEmergencialService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/cloro-emergencial")
public class CloroEmergencialController {
    private final CloroEmergencialService servico;
    public CloroEmergencialController(CloroEmergencialService servico) { this.servico = servico; }

    @GetMapping public List<CloroEmergencial> listar(@RequestParam(required = false) String referencia) {
        return servico.listar(referencia);
    }
    @PostMapping public ResponseEntity<CloroEmergencial> criar(@RequestBody NovoCloroEmergencialRequest r,
                                                                 Authentication auth) {
        return ResponseEntity.status(HttpStatus.CREATED).body(servico.criarOuAbrir(r, auth));
    }
    @PostMapping("/{id}/usos") public CloroEmergencial adicionarUso(@PathVariable Long id,
                                                                        @RequestBody NovoUsoCloroEmergencialRequest r) {
        return servico.adicionarUso(id, r);
    }
    @PutMapping("/{id}/finalizar") public CloroEmergencial finalizar(@PathVariable Long id,
                                                                        @RequestBody FinalizarCloroEmergencialRequest r,
                                                                        Authentication auth) {
        gestor(auth); return servico.finalizar(id, r);
    }
    @PutMapping("/{id}/confirmar-reposicao") public CloroEmergencial confirmarReposicao(@PathVariable Long id,
                                                                                            Authentication auth) {
        gestor(auth); return servico.confirmarReposicao(id);
    }
    private void gestor(Authentication auth) {
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_GESTOR")))
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem finalizar cloro.");
    }
}
