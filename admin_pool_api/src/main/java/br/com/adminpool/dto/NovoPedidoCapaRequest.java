package br.com.adminpool.dto;

import java.math.BigDecimal;

/** Dados variáveis de uma capa; a área é sempre calculada pela piscina cadastrada. */
public record NovoPedidoCapaRequest(
        Long clienteId,
        Long piscinaId,
        BigDecimal custoMetroQuadrado,
        BigDecimal frete,
        BigDecimal lucro,
        Integer espessuraMicras) {
}
