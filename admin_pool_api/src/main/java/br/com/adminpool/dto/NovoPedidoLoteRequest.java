package br.com.adminpool.dto;

import java.util.List;

/** Permite enviar vários produtos de uma vez para o mesmo cliente. */
public record NovoPedidoLoteRequest(Long clienteId, Long piscinaId, List<ItemPedidoRequest> itens) {
}
