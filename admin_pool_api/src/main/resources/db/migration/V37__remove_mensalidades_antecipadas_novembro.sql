-- Correção definitiva: novembro/2026 foi gerado antes do último dia de outubro.
-- Remove somente itens de MENSALIDADE; pedidos, OS e demais lançamentos permanecem.
DELETE FROM baixas_itens_cobranca
WHERE item_cobranca_id IN (
    SELECT item.id
    FROM itens_cobranca item
    JOIN cobrancas_mensais cobranca ON cobranca.id = item.cobranca_id
    WHERE cobranca.referencia = '2026-11'
      AND item.tipo = 'MENSALIDADE'
);

DELETE FROM itens_cobranca
WHERE id IN (
    SELECT item.id
    FROM itens_cobranca item
    JOIN cobrancas_mensais cobranca ON cobranca.id = item.cobranca_id
    WHERE cobranca.referencia = '2026-11'
      AND item.tipo = 'MENSALIDADE'
);

-- Apaga apenas as capas vazias deixadas pela geração antecipada.
DELETE FROM cobrancas_mensais cobranca
WHERE cobranca.referencia = '2026-11'
  AND NOT EXISTS (
      SELECT 1 FROM itens_cobranca item WHERE item.cobranca_id = cobranca.id
  );
