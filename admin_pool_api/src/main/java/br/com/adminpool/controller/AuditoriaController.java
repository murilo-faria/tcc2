package br.com.adminpool.controller;

import br.com.adminpool.model.RegistroAuditoria;
import br.com.adminpool.repository.RegistroAuditoriaRepository;
import java.time.LocalDate;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auditoria")
public class AuditoriaController {
    private final RegistroAuditoriaRepository registros;
    public AuditoriaController(RegistroAuditoriaRepository registros) { this.registros = registros; }

    @GetMapping
    public List<RegistroAuditoria> listar(@RequestParam(required = false) LocalDate inicio,
                                          @RequestParam(required = false) LocalDate fim) {
        if (inicio == null && fim == null) return registros.findTop200ByOrderByDataHoraDesc();
        LocalDate dataInicial = inicio == null ? LocalDate.of(2000, 1, 1) : inicio;
        LocalDate dataFinal = fim == null ? LocalDate.now() : fim;
        return registros.findByDataHoraBetweenOrderByDataHoraDesc(dataInicial.atStartOfDay(), dataFinal.plusDays(1).atStartOfDay());
    }
}
