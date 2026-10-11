package br.com.adminpool.dto;

import java.math.BigDecimal;

/** Números compactos da visão geral, sem transportar a lista de cobranças. */
public record ResumoVisaoGeral(long clientesAtivos, long cobrancasPendentes,
                               BigDecimal faturamentoPrevisto) {
}
