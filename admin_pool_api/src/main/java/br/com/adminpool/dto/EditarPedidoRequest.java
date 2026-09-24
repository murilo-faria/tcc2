package br.com.adminpool.dto;

import java.util.List;

/** Itens substituídos pelo gestor em um pedido ainda não concluído. */
public record EditarPedidoRequest(List<ItemPedidoRequest> itens) {
}
