-- Correção autorizada: o Pedido #76 foi concluído em duplicidade para
-- Cristina. Remove somente as duas parcelas pendentes desse pedido.
DELETE FROM itens_cobranca AS item
WHERE item.tipo = 'PEDIDO'
  AND item.descricao IN ('Pedido #76 — Parcela 1/2', 'Pedido #76 — Parcela 2/2')
  AND item.status IN ('PENDENTE', 'PARCIAL')
  AND COALESCE(item.valor_pago, 0) = 0;
