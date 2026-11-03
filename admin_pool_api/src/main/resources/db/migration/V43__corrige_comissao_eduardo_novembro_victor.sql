-- A piscina Eduardo já havia sido transferida em outubro. A reversão indevida
-- do importador fotografou Murilo na mensalidade de novembro; a comissão de
-- novembro deve pertencer ao Victor. Meses anteriores permanecem inalterados.
UPDATE itens_cobranca item
SET responsavel_referencia_id = (
    SELECT f.id
    FROM funcionarios f
    JOIN usuarios u ON u.id = f.usuario_id
    WHERE lower(u.nome) LIKE '%victor%'
    LIMIT 1
)
FROM cobrancas_mensais cobranca
JOIN clientes cliente ON cliente.id = cobranca.cliente_id
WHERE item.cobranca_id = cobranca.id
  AND item.tipo = 'MENSALIDADE'
  AND cobranca.referencia = '2026-11'
  AND lower(cliente.nome) = 'eduardo';
