-- Correção autorizada: a OS #6 foi apagada e sua cobrança pendente permaneceu.
-- Remove somente esse lançamento sem pagamento.
DELETE FROM itens_cobranca AS item
WHERE item.tipo = 'ORDEM_SERVICO'
  AND item.descricao LIKE 'OS #6 - %'
  AND item.status IN ('PENDENTE', 'PARCIAL')
  AND COALESCE(item.valor_pago, 0) = 0;
