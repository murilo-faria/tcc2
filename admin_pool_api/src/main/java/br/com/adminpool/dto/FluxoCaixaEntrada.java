package br.com.adminpool.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record FluxoCaixaEntrada(
        Long id, String clienteNome, String descricao, BigDecimal valor,
        String formaPagamento, LocalDateTime dataPagamento, String referencia) {}
