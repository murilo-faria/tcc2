package br.com.adminpool.dto;

import java.math.BigDecimal;

public record ResumoCobrancaCliente(
        Long clienteId,
        String clienteNome,
        BigDecimal totalPendente,
        long quantidadePendente,
        boolean possuiAtraso) {}
