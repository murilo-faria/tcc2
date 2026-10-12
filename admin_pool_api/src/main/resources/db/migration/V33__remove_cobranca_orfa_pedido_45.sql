-- Correção autorizada: o Pedido #45 foi excluído após ter sido concluído
-- para o cliente errado. Remove somente o lançamento ainda pendente, sem
-- alterar itens com pagamento recebido ou qualquer outro pedido.
DELETE FROM itens_cobranca AS item
WHERE item.tipo = 'PEDIDO'
  AND item.descricao = 'Pedido #45'
  AND item.status IN ('PENDENTE', 'PARCIAL')
  AND COALESCE(item.valor_pago, 0) = 0
  AND NOT EXISTS (
      SELECT 1
      FROM pedidos_produto AS pedido
      WHERE pedido.codigo_pedido = 45
  );
