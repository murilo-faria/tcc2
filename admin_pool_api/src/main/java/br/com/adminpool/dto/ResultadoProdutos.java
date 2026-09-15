package br.com.adminpool.dto;

import java.math.BigDecimal;

public record ResultadoProdutos(
        String referencia,
        BigDecimal totalCompras,
        BigDecimal totalVendas,
        BigDecimal lucroBruto,
        BigDecimal margemPercentual,
        BigDecimal totalAReceber) {}
