package br.com.adminpool.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Dados que o gestor pode corrigir em uma OS aberta. */
public record EditarOrdemServicoRequest(
        String descricao,
        LocalDate dataServico,
        BigDecimal valorAdicional) {
}
