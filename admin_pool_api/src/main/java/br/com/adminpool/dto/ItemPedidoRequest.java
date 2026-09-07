package br.com.adminpool.dto;

/** Um produto e sua quantidade dentro de um pedido. */
public record ItemPedidoRequest(Long produtoId, Integer quantidade) {
}
