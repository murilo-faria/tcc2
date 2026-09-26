package br.com.adminpool.dto;

import java.math.BigDecimal;

/** Totais de um pedido para o relatório gerencial de compras e vendas. */
public record LinhaRelatorioPedidoCompleto(
        String cliente,
        String produtos,
        BigDecimal compra,
        BigDecimal venda,
        BigDecimal lucro) {
}
