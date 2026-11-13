package br.com.adminpool.dto;

import java.math.BigDecimal;

/** Pedido de produto que ainda possui saldo pendente na cobrança do mês. */
public record ProdutoAReceber(
        Long codigoPedido,
        String cliente,
        String descricao,
        BigDecimal valorOriginal,
        BigDecimal valorPago,
        BigDecimal saldoPendente) {
}
