package br.com.adminpool.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Linha exibida no histórico de cobranças, incluindo abates parciais. */
public record LinhaHistoricoCobranca(
        Long id,
        String descricao,
        String referencia,
        LocalDate vencimento,
        LocalDate data,
        BigDecimal saldoPendente,
        BigDecimal valorPago,
        String status,
        boolean atrasado,
        boolean registroPagamento) {
}
