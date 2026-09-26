package br.com.adminpool.dto;

import java.math.BigDecimal;

public record EditarPedidoCapaRequest(
        BigDecimal custoMetroQuadrado,
        BigDecimal frete,
        BigDecimal lucro,
        Integer espessuraMicras) {
}
