package br.com.adminpool.dto;

import java.math.BigDecimal;

public record EditarValorCobrancaRequest(BigDecimal valor, String observacao) {}
