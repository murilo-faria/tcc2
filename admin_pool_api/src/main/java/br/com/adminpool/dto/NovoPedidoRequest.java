package br.com.adminpool.dto;

/** Dados para incluir um único produto em um pedido. */
public record NovoPedidoRequest(Long clienteId, Long piscinaId, Long produtoId, Integer quantidade) {
}
