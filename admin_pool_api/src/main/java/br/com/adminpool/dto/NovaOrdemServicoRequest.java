package br.com.adminpool.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Dados enviados pelo Flutter para criar uma ordem de serviço. */
public record NovaOrdemServicoRequest(
        Long clienteId,
        Long piscinaId,
        String descricao,
        LocalDate dataServico,
        BigDecimal valorAdicional) {
}
