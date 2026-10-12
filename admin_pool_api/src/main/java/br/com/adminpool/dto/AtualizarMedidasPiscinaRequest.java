package br.com.adminpool.dto;

import java.math.BigDecimal;

/** Medidas preenchidas uma única vez ao criar um pedido de capa. */
public record AtualizarMedidasPiscinaRequest(
        BigDecimal comprimento,
        BigDecimal largura) {
}
